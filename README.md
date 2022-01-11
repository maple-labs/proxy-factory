# Proxy Factory

[![CircleCI](https://circleci.com/gh/maple-labs/proxy-factory/tree/main.svg?style=svg)](https://circleci.com/gh/maple-labs/proxy-factory/tree/main) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

**DISCLAIMER: This code has NOT been externally audited and is actively being developed. Please do not use in production without taking the appropriate steps to ensure maximum security.**

Set of base contracts to deploy and manage versions on chain, designed to be minimally opinionated, extensible and gas-efficient. These contracts were built to provide the necessary features to be reused across multiple projects, both within Maple and externally.

### Features
- **No interfaces:** Contracts only define internal functionality and do not expose any external interfaces. Implementers are encouraged to mix and match the internal functions to cater to their specific needs.

- **Opt-In Upgrades:** Proxy contracts were designed to be upgraded individually.

- **CREATE2:** Contracts can be deployed with CREATE or CREATE2 opcodes, allowing the option for Proxy contracts to be deployed with deterministic addresses.

- **Migration Contracts:** Architecture allows for intermediary contracts that can perform storage migration operations between two versions on upgrade, as well as perform initialize functionality on Proxy instantiation.

### Contracts

`ProxyFactory.sol`

Responsible for deploying new Proxy instances and triggering initialization and migration logic atomically.
**NOTE: All factories that inherit ProxyFactory MUST also inherit IDefaultImpleemntationBeacon and implement `defaultImplementation` if the CREATE2 functionality of `_newInstance` is to be used.**

```js
    contract ProxyFactory {

        /// @dev Deploys a new proxy for some version, with some initialization arguments, using `create` (i.e. factory's nonce determines the address).
        function _newInstance(uint256 version_, bytes memory arguments_) internal virtual returns (bool success_, address proxy_);

        /// @dev Deploys a new proxy, with some initialization arguments, using `create2` (i.e. salt determines the address).
        ///      This factory needs to be IDefaultImplementationBeacon, since the proxy will pull its implementation from it.
        function _newInstance(bytes memory arguments_, bytes32 salt_) internal virtual returns (bool success_, address proxy_);

        /// @dev Registers an implementation for some version.
        function _registerImplementation(uint256 version_, address implementation_) internal virtual returns (bool success_);

        /// @dev Registers a migrator for between two versions. If `fromVersion_ == toVersion_`, migrator is an initializer.
        function _registerMigrator(uint256 fromVersion_, uint256 toVersion_, address migrator_) internal virtual returns (bool success_);

        /// @dev Upgrades a proxy to a new version of an implementation, with some migration arguments.
        ///      Inheritor should revert on `success_ = false`, since proxy can be set to new implementation, but failed to migrate.
        function _upgradeInstance(address proxy_, uint256 toVersion_, bytes memory arguments_) internal virtual returns (bool success_);

        /// @dev Returns the deterministic address of a proxy given some salt.
        function _getDeterministicProxyAddress(bytes32 salt_) internal virtual view returns (address deterministicProxyAddress_);

        /// @dev Returns whether the account is currently a contract.
        function _isContract(address account_) internal view returns (bool isContract_);

    }
```

`SlotManipulatable.sol`

Helper contract that can manually modify storage when necessary (i.e., during a initialization/migration process)

 ```js
 contract SlotManipulatable {

    /// @dev Returns the value stored at the given slot.
    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_);

    /// @dev Sets the value stored at the given slot.
    function _setSlotValue(bytes32 slot_, bytes32 value_) internal;

    // @dev Returns the storage slot for a reference type.
    function _getReferenceTypeSlot(bytes32 slot_, bytes32 key_) internal pure returns (bytes32 value_);

}
```

`Proxied.sol`

Contract that must be inherited by all implementation contracts in order for them to function properly with proxies.


 ```js
 contract Proxied {

    /// @dev Delegatecalls to a migrator contract to manipulate storage during an inititalization or migration.
    function _migrate(address migrator_, bytes calldata arguments_) internal virtual returns (bool success_);

    /// @dev Sets the factory address in storage.
    function _setFactory(address factory_) internal virtual returns (bool success_);

    /// @dev Sets the implementation address in storage.
    function _setImplementation(address implementation_) internal virtual returns (bool success_);

    /// @dev Returns the factory address.
    function _factory() internal view virtual returns (address factory_);

    /// @dev Returns the implementation address.
    function _implementation() internal view virtual returns (address implementation_)

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
- To run a specific test function: `./test.sh -t <test_name>` (e.g. `./test.sh test_composability`)

This project was built using <a href="https://github.com/dapphub/dapptools">dapptools</a>

## Security

The code is designed to be highly flexible and extensible, meaning that logic that is usually part of these functions (e.g., access controls) was not included. Therefore **it is strongly advised that these contracts be implemented with proper sanity checks, access controls and any extra logic necessary for security.**

## Audit Reports
| Auditor | Report link |
|---|---|
| Trail of Bits                            | [ToB - Dec 28 2021](https://docs.google.com/viewer?url=https://github.com/maple-labs/maple-core/files/7847684/Maple.Finance.-.Final.Report_v3.pdf) |
| Code 4rena                             | [C4 - Jan 5 2022](https://code4rena.com/reports/2021-12-maple/) |

## About Maple
Maple is a decentralized corporate credit market. Maple provides capital to institutional borrowers through globally accessible fixed-income yield opportunities.

For all technical documentation related to the Maple protocol, please refer to the GitHub [wiki](https://github.com/maple-labs/maple-core/wiki).

---

<p align="center">
  <img src="https://user-images.githubusercontent.com/44272939/116272804-33e78d00-a74f-11eb-97ab-77b7e13dc663.png" height="100" />
</p>
