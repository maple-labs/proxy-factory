// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title An factory that acts as a beacon for proxies, must implement IProxyBeacon.
interface IProxyBeacon {

    /**
     *  @notice The address of an implementation for proxies.
     */
    function instanceImplementation() external view returns (address instanceImplementation_);

}
