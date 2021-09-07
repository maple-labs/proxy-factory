// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IReturnsCallerImplementation } from "./interfaces/IReturnsCallerImplementation.sol";

contract Proxy {

    /// @dev Storage slot with the address of the current factory. This is the keccak-256 hash of "FACTORY_SLOT".
    bytes32 private constant FACTORY_SLOT = 0xf2db84db8157f5a01a257d644038e8929d5a62c9ffa8b736374913908897e5bb;

    constructor(address factory) payable {
        bytes32 slot = FACTORY_SLOT;

        assembly {
            sstore(slot, factory)
        }
    }

    function _fallback() private {
        bytes32 slot = FACTORY_SLOT;

        address factory;

        assembly {
            factory := sload(slot)
        }

        address implementationAddress = IReturnsCallerImplementation(factory).getImplementation();

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementationAddress, 0, calldatasize(), 0, 0)

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

    receive() payable external virtual {
        _fallback();
    }

}
