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

    function registerMigrator(uint256 fromVersion, uint256 toVersion, address migrator) external {
        require(_registerMigrator(fromVersion, toVersion, migrator));
    }

    function upgradeInstance(address proxy, uint256 toVersion, bytes calldata migrationArguments) external {
        require(_upgradeInstance(proxy, toVersion, migrationArguments));
    }

}

// Used to initialize V1 contracts ("constructor")
contract MockInitializerV1 is SlotManipulatable {

    event Initialized(uint256 beta, uint256 charlie, uint256 delta15);

    bytes32 private constant DELTA_SLOT = 0x1111111111111111111111111111111111111111111111111111111111111111;

    function _setDeltaOf(uint256 key, uint256 newDelta) internal {
        _setSlotValue(_getReferenceTypeSlot(DELTA_SLOT, bytes32(key)), bytes32(newDelta));
    }

    fallback() external {
        // Set beta (in slot 0) to 1313
        _setSlotValue(bytes32(0), bytes32(uint256(1313)));

        // Set charlie (in slot 1) to 1717
        _setSlotValue(bytes32(uint256(1)), bytes32(uint256(1717)));

        // Set deltaOf[15] to 4747
        _setDeltaOf(15, 4747);

        emit Initialized(1313, 1717, 4747);
    }

}

interface IMockImplementationV1 is IProxied {

    function alpha() external view returns (uint256);
    
    function beta() external view returns (uint256);

    function charlie() external view returns (uint256);

    function getLiteral() external pure returns (uint256);

    function getConstant() external pure returns (uint256);

    function getViewable() external view returns (uint256);

    function setBeta(uint256 newBeta) external;

    function setCharlie(uint256 newCharlie) external;

    function deltaOf(uint256 key) external view returns (uint256);

    function setDeltaOf(uint256 key, uint256 newDelta) external;

    // Composability

    function getAnotherBeta(address other) external view returns (uint256);

    function setAnotherBeta(address other, uint256 newBeta) external;

}

contract MockImplementationV1 is IMockImplementationV1, Proxied {

    // Some "Nothing Up My Sleeve" Slot
    bytes32 private constant DELTA_SLOT = 0x1111111111111111111111111111111111111111111111111111111111111111;

    uint256 public constant override alpha = 1111;

    uint256 public override beta;
    uint256 public override charlie;

    // NOTE: This is implemented manually in order to support upgradeability and migrations
    // mapping(uint256 => uint256) public override deltaOf;

    function getLiteral() external pure override returns (uint256) {
        return 2222;
    }

    function getConstant() external pure override returns (uint256) {
        return alpha;
    }

    function getViewable() external view override returns (uint256) {
        return beta;
    }

    function setBeta(uint256 newBeta) external override {
        beta = newBeta;
    }

    function setCharlie(uint256 newCharlie) external override {
        charlie = newCharlie;
    }

    function deltaOf(uint256 key) public view override returns (uint256) {
        return uint256(_getSlotValue((_getReferenceTypeSlot(DELTA_SLOT, bytes32(key)))));
    }

    function setDeltaOf(uint256 key, uint256 newDelta) public override {
        _setSlotValue(_getReferenceTypeSlot(DELTA_SLOT, bytes32(key)), bytes32(newDelta));
    }

    // Composability

    function getAnotherBeta(address other) external view override returns (uint256) {
        return IMockImplementationV1(other).beta();
    }

    function setAnotherBeta(address other, uint256 newBeta) external override {
        IMockImplementationV1(other).setBeta(newBeta);
    }

}

// Used to initialize V2 contracts ("constructor")
contract MockInitializerV2 is SlotManipulatable {

    event Initialized(uint256 charlie, uint256 echo, uint256 derby15);

    bytes32 private constant DERBY_SLOT = 0x1111111111111111111111111111111111111111111111111111111111111111;

    function _setDerbyOf(uint256 key, uint256 newDelta) internal {
        _setSlotValue(_getReferenceTypeSlot(DERBY_SLOT, bytes32(key)), bytes32(newDelta));
    }

    fallback() external {
        uint256 arg = abi.decode(msg.data, (uint256));

        // Set charlie (in slot 0) to 3434
        _setSlotValue(bytes32(0), bytes32(uint256(3434)));

        // Set echo (in slot 1) to 3333
        _setSlotValue(bytes32(uint256(1)), bytes32(uint256(3333)));

        // Set derbyOf[15] based on arg
        _setDerbyOf(15, arg);

        emit Initialized(3434, 3333, arg);
    }

}

interface IMockImplementationV2 is IProxied {

    function axiom() external view returns (uint256);

    function charlie() external view returns (uint256);

    function echo() external view returns (uint256);

    function getLiteral() external pure returns (uint256);

    function getConstant() external pure returns (uint256);

    function getViewable() external view returns (uint256);

    function setCharlie(uint256 newCharlie) external;

    function setEcho(uint256 newEcho) external;

    function derbyOf(uint256 key) external view returns (uint256);

    function setDerbyOf(uint256 key, uint256 newDerby) external;

}

