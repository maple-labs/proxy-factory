// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title An beacon that provides a default implementation for proxies, must implement IDefaultImplementationBeacon.
interface IDefaultImplementationBeacon {

    /**
     *  @notice The address of an implementation for proxies.
     */
    function defaultImplementation() external view returns (address defaultImplementation_);

}
