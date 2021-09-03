// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IProxyFactory } from "../../interfaces/IProxyFactory.sol";

contract ProxyFactoryUser {

    /************************/
    /*** Direct Functions ***/
    /************************/

    function proxyFactory_registerImplementation(address factory, uint256 version, address implementationAddress) external {
        IProxyFactory(factory).registerImplementation(version, implementationAddress);
    }

    function proxyFactory_newInstance(address factory, uint256 version, bytes calldata initializationArguments) external {
        IProxyFactory(factory).newInstance(version, initializationArguments);
    }

    function proxyFactory_registerMigrationPath(address factory, uint256 fromVersion, uint256 toVersion, address migrator) external {
        IProxyFactory(factory).registerMigrationPath(fromVersion, toVersion, migrator);
    }

    function proxyFactory_upgradeInstance(address factory, address proxy, uint256 toVersion, bytes calldata migrationArguments) external {
        IProxyFactory(factory).upgradeInstance(proxy, toVersion, migrationArguments);
    }

    /*********************/
    /*** Try Functions ***/
    /*********************/

    function try_proxyFactory_registerImplementation(address factory, uint256 version, address implementationAddress) external returns (bool ok) {
        (ok,) = factory.call(abi.encodeWithSelector(IProxyFactory.registerImplementation.selector, version, implementationAddress));
    }

    function try_proxyFactory_newInstance(address factory, uint256 version, bytes calldata initializationArguments) external returns (bool ok) {
        (ok,) = factory.call(abi.encodeWithSelector(IProxyFactory.newInstance.selector, version, initializationArguments));
    }

    function try_proxyFactory_registerMigrationPath(
        address factory,
        uint256 fromVersion,
        uint256 toVersion,
        address migrator
    ) external returns (bool ok) {
        (ok,) = factory.call(abi.encodeWithSelector(IProxyFactory.registerMigrationPath.selector, fromVersion, toVersion, migrator));
    }

    function try_proxyFactory_upgradeInstance(
        address factory,
        address proxy,
        uint256 toVersion,
        bytes calldata migrationArguments
    ) external returns (bool ok) {
        (ok,) = factory.call(abi.encodeWithSelector(IProxyFactory.upgradeInstance.selector, proxy, toVersion, migrationArguments));
    }

}