contract MockImplementationV2 is IMockImplementationV2, Proxied {

    // Same "Nothing Up My Sleeve" Slot as in V1
    bytes32 private constant DERBY_SLOT = 0x1111111111111111111111111111111111111111111111111111111111111111;

    uint256 public constant override axiom = 5555;

    uint256 public override charlie;  // Same charlie as in V1
    uint256 public override echo;

    // NOTE: This is implemented manually in order to support upgradeability and migrations
    // mapping(uint256 => uint256) public override derbyOf;

    function getLiteral() external pure override returns (uint256) {
        return 4444;
    }

    function getConstant() external pure override returns (uint256) {
        return axiom;
    }

    function getViewable() external view override returns (uint256) {
        return echo;
    }

    function setCharlie(uint256 newCharlie) external override {
        charlie = newCharlie;
    }

    function setEcho(uint256 newEcho) external override {
        echo = newEcho;
    }
    
    function derbyOf(uint256 key) public view override returns (uint256) {
        return uint256(_getSlotValue(_getReferenceTypeSlot(DERBY_SLOT, bytes32(key))));
    }

    function setDerbyOf(uint256 key, uint256 newDerby) public override {
        _setSlotValue(_getReferenceTypeSlot(DERBY_SLOT, bytes32(key)), bytes32(newDerby));
    }

}

// Used to migrate V1 contracts to v2 (may contain initialization logic as well)
contract MockMigratorV1ToV2 is SlotManipulatable {

    event Migrated(uint256 newCharlie, uint256 echo, uint256 derby15, uint256 newDerby4);

    bytes32 private constant DERBY_SLOT = 0x1111111111111111111111111111111111111111111111111111111111111111;

    function _setDerbyOf(uint256 key, uint256 newDelta) internal {
        _setSlotValue(_getReferenceTypeSlot(DERBY_SLOT, bytes32(key)), bytes32(newDelta));
    }

    function _getDerbyOf(uint256 key) public view returns (uint256) {
        return uint256(_getSlotValue(_getReferenceTypeSlot(DERBY_SLOT, bytes32(key))));
    }

    fallback() external {
        uint256 arg = abi.decode(msg.data, (uint256));

        // NOTE: It is possible to do this specific migration more optimally, but this is just a clear example

        // Delete beta from V1
        _setSlotValue(0, 0);

        // Move charlie from V1 up a slot (slot 1 to slot 2)
        _setSlotValue(bytes32(0), _getSlotValue(bytes32(uint256(1))));
        _setSlotValue(bytes32(uint256(1)), bytes32(0));

        // Double value of charlie from V1
        uint256 newCharlie = uint256(_getSlotValue(bytes32(0))) * 2;
        _setSlotValue(bytes32(0), bytes32(newCharlie));

        // Set echo (in slot 1) to 3333
        _setSlotValue(bytes32(uint256(1)), bytes32(uint256(3333)));

        // Set derbyOf[15] based on arg
        _setDerbyOf(15, arg);

        // If derbyOf[2] is set, set derbyOf[4] to 18
        uint256 newDerby4 = _getDerbyOf(4);
        if (_getDerbyOf(2) != 0) {
            _setDerbyOf(4, newDerby4 = 1188);
        }

        emit Migrated(newCharlie, 3333, arg, newDerby4);
    }

}

contract MockMigratorV1ToV2WithNoArgs is SlotManipulatable {

    event Migrated(uint256 newCharlie, uint256 echo, uint256 newDerby4);

    bytes32 private constant DERBY_SLOT = 0x1111111111111111111111111111111111111111111111111111111111111111;

    function _setDerbyOf(uint256 key, uint256 newDelta) internal {
        _setSlotValue(_getReferenceTypeSlot(DERBY_SLOT, bytes32(key)), bytes32(newDelta));
    }

    function _getDerbyOf(uint256 key) public view returns (uint256) {
        return uint256(_getSlotValue(_getReferenceTypeSlot(DERBY_SLOT, bytes32(key))));
    }

    fallback() external {
        // NOTE: It is possible to do this specific migration more optimally, but this is just a clear example

        // Delete beta from V1
        _setSlotValue(0, 0);

        // Move charlie from V1 up a slot (slot 1 to slot 2)
        _setSlotValue(bytes32(0), _getSlotValue(bytes32(uint256(1))));
        _setSlotValue(bytes32(uint256(1)), bytes32(0));

        // Double value of charlie from V1
        uint256 newCharlie = uint256(_getSlotValue(bytes32(0))) * 2;
        _setSlotValue(bytes32(0), bytes32(newCharlie));

        // Set echo (in slot 1) to 3333
        _setSlotValue(bytes32(uint256(1)), bytes32(uint256(3333)));

        // Set derbyOf[15] based on arg
        _setDerbyOf(15, 15);

        // If derbyOf[2] is set, set derbyOf[4] to 18
        uint256 newDerby4 = _getDerbyOf(4);
        if (_getDerbyOf(2) != 0) {
            _setDerbyOf(4, newDerby4 = 1188);
        }

        emit Migrated(newCharlie, 3333, newDerby4);
    }

}
