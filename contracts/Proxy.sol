// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IProxy } from "./interfaces/IProxy.sol";
import { IProxyFactory } from "./interfaces/IProxyFactory.sol";

contract Proxy is IProxy {

    // IMPORTANT: `address public factory` must be first defined state variable
    address internal factory;

    constructor() payable {
        factory = msg.sender;
    }

    function _implementation() internal view returns (address) {
        return IProxyFactory(factory).getImplementation();
    }
    
    function implementation() external override view returns (address) {
        return _implementation();
    }

    function _fallback() internal {
        address implementationAddress = _implementation();

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

    fallback() payable external {
        _fallback();
    }

    receive() payable external {
        _fallback();
    }

}
