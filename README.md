# Proxy Factory

[![CircleCI](https://circleci.com/gh/maple-labs/proxy-factory/tree/main.svg?style=svg)](https://circleci.com/gh/maple-labs/proxy-factory/tree/main) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)


Set of base contracts to deploy and manage versions on chain, designed to be minimally opinionated, extensible and gas-efficient.

It was built to provide the necessary features to be reused across multiple projects, both within Maple and externally. While there're some other good libraries for base smart contracts, none of them satisfied the need to simultaneously be feature complete and allow to be used within our own style of development. 


### Features
- No interfaces: the contracts only define the internal functionality and do not expose any kind external interface. Implementers are encouraged to mix and match the internal functions to cater for their specific need.

- Opt In Upgrades: the base contracts designed to be upgraded on a one-to-one basis. 

- Create2: can perform both regular deployments, as well create2 deployments, where the contracts are deployed to a deterministic address, regardless of chain state.

- Migration Contracts: an intermediary contract that can perform housekeeping between one version and the next.

### Contracts

`ProxyFactory.sol`

Responsible for deploying new instances and triggering initialization and migration logic atomically. 

```js
    contract ProxyFactory {

        /// @dev Register a new implementation address attached to a version, which can be used with any scheme of versioning.
        function _registerImplementation(uint256 version, address implementationAddress) internal virtual returns (bool success)

        /// @dev Deploys a new instance of and calls the initialization function with provided arguments
        function _newInstance(uint256 version, bytes calldata arguments) internal virtual returns (bool success, address proxy)

        /// @dev Deploys a new instance at a specific address using the salt and calls the initialization function with provided arguments
        function _newInstanceWithSalt(uint256 version, bytes calldata arguments, bytes32 salt) internal virtual returns (bool success, address proxy) 

        /// @dev Calls the proxy with arguments to perform the necessary initialization
        function _initializeInstance(address proxy, uint256 version, bytes calldata arguments) internal virtual returns (bool success) 

        /// @dev Register a possible migration path and optionally sets a migrator contract
        function _registerMigrationPath(uint256 fromVersion, uint256 toVersion, address migrator) internal virtual returns (bool success) 

        /// @dev Updates the implementation used by a proxy.
        function _upgradeInstance(address proxy, uint256 toVersion, bytes calldata arguments) internal virtual returns (bool success) 
    }
```

`Proxy.sol`

The slim contract that is deployed. It saves both and `implementation` and the `factory` address to be able to execute transactions and upgrades.

```js
contract Proxy is SlotManipulatable {

    /// @dev Storage slot with the address of the current factory. This is the keccak-256 hash of "FACTORY_SLOT".
    bytes32 private constant FACTORY_SLOT = 0xf2db84db8157f5a01a257d644038e8929d5a62c9ffa8b736374913908897e5bb;

    /// @dev Storage slot with the address of the current factory. This is the keccak-256 hash of "IMPLEMENTATION_SLOT".
    bytes32 private constant IMPLEMENTATION_SLOT = 0xf603533e14e17222e047634a2b3457fe346d27e294cedf9d21d74e5feea4a046;

    /// @dev Function to be called right after deployment, similar to a constructor in regular contracts.
    function _setup() private 

    /// @dev Function to delegatecall all incoming function to `implementation`
    fallback() payable external virtual 

}
```

`SlotManipulatable.sol`

Helper contract that allow to manually modify storage that might be needed during a migration process

 ```js
 contract SlotManipulatable {

    /// @dev returns the value stored at slot
    function _getSlotValue(bytes32 slot) internal view returns (bytes32 value) 

    /// @dev set the storage slot to the given value
    function _setSlotValue(bytes32 slot, bytes32 value) internal 

    // @dev Get the storage slot for a reference type
    function _getReferenceTypeSlot(bytes32 slot, bytes32 key) internal pure returns (bytes32 value) 

}
```

## Testing and Development
#### Setup
```sh
git clone git@github.com:maple-labs/maple-core.git
cd maple-core
dapp update
```
#### Running Tests
- To run all tests: `make test` (runs `./test.sh`)
- To run a specific test function: `./test.sh <test_name>` (e.g. `./test.sh test_composability`)

This project was built using <a href="https://github.com/dapphub/dapptools">dapptools</a>



## Security

The code is designed to be extended with needed feature, including access control and other guards on deployment and upgradeability, therefore it's not advised to use this as is. Additionally, it is still in development and haven't been externally audited. 


## About Maple
Maple is a decentralized corporate credit market. Maple provides capital to institutional borrowers through globally accessible fixed-income yield opportunities.

For all technical documentation related to the Maple protocol, please refer to the GitHub [wiki](https://github.com/maple-labs/maple-core/wiki).

---

<p align="center">
  <img src="https://user-images.githubusercontent.com/44272939/116272804-33e78d00-a74f-11eb-97ab-77b7e13dc663.png" height="100" />
</p>
