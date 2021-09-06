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

    uint256 public override recommendedVersion;

    function registerImplementation(uint256 version, address implementationAddress, address initializer) external virtual override {
        require(implementationAddress != address(0),   "PF:RI:ZERO_ADDRESS");
        require(implementation[version] == address(0), "PF:RI:ALREADY_REGISTERED");

        _registerImplementation(version, implementationAddress, initializer);
    }

    function _registerImplementation(uint256 version, address implementationAddress, address initializer) internal {
        require(version != uint256(0),     "PF:RI:INVALID_VERSION");
        require(initializer != address(0), "PF:RI:ZERO_INITIALIZER");

        emit ImplementationRegister(
            versionOf[implementationAddress] = version,
            implementation[version]          = implementationAddress,
            migratorForPath[0][version]      = initializer
        );
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

    function newInstanceTo(uint256 version, bytes calldata initializationArguments, bytes32 salt) external virtual override returns (address proxy) {
        return _newInstanceTo(recommendedVersion, initializationArguments, salt);
    }

    function _newInstance(uint256 version, bytes calldata initializationArguments) internal returns (address proxy) {
        address initializer = migratorForPath[0][version];
        require(initializer != address(0), "PF:NI:NO_INITIALIZER");

        implementationFor[proxy = address(new Proxy())] = implementation[version];

        (bool success,) = proxy.call(abi.encodeWithSelector(IProxied.migrate.selector, initializer, initializationArguments));
        require(success, "PF:NI:INITIALIZE_FAILED");

        emit InstanceDeployed(version, proxy, initializationArguments);
    }

    function _newInstanceTo(uint256 version, bytes calldata initializationArguments, bytes32 salt) internal returns (address proxy) {
        address initializer = migratorForPath[0][version];
        require(initializer != address(0), "PF:NI:NO_INITIALIZER");


        bytes memory bytecode = type(Proxy).creationCode;
        assembly {
            proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        implementationFor[proxy] = implementation[version];

        (bool success,) = proxy.call(abi.encodeWithSelector(IProxied.migrate.selector, initializer, initializationArguments));
        require(success, "PF:NI:INITIALIZE_FAILED");

        emit InstanceDeployed(version, proxy, initializationArguments);
    }

    function getImplementation() external override view returns (address) {
        return implementationFor[msg.sender];
    }

    function setMigrationPath(uint256 fromVersion, uint256 toVersion, address migrator) external virtual override {
        _setMigrationPath(fromVersion, toVersion, migrator);
    }

    function _setMigrationPath(uint256 fromVersion, uint256 toVersion, address migrator) internal {
        require(fromVersion != uint256(0), "PF:SMP:INVALID_FROM_VERSION");
        require(toVersion != uint256(0),   "PF:SMP:INVALID_TO_VERSION");
        require(migrator != address(0),    "PF:SMP:ZERO_MIGRATOR");

        emit MigrationPathSet(fromVersion, toVersion, migratorForPath[fromVersion][toVersion] = migrator);
    }

    function upgradeImplementationFor(address proxy, uint256 toVersion, bytes calldata migrationArguments) external virtual override {
        return _upgradeImplementationFor(proxy, toVersion, migrationArguments);
    }

    function _upgradeImplementationFor(address proxy, uint256 toVersion, bytes calldata migrationArguments) internal {
        uint256 fromVersion = versionOf[implementationFor[proxy]];
        address migrator    = migratorForPath[fromVersion][toVersion];

        require(migrator != address(0), "PF:UIF:NO_MIGRATOR");

        implementationFor[proxy] = implementation[toVersion];

        (bool success,) = proxy.call(abi.encodeWithSelector(IProxied.migrate.selector, migrator, migrationArguments));
        require(success, "PF:UIF:MIGRATION_FAILED");

        emit InstanceUpgrade(proxy, fromVersion, toVersion, migrationArguments);
    }

}
