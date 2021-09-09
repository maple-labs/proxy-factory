// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { SlotManipulatable } from "./SlotManipulatable.sol";

contract Proxy is SlotManipulatable {

    /// @dev Storage slot with the address of the current factory. This is the keccak-256 hash of "FACTORY_SLOT".
    bytes32 private constant FACTORY_SLOT = 0xf2db84db8157f5a01a257d644038e8929d5a62c9ffa8b736374913908897e5bb;

    /// @dev Storage slot with the address of the current implementation. This is the keccak-256 hash of "IMPLEMENTATION_SLOT".
    bytes32 private constant IMPLEMENTATION_SLOT = 0xf603533e14e17222e047634a2b3457fe346d27e294cedf9d21d74e5feea4a046;

    function _setup() private {
        (address factory, address implementation) = abi.decode(msg.data, (address, address));
        _setSlotValue(FACTORY_SLOT,        bytes32(uint256(uint160(factory))));
        _setSlotValue(IMPLEMENTATION_SLOT, bytes32(uint256(uint160(implementation))));
    }

    function _fallback() private {
        bytes32 implementation = _getSlotValue(IMPLEMENTATION_SLOT);

        if (implementation == bytes32(0)) return _setup();

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() payable external virtual {
        _fallback();
    }

}
