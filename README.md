# Proxy Factory

[![CircleCI](https://circleci.com/gh/maple-labs/proxy-factory/tree/main.svg?style=svg)](https://circleci.com/gh/maple-labs/proxy-factory/tree/main) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)


Set of base contracts to deploy and manage versions on chain, designed to be minimally opinionated, extensible and gas-efficient. These contracts were built to provide the necessary features to be reused across multiple projects, both within Maple and externally.

While there are other good libraries for base smart contracts, none of them satisfied the need to simultaneously be feature complete and allow to be used within our own style of development.


### Features
- **No interfaces:** Contracts only define internal functionality and do not expose any external interfaces. Implementers are encouraged to mix and match the internal functions to cater to their specific needs.

- **Opt-In Upgrades:** Proxy contracts were designed to be upgraded individually. 

- **CREATE2:** Contracts can be deployed with CREATE or CREATE2 opcodes, allowing the option for Proxy contracts to be deployed with deterministic addresses.

- **Migration Contracts:** Architecture allows for intermediary contracts that can perform storage migration operations between two versions on upgrade, as well as perform initialize functionality on Proxy instantiation.

### Contracts

`ProxyFactory.sol`

Responsible for deploying new Proxy instances and triggering initialization and migration logic atomically. 

```js
    contract ProxyFactory {

        /// @dev Registers a new implementation address attached to a version, which can be used with any uint256 versioning scheme.
        function _registerImplementation(uint256 version, address implementationAddress) internal virtual returns (bool success);

        /// @dev Deploys a new Proxy instance of and calls the initialization function with provided arguments.
        function _newInstance(uint256 version, bytes calldata arguments) internal virtual returns (bool success, address proxy);

        /// @dev Deploys a new new Proxy instance at a specific address using a salt and calls the initialization function with provided arguments.
        function _newInstanceWithSalt(uint256 version, bytes calldata arguments, bytes32 salt) internal virtual returns (bool success, address proxy); 

        /// @dev Calls the Proxy with arguments to perform the necessary initialization.
        function _initializeInstance(address proxy, uint256 version, bytes calldata arguments) internal virtual returns (bool success); 

        /// @dev Registers a migration path between versions and optionally set a migrator contract
        function _registerMigrationPath(uint256 fromVersion, uint256 toVersion, address migrator) internal virtual returns (bool success); 

        /// @dev Updates the implementation used by a Proxy.
        function _upgradeInstance(address proxy, uint256 toVersion, bytes calldata arguments) internal virtual returns (bool success); 
    }
```

`Proxy.sol`

The Proxy contract that is deployed and manages storage. It saves both and `implementation` and the `factory` addresses to be able to execute transactions and upgrades.

```js
contract Proxy is SlotManipulatable {

    /// @dev Storage slot with the address of the current factory. This is the keccak-256 hash of "FACTORY_SLOT".
    bytes32 private constant FACTORY_SLOT = 0xf2db84db8157f5a01a257d644038e8929d5a62c9ffa8b736374913908897e5bb;

    /// @dev Storage slot with the address of the current implementation. This is the keccak-256 hash of "IMPLEMENTATION_SLOT".
    bytes32 private constant IMPLEMENTATION_SLOT = 0xf603533e14e17222e047634a2b3457fe346d27e294cedf9d21d74e5feea4a046;

    /// @dev Function to be called right after deployment, to set the `implementation` and the `factory` addresses in storage.
    function _setup() private; 

    /// @dev Function to delegatecall all incoming functions to the `implementation` address.
    fallback() payable external virtual; 

}
```

`SlotManipulatable.sol`

Helper contract that can manually modify storage when necessary (i.e., during a initialization/migration process)

 ```js
 contract SlotManipulatable {

    /// @dev Returns the value stored at the given slot.
    function _getSlotValue(bytes32 slot) internal view returns (bytes32 value); 

    /// @dev Sets the value stored at the given slot.
    function _setSlotValue(bytes32 slot, bytes32 value) internal; 

    // @dev Returns the storage slot for a reference type.
    function _getReferenceTypeSlot(bytes32 slot, bytes32 key) internal pure returns (bytes32 value); 

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
