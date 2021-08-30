// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IProxied {

    /// @notice Returns the address of the proxy factory.
    function factory() external view returns (address);

    /// @notice Returns the address of the implementation contract.
    function implementation() external view returns (address);

    /// @notice Modifies the proxy's storage by delegatecalling a migrator contract with some arguments.
    function migrate(address migrator, bytes calldata arguments) external;

}
