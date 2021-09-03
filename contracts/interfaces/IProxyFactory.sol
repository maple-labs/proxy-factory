// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IProxyFactory {

    /// @dev A version of an implementation, at some address, was registered.
    event ImplementationRegister(uint256 indexed version, address indexed implementationAddress);

    /// @dev A proxy of an implementation version was deployed with some initialization arguments.
    event InstanceDeployed(uint256 indexed version, address indexed proxy, bytes initializationArguments);

    /// @dev A migration path, and thus a migrator contract, has been set between two versions.
    event MigrationPathSet(uint256 indexed fromVersion, uint256 indexed toVersion, address indexed migrator);

    /// @dev A proxy has been upgrade from an implementation version implementation version, with some migration arguments.
    event InstanceUpgrade(address indexed proxy, uint256 indexed fromVersion, uint256 indexed toVersion, bytes migrationArguments);

    /// @dev Returns the address of the implementation of a version.
    function implementation(uint256) external view returns (address);

    /// @dev Returns the address of the implementation of a proxy instance.
    function implementationFor(address) external view returns (address);

    /// @dev Returns the address of the migration contract for a migration path (from version, to version).
    function migratorForPath(uint256, uint256) external view returns (address);

    /// @dev Returns the version of an implementation address.
    function versionOf(address) external view returns (uint256);

    /// @dev Set the addresses of a version of an implementation contract.
    function registerImplementation(uint256 version, address implementationAddress) external;

    /// @dev Deploys a new instance of a proxy, for a version of the implementation, with some initialization arguments.
    function newInstance(uint256 version, bytes calldata initializationArguments) external returns (address proxy);

    /// @dev Returns the implementation contract address of the caller, assumed to be a proxy instance.
    function getImplementation() external view returns (address);

    /// @dev Sets the migrator used to allow upgrading and migrations from a version to another version.
    function registerMigrationPath(uint256 fromVersion, uint256 toVersion, address migrator) external;

    /// @dev Upgrades and migrates a proxy instance to a version, with some migration arguments.
    function upgradeImplementationFor(address proxy, uint256 toVersion, bytes calldata migrationArguments) external;

}
