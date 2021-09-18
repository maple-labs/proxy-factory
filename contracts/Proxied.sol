// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IProxied } from "./interfaces/IProxied.sol";

import { SlotManipulatable } from "./SlotManipulatable.sol";

/// @title A proxied implementation must be Proxied.
contract Proxied is IProxied, SlotManipulatable {

    /// @dev Storage slot with the address of the current factory. This is the keccak-256 hash of "FACTORY_SLOT".
    bytes32 private constant FACTORY_SLOT = 0xf2db84db8157f5a01a257d644038e8929d5a62c9ffa8b736374913908897e5bb;

    /// @dev Storage slot with the address of the current factory. This is the keccak-256 hash of "IMPLEMENTATION_SLOT".
    bytes32 private constant IMPLEMENTATION_SLOT = 0xf603533e14e17222e047634a2b3457fe346d27e294cedf9d21d74e5feea4a046;

    /********************************/
    /*** State-Changing Functions ***/
    /********************************/

    function migrate(address migrator_, bytes calldata arguments_) external override {
        require(msg.sender == factory(),         "P:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "P:M:MIGRATION_FAILED");
    }

    function setImplementation(address newImplementation_) external virtual override {
        require(msg.sender == factory(), "P:U:NOT_FACTORY");
        _setImplementation(newImplementation_);
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _migrate(address migrator_, bytes calldata arguments_) internal virtual returns (bool success_) {
        ( success_, ) = migrator_.delegatecall(arguments_);
    }

    function _setImplementation(address newImplementation_) internal virtual {
        _setSlotValue(IMPLEMENTATION_SLOT, bytes32(uint256(uint160(newImplementation_))));
    }

    /************************/
    /*** Getter Functions ***/
    /************************/

    function factory() public view override returns (address factory_) {
        return address(uint160(uint256(_getSlotValue(FACTORY_SLOT))));
    }

    function implementation() public view override returns (address implementation_) {
        return address(uint160(uint256(_getSlotValue(IMPLEMENTATION_SLOT))));
    }

}
