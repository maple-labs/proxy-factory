// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IProxied }      from "./interfaces/IProxied.sol";
import { IProxyFactory } from "./interfaces/IProxyFactory.sol";

import { Proxy } from "./Proxy.sol";

contract ProxyFactory is IProxyFactory {
  
    mapping(uint256 => address) public override implementation;
    mapping(address => address) public override implementationFor;
    mapping(uint256 => address) public override initializerFor;
    mapping(bytes32 => address) public override migratorForPath;
    mapping(address => uint256) public override versionOf;

    uint256 public override recommendedVersion;

    function _getUpgradePath(uint256 fromVersion, uint256 toVersion) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(fromVersion, toVersion));
    }

    function _registerImplementation(uint256 version, address implementationAddress, address initializer) internal {
        require(initializer != address(0), "PF:RI:ZERO_INITIALIZER");

        emit ImplementationRegister(
            versionOf[implementationAddress] = version,
            implementation[version]          = implementationAddress,
            initializerFor[version]          = initializer
        );
    }

    function _newInstance(uint256 version, bytes calldata initializationArguments) internal returns (address proxy) {
        address initializer = initializerFor[version];
        require(initializer != address(0), "PF:NI:NO_INITIALIZER");

        implementationFor[proxy = address(new Proxy(address(this)))] = implementation[version];

        (bool success,) = proxy.call(abi.encodeWithSelector(IProxied.initialize.selector, initializer, initializationArguments));
        require(success, "PF:NI:INITIALIZE_FAILED");

        emit InstanceDeployed(version, proxy, initializationArguments);
    }

    function _setMigrationPath(uint256 fromVersion, uint256 toVersion, address migrator) internal {
        require(migrator != address(0), "PF:SUP:ZERO_MIGRATOR");

        emit MigrationPathSet(fromVersion, toVersion, migratorForPath[_getUpgradePath(fromVersion, toVersion)] = migrator);
    }

    function _upgradeImplementationFor(address proxy, uint256 toVersion, bytes calldata migrationArguments) internal {
        uint256 fromVersion = versionOf[implementationFor[proxy]];
        
        address migrator = migratorForPath[_getUpgradePath(fromVersion, toVersion)];
        require(migrator != address(0), "PF:UIF:NO_MIGRATOR");

        implementationFor[proxy] = implementation[toVersion];

        (bool success,) = proxy.call(abi.encodeWithSelector(IProxied.migrate.selector, migrator, migrationArguments));
        require(success, "PF:UIF:MIGRATION_FAILED");

        emit InstanceUpgrade(proxy, fromVersion, toVersion, migrationArguments);
    }

    function registerImplementation(uint256 version, address implementationAddress, address initializer) external virtual override {
        require(implementationAddress != address(0),   "PF:RI:ZERO_ADDRESS");
        require(implementation[version] == address(0), "PF:RI:ALREADY_REGISTERED");

        _registerImplementation(version, implementationAddress, initializer);
    }

    function setRecommendedVersion(uint256 version) external override {
        emit RecommendedVersionSet(recommendedVersion = version);
    }

    function newInstance(uint256 version, bytes calldata initializationArguments) external virtual override returns (address proxy) {
        return _newInstance(version, initializationArguments);
    }

    function newInstance(bytes calldata initializationArguments) external virtual override returns (address proxy) {
        return _newInstance(recommendedVersion, initializationArguments);
    }

    function getImplementation() external override view returns (address) {
        return implementationFor[msg.sender];
    }

    function setMigrationPath(uint256 fromVersion, uint256 toVersion, address migrator) external virtual override {
        _setMigrationPath(fromVersion, toVersion, migrator);
    }

    function getMigrator(uint256 fromVersion, uint256 toVersion) external view override returns (address proxy) {
        return migratorForPath[_getUpgradePath(fromVersion, toVersion)];
    }

    function upgradeImplementationFor(address proxy, uint256 toVersion, bytes calldata migrationArguments) external virtual override {
        return _upgradeImplementationFor(proxy, toVersion, migrationArguments);
    }

}
