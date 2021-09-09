// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { DSTest } from "../../modules/ds-test/src/test.sol";

import { SlotManipulatable }  from "../SlotManipulatable.sol";

contract StorageContract is SlotManipulatable {

    bytes32 private constant UINT_SLOT    = 0x1111111111111111111111111111111111111111111111111111111111111111;
    bytes32 private constant ADDRESS_SLOT = 0x2222222222222222222222222222222222222222222222222222222222222222;
    bytes32 private constant BYTES_SLOT   = 0x3333333333333333333333333333333333333333333333333333333333333333;
    
    uint256 public slot0 = 1;
    
    /************************/
    /*** Internal Helpers ***/
    /************************/

    function _setReferenceTypeOf(bytes32 slot, bytes32 key, bytes32 value) internal {
        _setSlotValue(_getReferenceTypeSlot(slot, key), value);
    }

    function _bytes32(address value) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(value)));
    }

    function _address(bytes32 value) internal pure returns (address) {
        return address(uint160(uint256(value)));
    }

    /*****************/
    /*** Setters ****/
    /****************/

    function setSlotValue(bytes32 slot, bytes32 value) external {
        _setSlotValue(slot, value);
    }

    function setUint256Of(uint256 key, uint256 value) external {
        _setSlotValue(_getReferenceTypeSlot(UINT_SLOT, bytes32(key)), bytes32(value));
    }

    function setUint256Of(uint256 key, address value) external {
        _setSlotValue(_getReferenceTypeSlot(UINT_SLOT, bytes32(key)), _bytes32(value));
    }

    function setUint256Of(uint256 key, bytes32 value) external {
        _setSlotValue(_getReferenceTypeSlot(UINT_SLOT, bytes32(key)), value);
    }

    function setAddressOf(address key, uint256 value) external {
        _setSlotValue(_getReferenceTypeSlot(ADDRESS_SLOT, _bytes32(key)), bytes32(value));
    }

    function setAddressOf(address key, address value) external {
        _setSlotValue(_getReferenceTypeSlot(ADDRESS_SLOT, _bytes32(key)), _bytes32(value));
    }

    function setAddressOf(address key, bytes32 value) external {
        _setSlotValue(_getReferenceTypeSlot(ADDRESS_SLOT, _bytes32(key)), value);
    }

    function setBytes32Of(bytes32 key, uint256 value) external {
        _setSlotValue(_getReferenceTypeSlot(BYTES_SLOT, bytes32(key)), bytes32(value));
    }

    function setBytes32Of(bytes32 key, address value) external {
        _setSlotValue(_getReferenceTypeSlot(BYTES_SLOT, bytes32(key)), _bytes32(value));
    }

    function setBytes32Of(bytes32 key, bytes32 value) external {
        _setSlotValue(_getReferenceTypeSlot(BYTES_SLOT, bytes32(key)), value);
    }

    /*****************/
    /*** Getters ****/
    /*****+*********/

    function getSlotValue(bytes32 slot) external view returns (bytes32 value){
        value = _getSlotValue(slot);
    }

    function getUint256In(uint256 key) external view returns (uint256 value) {
        value = uint256(_getSlotValue(_getReferenceTypeSlot(UINT_SLOT, bytes32(key))));
    }

    function getUint256In(address key) external view returns (uint256 value) {
        value = uint256(_getSlotValue(_getReferenceTypeSlot(ADDRESS_SLOT, _bytes32(key))));
    }

    function getUint256In(bytes32 key) external view returns (uint256 value) {
        value = uint256(_getSlotValue(_getReferenceTypeSlot(BYTES_SLOT, key)));
    }

    function getAddressIn(uint256 key) external view returns (address value) {
        value = _address(_getSlotValue(_getReferenceTypeSlot(UINT_SLOT, bytes32(key))));
    }

    function getAddressIn(address key) external view returns (address value) {
        value = _address(_getSlotValue(_getReferenceTypeSlot(ADDRESS_SLOT, _bytes32(key))));
    }

    function getAddressIn(bytes32 key) external view returns (address value) {
        value = _address(_getSlotValue(_getReferenceTypeSlot(BYTES_SLOT, key)));
    }

    function getBytes32In(uint256 key) external view returns (bytes32 value) {
        value = _getSlotValue(_getReferenceTypeSlot(UINT_SLOT, bytes32(key)));
    }

    function getBytes32In(address key) external view returns (bytes32 value) {
        value = _getSlotValue(_getReferenceTypeSlot(ADDRESS_SLOT, _bytes32(key)));
    }

    function getBytes32In(bytes32 key) external view returns (bytes32 value) {
        value = _getSlotValue(_getReferenceTypeSlot(BYTES_SLOT, key));
    }
}

contract SlotManipulatableTest is DSTest {

    StorageContract storageContract;

    function setUp() external {
        storageContract = new StorageContract();
    }

    function test_setAndRetrieve_bytes32(bytes32 value) external {
        storageContract.setSlotValue(bytes32(0), value);

        assertEq(storageContract.getSlotValue(bytes32(0)), value);
    }

    function test_setAndRetrieve_uint(uint256 value) external {
        storageContract.setSlotValue(bytes32(0), bytes32(value));

        assertEq(uint256(storageContract.getSlotValue(bytes32(0))), value);
    }

    function test_setAndRetrieve_address(address value) external {
        storageContract.setSlotValue(bytes32(0), bytes32(uint256(uint160(value))));

        assertEq(address(uint160(uint256(storageContract.getSlotValue(bytes32(0))))), value);
    }

    function test_referenceType_uint256ToUint256(uint256 key, uint256 value) external {
        storageContract.setUint256Of(key, value);

        assertEq(storageContract.getUint256In(key), value);
    }

    function test_referenceType_uint256ToAddress(uint256 key, address value) external {
        storageContract.setUint256Of(key, value);

        assertEq(storageContract.getAddressIn(key), value);
    }

    function test_referenceType_uint256ToBytes32(uint256 key, bytes32 value) external {
        storageContract.setUint256Of(key, value);

        assertEq(storageContract.getBytes32In(key), value);
    }

    function test_referenceType_addressToUint256(address key, uint256 value) external {
        storageContract.setAddressOf(key, value);

        assertEq(storageContract.getUint256In(key), value);
    }

    function test_referenceType_addressToAddress(address key, address value) external {
        storageContract.setAddressOf(key, value);

        assertEq(storageContract.getAddressIn(key), value);
    }

    function test_referenceType_addressToBytes32(address key, bytes32 value) external {
        storageContract.setAddressOf(key, value);

        assertEq(storageContract.getBytes32In(key), value);
    }

    function test_referenceType_bytes32ToUints256(bytes32 key, uint256 value) external {
        storageContract.setBytes32Of(key, value);

        assertEq(storageContract.getUint256In(key), value);
    }

    function test_referenceType_bytes32ToAddress(bytes32 key, address value) external {
        storageContract.setBytes32Of(key, value);

        assertEq(storageContract.getAddressIn(key), value);
    }

    function test_referenceType_bytes32ToBytes32(bytes32 key, bytes32 value) external {
        storageContract.setBytes32Of(key, value);

        assertEq(storageContract.getBytes32In(key), value);
    }

}
