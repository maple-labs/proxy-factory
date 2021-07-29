// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IProxy {

  function implementation() external view returns (address);

}
