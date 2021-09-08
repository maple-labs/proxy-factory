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

interface IMockInitializerV1 is IProxied {

    function alpha() external view returns (uint256);
    
    function beta() external view returns (uint256);

    function charlie() external view returns (uint256);

    function getLiteral() external pure returns (uint256);

    function getConstant() external pure returns (uint256);

    function getViewable() external view returns (uint256);

    function setBeta(uint256 newBeta) external;

    function setBetaAndReturnOldBeta(uint256 newBeta) external returns (uint256 oldBeta);

    function setCharlie(uint256 newCharlie) external;

    function setCharlieAndReturnOldCharlie(uint256 newCharlie) external returns (uint256 oldCharlie);

    function deltaOf(uint256 key) external view returns (uint256);

    function setDeltaOf(uint256 key, uint256 newDelta) external;

    function setDeltaOfAndReturnOldDeltaOf(uint256 key, uint256 newDelta) external returns (uint256 oldDelta);

    // Composability

    function getAnotherFactory(address other) external view returns (address);

    function getAnotherImplementation(address other) external view returns (address);

    function getAnotherAlpha(address other) external view returns (uint256);

    function getAnotherBeta(address other) external view returns (uint256);

    function getAnotherCharlie(address other) external view returns (uint256);

    function getAnotherDeltaOf(address other, uint256 index) external view returns (uint256);

    function getAnotherLiteral(address other) external pure returns (uint256);

    function getAnotherConstant(address other) external pure returns (uint256);

    function getAnotherViewable(address other) external view returns (uint256);

    function setAnotherBeta(address other, uint256 newBeta) external;

    function setAnotherBetaAndReturnOldBeta(address other, uint256 newBeta) external returns (uint256);

    function setAnotherCharlie(address other, uint256 newCharlie) external;

    function setAnotherCharlieAndReturnOldCharlie(address other, uint256 newCharlie) external returns (uint256);

    function setAnotherDelta(address other, uint256 key, uint256 newDelta) external;

    function setAnotherDeltaOfAndReturnOldDeltaOf(address other, uint256 key, uint256 newDelta) external returns (uint256 oldDelta);

}

