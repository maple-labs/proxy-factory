// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IProxyFactory {

    /// @notice A version of an implementation, at some address, was registered.
    event ImplementationRegister(uint256 indexed version, address indexed implementationAddress, address indexed initializer);

    /// @notice A version was recommended.
    event RecommendedVersionSet(uint256 indexed version);

    /// @notice A proxy of an implementation version was deployed with some initialization arguments.
    event InstanceDeployed(uint256 indexed version, address indexed proxy, bytes initializationArguments);

    /// @notice A migration path, and thus a migrator contract, has been set between two versions.
    event MigrationPathSet(uint256 indexed fromVersion, uint256 indexed toVersion, address indexed migrator);

    /// @notice A proxy has been upgrade from an implementation version implementation version, with some migration arguments.
    event InstanceUpgrade(address indexed proxy, uint256 indexed fromVersion, uint256 indexed toVersion, bytes migrationArguments);

    /// @notice Returns the address of the implementation of a version.
    function implementation(uint256) external view returns (address);

    /// @notice Returns the address of the implementation of a proxy instance.
    function implementationFor(address) external view returns (address);

    /// @notice Returns the address of the initialization contract of a version of an implementation.
    function initializerFor(uint256) external view returns (address);

    /// @notice Returns the address of the migration contract for a migration path.
    function migratorForPath(bytes32) external view returns (address);

    /// @notice Returns the version of an implementation address.
    function versionOf(address) external view returns (uint256);

    /// @notice Returns the recommended version of the implementation.
    function recommendedVersion() external view returns (uint256);

    /// @notice Registers the addresses of a version of an implementation contract, and its initializer contract.
    function registerImplementation(uint256 version, address implementationAddress, address initializer) external;

    /// @notice Sets the recommended version of the implementation.
    function setRecommendedVersion(uint256 version) external;

    /// @notice Deploys a new instance of a proxy, for a version of the implementation, with some initialization arguments.
    function newInstance(uint256 version, bytes calldata initializationArguments) external returns (address proxy);

    /// @notice Deploys a new instance of a proxy, for the recommended version of the implementation, with some initialization arguments.
    function newInstance(bytes calldata initializationArguments) external returns (address proxy);

    /// @notice Returns the implementation contract address of the caller, assumed to be a proxy instance.
    function getImplementation() external view returns (address);

    /// @notice Sets the migrator used to allow upgrading and migrations from a version to another version.
    function setMigrationPath(uint256 fromVersion, uint256 toVersion, address migrator) external;

    /// @notice Returns the migrator used in upgrading and migrating from a version to another version.
    function getMigrator(uint256 fromVersion, uint256 toVersion) external view returns (address proxy);

    /// @notice Upgrades and migrates a proxy instance to a version, with some migration arguments.
    function upgradeImplementationFor(address proxy, uint256 toVersion, bytes calldata migrationArguments) external;

}
