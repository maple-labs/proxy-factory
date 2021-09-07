// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IProxied }      from "./interfaces/IProxied.sol";
import { IReturnsCallerImplementation } from "./interfaces/IReturnsCallerImplementation.sol";

import { Proxy } from "./Proxy.sol";

contract ProxyFactory is IReturnsCallerImplementation {
  
    mapping(uint256 => address) internal _implementation;

    mapping(address => address) internal _implementationFor;

    mapping(address => uint256) internal _versionOf;

    mapping(uint256 => mapping(uint256 => address)) internal _migratorForPath;

    function getImplementation() external view override virtual returns (address) {
        return _implementationFor[msg.sender];
    }

    function _registerImplementation(uint256 version, address implementationAddress) internal virtual returns (bool success) {
        // Cannot already be registered and cannot be empty implementation
        if (_implementation[version] != address(0) || implementationAddress == address(0)) return false;

        _versionOf[implementationAddress] = version;
        _implementation[version]          = implementationAddress;

        return true;
    }

    function _newInstance(uint256 version, bytes calldata initializationArguments) internal virtual returns (bool success, address proxy) {
        _implementationFor[proxy = address(new Proxy(address(this)))] = _implementation[version];

        address initializer = _migratorForPath[version][version];

        if (initializer == address(0)) return (true, proxy);

        (success,) = proxy.call(abi.encodeWithSelector(IProxied.migrate.selector, initializer, initializationArguments));
        
        return (success, proxy);
    }

    function _registerMigrationPath(uint256 fromVersion, uint256 toVersion, address migrator) internal virtual returns (bool success) {
        _migratorForPath[fromVersion][toVersion] = migrator;
        return true;
    }

    function _upgradeInstance(address proxy, uint256 toVersion, bytes calldata migrationArguments) internal virtual returns (bool success) {
        uint256 fromVersion      = _versionOf[_implementationFor[proxy]];
        _implementationFor[proxy] = _implementation[toVersion];

        address migrator = _migratorForPath[fromVersion][toVersion];

        if (migrator == address(0)) return true;

        (success,) = proxy.call(abi.encodeWithSelector(IProxied.migrate.selector, migrator, migrationArguments));
    }

}
