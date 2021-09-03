// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IProxied }      from "./interfaces/IProxied.sol";
import { IProxyFactory } from "./interfaces/IProxyFactory.sol";

import { Proxy } from "./Proxy.sol";

contract ProxyFactory is IProxyFactory {
  
    mapping(uint256 => address) public override implementation;

    mapping(address => address) public override implementationFor;

    mapping(address => uint256) public override versionOf;

    mapping(uint256 => mapping(uint256 => address)) public override migratorForPath;

    function registerImplementation(uint256 version, address implementationAddress) external virtual override {
        _registerImplementation(version, implementationAddress);
    }

    function _registerImplementation(uint256 version, address implementationAddress) internal {
        require(implementation[version] == address(0), "PF:RI:ALREADY_REGISTERED");
        require(implementationAddress != address(0),   "PF:RI:NO_IMPLEMENTATION");

        emit ImplementationRegister(
            versionOf[implementationAddress] = version,
            implementation[version]          = implementationAddress
        );
    }

    function newInstance(uint256 version, bytes calldata initializationArguments) external virtual override returns (address proxy) {
        return _newInstance(version, initializationArguments);
    }

    function _newInstance(uint256 version, bytes calldata initializationArguments) internal returns (address proxy) {
        implementationFor[proxy = address(new Proxy(address(this)))] = implementation[version];

        emit InstanceDeployed(version, proxy, initializationArguments);

        address initializer = migratorForPath[version][version];

        if (initializer == address(0)) return proxy;

        (bool success,) = proxy.call(abi.encodeWithSelector(IProxied.migrate.selector, initializer, initializationArguments));
        require(success, "PF:NI:INITIALIZE_FAILED");
    }

    function getImplementation() external override view returns (address) {
        return implementationFor[msg.sender];
    }

    function registerMigrationPath(uint256 fromVersion, uint256 toVersion, address migrator) external virtual override {
        _registerMigrationPath(fromVersion, toVersion, migrator);
    }

    function _registerMigrationPath(uint256 fromVersion, uint256 toVersion, address migrator) internal {
        emit MigrationPathSet(fromVersion, toVersion, migratorForPath[fromVersion][toVersion] = migrator);
    }

    function upgradeImplementationFor(address proxy, uint256 toVersion, bytes calldata migrationArguments) external virtual override {
        return _upgradeImplementationFor(proxy, toVersion, migrationArguments);
    }

    function _upgradeImplementationFor(address proxy, uint256 toVersion, bytes calldata migrationArguments) internal {
        uint256 fromVersion      = versionOf[implementationFor[proxy]];
        implementationFor[proxy] = implementation[toVersion];

        emit InstanceUpgrade(proxy, fromVersion, toVersion, migrationArguments);

        address migrator = migratorForPath[fromVersion][toVersion];

        if (migrator == address(0)) return;

        (bool success,) = proxy.call(abi.encodeWithSelector(IProxied.migrate.selector, migrator, migrationArguments));
        require(success, "PF:UIF:MIGRATION_FAILED");
    }

}
