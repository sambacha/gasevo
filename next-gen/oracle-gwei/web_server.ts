import Koa = require('koa');
import KoaCors = require('koa2-cors');
import { errorHandler } from './ErrorHandler';
import { GasOracle } from './GasOracle';

process.on('SIGINT', () => process.exit());
process.on('SIGTERM', () => process.exit());

const ethereumUrl = process.env.ETHEREUM_URL;
if (!ethereumUrl) throw new Error('ETHEREUM_URL environment variable must be defined.');
const pollingFrequencySecondsString = process.env.POLLING_FREQUENCY_SECONDS;
if (!pollingFrequencySecondsString) throw new Error(`POLLING_FREQUENCY_SECONDS environment variable must be defined.`)
const pollingFrequencySeconds = Number.parseFloat(pollingFrequencySecondsString)
if (pollingFrequencySeconds <= 0 || pollingFrequencySeconds > 3600 || !Number.isInteger(pollingFrequencySeconds)) throw new Error(`POLLING_FREQUENCY_SECONDS must be an integer number of seconds between 1 and 3600`)
const gasOracle = new GasOracle(ethereumUrl, pollingFrequencySeconds);

new Koa()
	.use(errorHandler)
	.use(KoaCors())
	.use(async context => {
		context.body = {
			number_of_blocks: await gasOracle.getNumberOfBlocks(),
			latest_block_number: await gasOracle.getLatestBlockNumber(),
		}
		for (let i = 1; i <= 4; ++i) {
			context.body[`percentile_${i}`] = `${await gasOracle.getPercentile(i) / 10**9} nanoeth`;
		}
		for (let i = 5; i <= 95; i+=5) {
			context.body[`percentile_${i}`] = `${await gasOracle.getPercentile(i) / 10**9} nanoeth`;
		}
		for (let i = 96; i <= 100; ++i) {
			context.body[`percentile_${i}`] = `${await gasOracle.getPercentile(i) / 10**9} nanoeth`;
		}
	})
	.listen(80);