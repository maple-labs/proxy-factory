// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IReturnsCallerImplementation {

    /// @dev Returns the implementation contract address of the caller, assumed to be a proxy instance.
    function getImplementation() external view returns (address);

}
