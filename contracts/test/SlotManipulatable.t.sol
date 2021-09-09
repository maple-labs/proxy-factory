// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { DSTest } from "../../modules/ds-test/src/test.sol";

import { SlotManipulatable }  from "../SlotManipulatable.sol";

contract StorageContract is SlotManipulatable {

    bytes32 private constant REFERENCE_SLOT    = 0x1111111111111111111111111111111111111111111111111111111111111111;
    
    /************************/
    /*** Internal Helpers ***/
    /************************/

    function _setReferenceTypeOf(bytes32 slot, bytes32 key, bytes32 value) internal {
        _setSlotValue(_getReferenceTypeSlot(slot, key), value);
    }

    /*****************/
    /*** External ****/
    /****************/

    function setSlotValue(bytes32 slot, bytes32 value) external {
        _setSlotValue(slot, value);
    }

    function setReferenceValue(bytes32 key, bytes32 value) external {
        _setSlotValue(_getReferenceTypeSlot(REFERENCE_SLOT, bytes32(key)), value);
    }

    function getSlotValue(bytes32 slot) external view returns (bytes32 value){
        value = _getSlotValue(slot);
    }

    function getReferenceValue(bytes32 key) external view returns (bytes32 value) {
        value = _getSlotValue(_getReferenceTypeSlot(REFERENCE_SLOT, key));
    }

    function getReferenceSlot(bytes32 slot, bytes32 key) external pure returns (bytes32) {
        return _getReferenceTypeSlot(REFERENCE_SLOT, _getReferenceTypeSlot(slot, key));
    }

}

contract SlotManipulatableTest is DSTest {

    StorageContract storageContract;

    function _bytes32(address value) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(value)));
    }

    function _address(bytes32 value) internal pure returns (address) {
        return address(uint160(uint256(value)));
    }

    function setUp() external {
        storageContract = new StorageContract();
    }

    function test_setAndRetrieve_uint256(uint256 value) external {
        storageContract.setSlotValue(bytes32(0), bytes32(value));

        assertEq(uint256(storageContract.getSlotValue(bytes32(0))), value);
    }

    function test_setAndRetrieve_address(address value) external {
        storageContract.setSlotValue(bytes32(0), bytes32(uint256(uint160(value))));

        assertEq(address(uint160(uint256(storageContract.getSlotValue(bytes32(0))))), value);
    }

    function test_setAndRetrieve_bytes32(bytes32 value) external {
        storageContract.setSlotValue(bytes32(0), value);

        assertEq(storageContract.getSlotValue(bytes32(0)), value);
    }

    function test_setAndRetrieve_uint8(uint8 value) external {
        storageContract.setSlotValue(bytes32(0), bytes32(uint256(value)));

        assertEq(uint8(uint256(storageContract.getSlotValue(bytes32(0)))), value);
    }

    function test_referenceType(bytes32 key, bytes32 value) external {
        storageContract.setReferenceValue(key, value);

        assertEq(storageContract.getReferenceValue(key), value);
    }

    function test_doubleReferenceType(bytes32 key, bytes32 index, bytes32 value) external {
        bytes32 slot = storageContract.getReferenceSlot(key, index);

        storageContract.setReferenceValue(slot, value);

        assertEq(storageContract.getReferenceValue(slot), value);
    }

}
