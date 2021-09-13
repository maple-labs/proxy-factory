// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title A proxied implementation must be Proxied.
interface IProxied {

    /// @notice Returns the address of the proxy factory.
    function factory() external view returns (address factory_);

    /// @notice Returns the address of the implementation contract.
    function implementation() external view returns (address implementation_);

    /// @notice Modifies the proxy's implementation address.
    function setImplementation(address newImplementation_) external;

    /// @notice Modifies the proxy's storage by delegate-calling a migrator contract with some arguments.
    function migrate(address migrator_, bytes calldata arguments_) external;

}
