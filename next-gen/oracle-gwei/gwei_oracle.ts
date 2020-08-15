// original source from: https://github.com/Zoltu/ethereum-gas-oracle
import { BlockAndLogStreamer, Log } from 'ethereumjs-blockstream';
import fetch from 'node-fetch';
import Deque = require('collections/deque');

interface JsonRpcResponse<T> {
	jsonrpc: '2.0';
	id: number;
	result?: T;
	error?: { code: number, message: string, data?: any };
}

interface Transaction {
	gasPrice: string;
	from: string;
}

interface Block {
	readonly number: string;
	readonly hash: string;
	readonly parentHash: string;
	readonly miner: string;
	readonly transactions: Array<Transaction>;
}

export class GasOracle {
	private readonly ethereumUrl: string;
	private readonly blockAndLogStreamer: BlockAndLogStreamer<Block, Log>;
	private readonly blockMinGasPrices = new Deque<{ hash: string, minGas: number }>();

	public constructor(ethereumUrl: string, pollingFrequency: number) {
		this.ethereumUrl = ethereumUrl;
		this.blockAndLogStreamer = new BlockAndLogStreamer(this.getBlockByHash, this.getLogs, console.error, { blockRetention: 500 });
		this.blockAndLogStreamer.subscribeToOnBlockAdded(this.onBlockAdded);
		this.blockAndLogStreamer.subscribeToOnBlockRemoved(this.onBlockRemoved);
		this.reconcileAgedBlock(50)
			// the interval lambda is intentionally not async, `reconcileLatestBlock` catches and swallows all errors
			.then(() => setInterval(() => this.reconcileLatestBlock(), pollingFrequency * 1000));
	}

	public getPercentile = async (percentile: number): Promise<number> => {
		if (percentile > 100 || percentile < 1) throw new Error(`Percentile must be between 1 and 100.`);
		const sorted = this.blockMinGasPrices.map(x => x.minGas).sort((a, b) => a - b);
		if (sorted.length <= 0) throw new Error(`Please wait until the service has fetched at least one block.`);
		const index = Math.ceil(sorted.length * percentile / 100) - 1;
		return sorted[index];
	}

	public getNumberOfBlocks = async (): Promise<number> => {
		return this.blockMinGasPrices.length;
	}

	public getLatestBlockNumber = () => {
		const maybeLatestBlock = this.blockAndLogStreamer.getLatestReconciledBlock();
		return (maybeLatestBlock !== null) ? parseInt(maybeLatestBlock.number, 16) : 0;
	}

	private onBlockAdded = (block: Block) => {
		console.log(`Block ${block.hash} (${parseInt(block.number, 16)}) seen.`);
		const prices = block.transactions
			.filter(transaction => transaction.from !== block.miner)
			.map(transaction => parseInt(transaction.gasPrice, 16));
		const minPrice = Math.min(...prices);
		if (minPrice === 0 || !isFinite(minPrice)) return;
		this.blockMinGasPrices.push({ hash: block.hash, minGas: minPrice });
		if (this.blockMinGasPrices.length > 200) {
			this.blockMinGasPrices.shift();
		}
	}

	private onBlockRemoved = (block: Block) => {
		const poppedBlock = this.blockMinGasPrices.pop();
		if (poppedBlock.hash !== block.hash) throw new Error(`Received notification to remove block ${block.hash} but found ${poppedBlock.hash} on the top of the stack.`);
	}

	private getAgedBlock = async (numBlocksBack: number) => {
		const latestBlock = await this.getLatestBlock();
		const targetBlock = Math.max(0, parseInt(latestBlock.number, 16) - numBlocksBack);
		return await this.getBlockByNumber(targetBlock);
	}

	private getLatestBlock = async (): Promise<Block> => {
		return await this.getBlockByNumber('latest');
	}

	private getBlockByNumber = async (blockNumber: number|'latest') => {
		let param = (typeof blockNumber === 'number')
			? `0x${blockNumber.toString(16)}`
			: blockNumber;
		const payload = {
			jsonrpc: '2.0',
			id: 1,
			method: 'eth_getBlockByNumber',
			params: [param, true],
		};
		const response = await fetch(this.ethereumUrl, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) });
		const result = <JsonRpcResponse<Block>>await response.json();
		if (result.error) throw new Error(`Failed to fetch block (${blockNumber}): ${result.error.code}\n${result.error.message}`);
		if (!result.result) throw new Error(`Received unexpected response:\n${JSON.stringify(payload, null, '\t')}\n${JSON.stringify(result, null, '\t')}`);
		return result.result;
	}

	private reconcileLatestBlock = async (): Promise<void> => {
		try {
			const block = await this.getLatestBlock();
			await this.blockAndLogStreamer.reconcileNewBlock(block);
		} catch (error) {
			console.log(error);
		}
	}

	private reconcileAgedBlock = async (blockAge: number): Promise<void> => {
		try {
			const block = await this.getAgedBlock(blockAge);
			await this.blockAndLogStreamer.reconcileNewBlock(block);
		} catch (error) {
			console.log(error);
		}
	}

	private getBlockByHash = async (hash: string) => {
		const payload = {
			jsonrpc: '2.0',
			id: 1,
			method: 'eth_getBlockByHash',
			params: [hash, true],
		};
		const response = await fetch(this.ethereumUrl, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) });
		const result = <JsonRpcResponse<Block>>await response.json();
		if (result.error) throw new Error(`Failed to fetch block with hash ${hash}: ${result.error.code}\n${result.error.message}`);
		if (!result.result) throw new Error(`Received unexpected response:\n${JSON.stringify(payload, null, '\t')}\n${JSON.stringify(result, null, '\t')}`);
		return result.result;
	}

	private getLogs = async (filterOptions: any) => {
		return [];
	}
}