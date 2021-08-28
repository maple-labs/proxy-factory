// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SlotManipulatable {

    function _getSlotValue(bytes32 slot) internal view returns (bytes32 value) {
        assembly {
            value := sload(slot)
        }
    }

    function _setSlotValue(bytes32 slot, bytes32 value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function _getReferenceTypeSlot(bytes32 slot, bytes32 key) internal pure returns (bytes32 value) {
        return keccak256(abi.encodePacked(key, slot));
    }

}