contract MockImplementationV1 is IMockInitializerV1, Proxied {

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

    function setBetaAndReturnOldBeta(uint256 newBeta) external override returns (uint256 oldBeta) {
        oldBeta = beta;
        beta = newBeta;
    }

    function setCharlie(uint256 newCharlie) external override {
        charlie = newCharlie;
    }

    function setCharlieAndReturnOldCharlie(uint256 newCharlie) external override returns (uint256 oldCharlie) {
        oldCharlie = charlie;
        charlie = newCharlie;
    }

    function deltaOf(uint256 key) public view override returns (uint256) {
        return uint256(_getSlotValue((_getReferenceTypeSlot(DELTA_SLOT, bytes32(key)))));
    }

    function setDeltaOf(uint256 key, uint256 newDelta) public override {
        _setSlotValue(_getReferenceTypeSlot(DELTA_SLOT, bytes32(key)), bytes32(newDelta));
    }

    function setDeltaOfAndReturnOldDeltaOf(uint256 key, uint256 newDelta) external override returns (uint256 oldDelta) {
        oldDelta = deltaOf(key);
        setDeltaOf(key, newDelta);
    }

    // Composability

    function getAnotherFactory(address other) external view override returns (address) {
        return IMockInitializerV1(other).factory();
    }

    function getAnotherImplementation(address other) external view override returns (address) {
        return IMockInitializerV1(other).implementation();
    }

    function getAnotherAlpha(address other) external view override returns (uint256) {
        return IMockInitializerV1(other).alpha();
    }

    function getAnotherBeta(address other) external view override returns (uint256) {
        return IMockInitializerV1(other).beta();
    }

    function getAnotherCharlie(address other) external view override returns (uint256) {
        return IMockInitializerV1(other).charlie();
    }

    function getAnotherDeltaOf(address other, uint256 index) external view override returns (uint256) {
        return IMockInitializerV1(other).deltaOf(index);
    }

    function getAnotherLiteral(address other) external pure override returns (uint256) {
        return IMockInitializerV1(other).getLiteral();
    }

    function getAnotherConstant(address other) external pure override returns (uint256) {
        return IMockInitializerV1(other).getConstant();
    }

    function getAnotherViewable(address other) external view override returns (uint256) {
        return IMockInitializerV1(other).getViewable();
    }

    function setAnotherBeta(address other, uint256 newBeta) external override {
        IMockInitializerV1(other).setBeta(newBeta);
    }

    function setAnotherBetaAndReturnOldBeta(address other, uint256 newBeta) external override returns (uint256) {
        return IMockInitializerV1(other).setBetaAndReturnOldBeta(newBeta);
    }

    function setAnotherCharlie(address other, uint256 newCharlie) external override {
        IMockInitializerV1(other).setCharlie(newCharlie);
    }

    function setAnotherCharlieAndReturnOldCharlie(address other, uint256 newCharlie) external override returns (uint256) {
        return IMockInitializerV1(other).setCharlieAndReturnOldCharlie(newCharlie);
    }

    function setAnotherDelta(address other, uint256 key, uint256 newDelta) external override {
        IMockInitializerV1(other).setDeltaOf(key, newDelta);
    }

    function setAnotherDeltaOfAndReturnOldDeltaOf(address other, uint256 key, uint256 newDelta) external override returns (uint256 oldDelta) {
        return IMockInitializerV1(other).setDeltaOfAndReturnOldDeltaOf(key, newDelta);
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

interface IMockInitializerV2 is IProxied {

    function axiom() external view returns (uint256);

    function charlie() external view returns (uint256);

    function echo() external view returns (uint256);

    function getLiteral() external pure returns (uint256);

    function getConstant() external pure returns (uint256);

    function getViewable() external view returns (uint256);

    function setCharlie(uint256 newCharlie) external;

    function setCharlieAndReturnOldCharlie(uint256 newCharlie) external returns (uint256 oldCharlie);

    function setEcho(uint256 newEcho) external;

    function setEchoAndReturnOldEcho(uint256 newEcho) external returns (uint256 oldEcho);

    function derbyOf(uint256 key) external view returns (uint256);

    function setDerbyOf(uint256 key, uint256 newDerby) external;

    function setDerbyOfAndReturnOldDerbyOf(uint256 key, uint256 newDerby) external returns (uint256 oldDerby);

    // Composability

    function getAnotherFactory(address other) external view returns (address);

    function getAnotherImplementation(address other) external view returns (address);

    function getAnotherAxiom(address other) external view returns (uint256);

    function getAnotherCharlie(address other) external view returns (uint256);

    function getAnotherDerbyOf(address other, uint256 index) external view returns (uint256);

    function getAnotherEcho(address other) external view returns (uint256);

    function getAnotherLiteral(address other) external pure returns (uint256);

    function getAnotherConstant(address other) external pure returns (uint256);

    function getAnotherViewable(address other) external view returns (uint256);

    function setAnotherCharlie(address other, uint256 newCharlie) external;

    function setAnotherCharlieAndReturnOldCharlie(address other, uint256 newCharlie) external returns (uint256);

    function setAnotherEcho(address other, uint256 newEcho) external;

    function setAnotherEchoAndReturnOldEcho(address other, uint256 newEcho) external returns (uint256);

    function setAnotherDerby(address other, uint256 key, uint256 newDerby) external;

    function setAnotherDerbyOfAndReturnOldDerbyOf(address other, uint256 key, uint256 newDerby) external returns (uint256 oldDerby);

}

contract MockImplementationV2 is IMockInitializerV2, Proxied {

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

    function setCharlieAndReturnOldCharlie(uint256 newCharlie) external override returns (uint256 oldCharlie) {
        oldCharlie = charlie;
        charlie = newCharlie;
    }

    function setEcho(uint256 newEcho) external override {
        echo = newEcho;
    }

    function setEchoAndReturnOldEcho(uint256 newEcho) external override returns (uint256 oldEcho) {
        oldEcho = echo;
        echo = newEcho;
    }

    function derbyOf(uint256 key) public view override returns (uint256) {
        return uint256(_getSlotValue(_getReferenceTypeSlot(DERBY_SLOT, bytes32(key))));
    }

    function setDerbyOf(uint256 key, uint256 newDerby) public override {
        _setSlotValue(_getReferenceTypeSlot(DERBY_SLOT, bytes32(key)), bytes32(newDerby));
    }

    function setDerbyOfAndReturnOldDerbyOf(uint256 key, uint256 newDerby) external override returns (uint256 oldDerby) {
        oldDerby = derbyOf(key);
        setDerbyOf(key, newDerby);
    }

    // Composability

    function getAnotherFactory(address other) external view override returns (address) {
        return IMockInitializerV2(other).factory();
    }

    function getAnotherImplementation(address other) external view override returns (address) {
        return IMockInitializerV2(other).implementation();
    }

    function getAnotherAxiom(address other) external view override returns (uint256) {
        return IMockInitializerV2(other).axiom();
    }

    function getAnotherCharlie(address other) external view override returns (uint256) {
        return IMockInitializerV2(other).charlie();
    }

    function getAnotherDerbyOf(address other, uint256 index) external view override returns (uint256) {
        return IMockInitializerV2(other).derbyOf(index);
    }

    function getAnotherEcho(address other) external view override returns (uint256) {
        return IMockInitializerV2(other).echo();
    }

    function getAnotherLiteral(address other) external pure override returns (uint256) {
        return IMockInitializerV2(other).getLiteral();
    }

    function getAnotherConstant(address other) external pure override returns (uint256) {
        return IMockInitializerV2(other).getConstant();
    }

    function getAnotherViewable(address other) external view override returns (uint256) {
        return IMockInitializerV2(other).getViewable();
    }

    function setAnotherCharlie(address other, uint256 newCharlie) external override {
        IMockInitializerV2(other).setCharlie(newCharlie);
    }

    function setAnotherCharlieAndReturnOldCharlie(address other, uint256 newCharlie) external override returns (uint256) {
        return IMockInitializerV2(other).setCharlieAndReturnOldCharlie(newCharlie);
    }

    function setAnotherEcho(address other, uint256 newEcho) external override {
        IMockInitializerV2(other).setEcho(newEcho);
    }

    function setAnotherEchoAndReturnOldEcho(address other, uint256 newEcho) external override returns (uint256) {
        return IMockInitializerV2(other).setEchoAndReturnOldEcho(newEcho);
    }

    function setAnotherDerby(address other, uint256 key, uint256 newDerby) external override {
        IMockInitializerV2(other).setDerbyOf(key, newDerby);
    }

    function setAnotherDerbyOfAndReturnOldDerbyOf(address other, uint256 key, uint256 newDerby) external override returns (uint256 oldDerby) {
        return IMockInitializerV2(other).setDerbyOfAndReturnOldDerbyOf(key, newDerby);
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


contract MockMigratorV2ToV3 is SlotManipulatable {

    fallback() external {
        _setSlotValue(bytes32(0), _getSlotValue(bytes32(uint256(3))));
    }

}

contract MockV3 is Proxied {
    
}