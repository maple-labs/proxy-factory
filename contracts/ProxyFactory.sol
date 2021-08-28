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

    function _getUpgradePath(uint256 oldVersion, uint256 newVersion) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(oldVersion, newVersion));
    }

    function registerImplementation(uint256 version, address implementationAddress, address initializer) external override {
        require(implementationAddress != address(0),   "PF:RI:ZERO_ADDRESS");
        require(implementation[version] == address(0), "PF:RI:ALREADY_REGISTERED");
        require(initializer != address(0),             "PF:RI:ZERO_INITIALIZER");

        implementation[version]          = implementationAddress;
        initializerFor[version]          = initializer;
        versionOf[implementationAddress] = version;
    }

    function setRecommendedVersion(uint256 version) external override {
        recommendedVersion = version;
    }

    function newInstance(uint256 version, bytes calldata initializationArguments) external override returns (address proxy) {
        address initializer = initializerFor[version];
        require(initializer != address(0), "PF:NI:NO_INITIALIZER");

        implementationFor[proxy = address(new Proxy(address(this)))] = implementation[version];

        (bool success,) = proxy.call(abi.encodeWithSelector(IProxied.initialize.selector, initializer, initializationArguments));
        require(success, "PF:NI:INITIALIZE_FAILED");
    }

    function getImplementation() external override view returns (address) {
        return implementationFor[msg.sender];
    }

    function setMigrationPath(uint256 oldVersion, uint256 newVersion, address migrator) external override {
        require(implementation[oldVersion] != address(0), "PF:SUP:OLD_NOT_REGISTERED");
        require(implementation[newVersion] != address(0), "PF:SUP:NEW_NOT_REGISTERED");
        require(migrator != address(0),                   "PF:SUP:ZERO_MIGRATOR");

        migratorForPath[_getUpgradePath(oldVersion, newVersion)] = migrator;
    }

    function upgradeImplementationFor(address proxy, uint256 oldVersion, uint256 newVersion, bytes calldata migrationArguments) external override {
        require(implementation[oldVersion] == implementationFor[proxy], "PF:UIF:INCORRECT_VERSION");
        
        address migrator = migratorForPath[_getUpgradePath(oldVersion, newVersion)];
        require(migrator != address(0), "PF:UIF:NO_MIGRATOR");

        implementationFor[proxy] = implementation[newVersion];

        (bool success,) = proxy.call(abi.encodeWithSelector(IProxied.migrate.selector, migrator, migrationArguments));
        require(success, "PF:UIF:MIGRATION_FAILED");

    }

}
