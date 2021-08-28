// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IProxied {

    /// @notice Returns the address of the proxy factory.
    function factory() external view returns (address);

    /// @notice Returns the address of the implementation contract.
    function implementation() external view returns (address);

    /// @notice Initializes the proxy's storage by delegatecalling an initializer contract with some initialization arguments.
    function initialize(address initializer, bytes calldata initializationArguments) external;

    /// @notice Migrates the proxy's storage by delegatecalling a migrator contract with some migration arguments.
    function migrate(address migrator, bytes calldata migrationArguments) external;

}
