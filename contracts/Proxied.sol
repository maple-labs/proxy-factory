// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IProxied }      from "./interfaces/IProxied.sol";
import { IProxyFactory } from "./interfaces/IProxyFactory.sol";

import { SlotManipulatable } from "./SlotManipulatable.sol";

contract Proxied is IProxied, SlotManipulatable {

    bytes32 private constant FACTORY_SLOT = 0xf2db84db8157f5a01a257d644038e8929d5a62c9ffa8b736374913908897e5bb;

    function _initialize(address initializer, bytes calldata initializationArguments) internal {
        (bool success,) = initializer.delegatecall(initializationArguments);
        require(success, "P:I:INITIALIZE_FAILED");
    }

    function _migrate(address migrator, bytes calldata migrationArguments) internal {
        (bool success,) = migrator.delegatecall(migrationArguments);
        require(success, "P:M:MIGRATION_FAILED");
    }

    function factory() public view override returns (address _factory) {
        return address(uint160(uint256(_getSlotValue(FACTORY_SLOT))));
    }

    function implementation() external view override returns (address) {
        return IProxyFactory(factory()).getImplementation();
    }

    function initialize(address initializer, bytes calldata initializationArguments) external virtual override {
        require(msg.sender == factory(), "P:I:NOT_FACTORY");
        _initialize(initializer, initializationArguments);
    }

    function migrate(address migrator, bytes calldata migrationArguments) external override {
        require(msg.sender == factory(), "P:M:NOT_FACTORY");
        _migrate(migrator, migrationArguments);
    }

}
