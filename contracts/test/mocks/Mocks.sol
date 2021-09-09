// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IProxied } from "../../interfaces/IProxied.sol";

import { Proxied }           from "../../Proxied.sol";
import { ProxyFactory }      from "../../ProxyFactory.sol";
import { SlotManipulatable } from "../../SlotManipulatable.sol";

contract MockFactory is ProxyFactory {

    function implementation(uint256 version) external view returns (address) {
        return _implementation[version];
    }

    function migratorForPath(uint256 fromVersion, uint256 toVersion) external view returns (address) {
        return _migratorForPath[fromVersion][toVersion];
    }

    function versionOf(address proxy) external view returns (uint256) {
        return _versionOf[proxy];
    }

    function registerImplementation(uint256 version, address implementationAddress) external {
        require(_registerImplementation(version, implementationAddress));
    }

    function newInstance(uint256 version, bytes calldata initializationArguments) external returns (address proxy) {
        bool success;
        (success, proxy) = _newInstance(version, initializationArguments);
        require(success);
    }

    function newInstanceWithSalt(uint256 version, bytes calldata initializationArguments, bytes32 salt) external returns (address proxy) {
        bool success;
        (success, proxy) = _newInstanceWithSalt(version, initializationArguments, salt);
        require(success);
    }

    function registerMigrationPath(uint256 fromVersion, uint256 toVersion, address migrator) external {
        require(_registerMigrationPath(fromVersion, toVersion, migrator));
    }

    function upgradeInstance(address proxy, uint256 toVersion, bytes calldata migrationArguments) external {
        require(_upgradeInstance(proxy, toVersion, migrationArguments));
    }

}

// Used to initialize V1 contracts ("constructor")
contract MockInitializerV1 is SlotManipulatable {

    event Initialized(uint256 storageVariable);

    fallback() external {

        // Set storageVariable (in slot 0) to 1313
        _setSlotValue(bytes32(0), bytes32(uint256(1313)));

        emit Initialized(1313);
    }

}

interface IMockInitializerV1 is IProxied {

    function storageVariable() external view returns (uint256);

    function setStorageVariable(uint256 newStorageVariable) external;

}

contract MockImplementationV1 is IMockInitializerV1, Proxied {

    uint256 public override storageVariable;

    function setStorageVariable(uint256 newStorageVariable) external override {
        storageVariable = newStorageVariable;
    }

}

// Used to initialize V2 contracts ("constructor")
contract MockInitializerV2 is SlotManipulatable {

    event Initialized(uint256 argument);

    fallback() external {
        if (msg.data.length == 0) return;

        uint256 arg = abi.decode(msg.data, (uint256));

        // Set storageVariable (in slot 0) to 3434
        _setSlotValue(bytes32(0), bytes32(uint256(arg)));

        emit Initialized(arg);
    }

}

interface IMockInitializerV2 is IProxied {

    function storageVariable() external view returns (uint256);

    function incrementStorageVariable() external;

}

contract MockImplementationV2 is IMockInitializerV2, Proxied {

    uint256 public override storageVariable;

    function incrementStorageVariable() external override {
        storageVariable++;
    }
}

// Used to migrate V1 contracts to v2 (may contain initialization logic as well)
contract MockMigratorV1ToV2 is SlotManipulatable {

    event Migrated(uint256 argument);

    fallback() external {
        uint256 arg = abi.decode(msg.data, (uint256));

        _setSlotValue(bytes32(0), bytes32(uint256(arg)));
       
        emit Migrated(arg);
    }

}

contract MockMigratorV1ToV2WithNoArgs is SlotManipulatable {

    event Migrated(uint256 defaultValue);

    fallback() external {

        _setSlotValue(bytes32(0), bytes32(uint256(1111)));
       
        emit Migrated(1111);
    }

}