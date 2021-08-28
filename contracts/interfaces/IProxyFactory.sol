// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IProxyFactory {

    function implementation(uint256) external view returns (address);

    function implementationFor(address) external view returns (address);

    function initializerFor(uint256) external view returns (address);

    function migratorForPath(bytes32) external view returns (address);

    function versionOf(address) external view returns (uint256);

    function recommendedVersion() external view returns (uint256);

    function registerImplementation(uint256 version, address implementationAddress, address initializer) external;

    function setRecommendedVersion(uint256 version) external;

    function newInstance(uint256 version, bytes calldata initializationArguments) external returns (address proxy);

    function getImplementation() external view returns (address);

    function setMigrationPath(uint256 oldVersion, uint256 newVersion, address migrator) external;

    function upgradeImplementationFor(address proxy, uint256 oldVersion, uint256 newVersion, bytes calldata migrationArguments) external;

}
