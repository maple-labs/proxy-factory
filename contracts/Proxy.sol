// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IDefaultImplementationBeacon } from "./interfaces/IDefaultImplementationBeacon.sol";

import { SlotManipulatable } from "./SlotManipulatable.sol";

/// @title A completely transparent, and thus interface-less, proxy contract.
contract Proxy is SlotManipulatable {

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.factory') - 1`.
    bytes32 private constant FACTORY_SLOT = bytes32(0x7a45a402e4cb6e08ebc196f20f66d5d30e67285a2a8aa80503fa409e727a4af1);

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.implementation') - 1`.
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    constructor(address factory_, address implementation_) {
        _setSlotValue(FACTORY_SLOT, bytes32(uint256(uint160(factory_))));

        // If the implementation is empty, fetch it from the factory, which can act as a beacon.
        address implementation = implementation_ == address(0) ? IDefaultImplementationBeacon(factory_).defaultImplementation() : implementation_;

        require(implementation != address(0), "P:C:INVALID_IMPLEMENTATION");

        _setSlotValue(IMPLEMENTATION_SLOT, bytes32(uint256(uint160(implementation))));
    }

    fallback() payable external virtual {
        bytes32 implementation = _getSlotValue(IMPLEMENTATION_SLOT);

        int256 size;

        assembly {
            size := extcodesize(implementation)
        }

        require(size != 0, "P:F:INVALID_IMPLEMENTATION");

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

}
