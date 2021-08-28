// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IProxied {

    function factory() external view returns (address);

    function implementation() external view returns (address);

    function initialize(address initializer, bytes calldata initializationArguments) external;

    function migrate(address migrator, bytes calldata migrationArguments) external;

}
