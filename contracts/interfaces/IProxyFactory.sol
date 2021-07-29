// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IProxyFactory {

  function implementationHash(uint256) external view returns (bytes32);

  function implementation(uint256) external view returns (address);

  function implementationFor(address) external view returns (address);

  function latestVersion() external view returns (uint256);

  function latestImplementation() external view returns (uint256);

  function upgradePath(uint256) external view returns (uint256);

  function registerVersion(uint256 version, bytes32 codeHash) external;

  function registerImplementation(uint256 version, address implementationAddress) external;

  function setUpgradePath(uint256 oldVersion, uint256 newVersion) external;

  function newInstance() external returns (address proxy);

  function getImplementation() external view returns (address imp);

  function updateImplementationFor(address proxy, uint256 oldVersion) external;

}
