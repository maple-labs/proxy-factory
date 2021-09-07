// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title A proxied implementation must be Proxied.
interface IProxied {

    /// @notice Returns the address of the proxy factory.
    function factory() external view returns (address);

    /// @notice Returns the address of the implementation contract.
    function implementation() external view returns (address);

    /// @notice Modifies the proxy's implementation address.
    function setImplementation(address newImplementation) external;

    /// @notice Modifies the proxy's storage by delegate-calling a migrator contract with some arguments.
    function migrate(address migrator, bytes calldata arguments) external;

}
