// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IProxied }                     from "./interfaces/IProxied.sol";
import { IReturnsCallerImplementation } from "./interfaces/IReturnsCallerImplementation.sol";

import { SlotManipulatable } from "./SlotManipulatable.sol";

contract Proxied is IProxied, SlotManipulatable {

    bytes32 private constant FACTORY_SLOT = 0xf2db84db8157f5a01a257d644038e8929d5a62c9ffa8b736374913908897e5bb;

    function factory() public view override returns (address _factory) {
        return address(uint160(uint256(_getSlotValue(FACTORY_SLOT))));
    }

    function implementation() external view override returns (address) {
        return IReturnsCallerImplementation(factory()).getImplementation();
    }

    function migrate(address migrator, bytes calldata arguments) external virtual override {
        require(msg.sender == factory(), "P:M:NOT_FACTORY");
        require(_migrate(migrator, arguments), "P:M:MIGRATION_FAILED");
    }

    function _migrate(address migrator, bytes calldata arguments) internal returns (bool success) {
        (success,) = migrator.delegatecall(arguments);
    }

}
