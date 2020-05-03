pragma solidity 0.5.4;
import "../kernel/Owned.sol";

/**
 * @title GoTokenRegistry
 * @dev mapping between underlying assets and their corresponding GoToken.
 * @dev This has not been audited please do not use in production
 */
contract goTokenRegistry is Owned {

    address[] tokens;

    mapping (address => GoTokenInfo) internal GoToken;

    struct GoTokenInfo {
        bool exists;
        uint128 index;
        address market;
    }

    event GoTokenAdded(address indexed _underlying, address indexed _GoToken);
    event GoTokenRemoved(address indexed _underlying);

    /**
     * @dev Adds a new GoToken to the registry.
     * @param _underlying The underlying asset.
     * @param _GoToken The GoToken.
     */
    function addGoToken(address _underlying, address _GoToken) external onlyOwner {
        require(!GoToken[_underlying].exists, "CR: GoToken already added");
        GoToken[_underlying].exists = true;
        GoToken[_underlying].index = uint128(tokens.push(_underlying) - 1);
        GoToken[_underlying].market = _GoToken;
        emit GoTokenAdded(_underlying, _GoToken);
    }

    /**
     * @dev Removes a GoToken from the registry.
     * @param _underlying The underlying asset.
     */
    function removeGoToken(address _underlying) external onlyOwner {
        require(GoToken[_underlying].exists, "CR: GoToken does not exist");
        address last = tokens[tokens.length - 1];
        if (_underlying != last) {
            uint128 targetIndex = GoToken[_underlying].index;
            tokens[targetIndex] = last;
            GoToken[last].index = targetIndex;
        }
        tokens.length --;
        delete GoToken[_underlying];
        emit GoTokenRemoved(_underlying);
    }

    /**
     * @dev Gets the GoToken for a given underlying asset.
     * @param _underlying The underlying asset.
     */
    function getGoToken(address _underlying) external view returns (address) {
        return GoToken[_underlying].market;
    }

    /**
    * @dev Gets the list of supported underlyings.
    */
    function listUnderlyings() external view returns (address[] memory) {
        address[] memory underlyings = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            underlyings[i] = tokens[i];
        }
        return underlyings;
    }
}