// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { DSTest } from "../../modules/ds-test/src/test.sol";

import {
    IMockInitializerV1,
    IMockInitializerV2,
    MockFactory,
    MockImplementationV1,
    MockImplementationV2,
    MockInitializerV1,
    MockInitializerV2,
    MockMigratorV1ToV2,
    MockMigratorV1ToV2WithNoArgs
} from "./mocks/Mocks.sol";

contract Test is DSTest {

    function test_newInstance_withNoInitialization() external {
        MockFactory          factory        = new MockFactory();
        MockImplementationV1 implementation = new MockImplementationV1();

        factory.registerImplementation(1, address(implementation));

        assertEq(factory.implementation(1),                  address(implementation));
        assertEq(factory.migratorForPath(1, 1),              address(0));
        assertEq(factory.versionOf(address(implementation)), 1);

        IMockInitializerV1 proxy = IMockInitializerV1(factory.newInstance(1, new bytes(0)));

        assertEq(proxy.factory(),        address(factory));
        assertEq(proxy.implementation(), address(implementation));

        // No change made in storage
        assertEq(proxy.storageVariable(), 0);

        // Performing mutating functions on proxy
        proxy.setStorageVariable(8888);
        assertEq(proxy.storageVariable(), 8888);
    }

    function test_newInstance_withNoInitializationArgs() external {
        MockFactory          factory        = new MockFactory();
        MockInitializerV1    initializer    = new MockInitializerV1();
        MockImplementationV1 implementation = new MockImplementationV1();

        factory.registerMigrationPath(1, 1, address(initializer));
        factory.registerImplementation(1, address(implementation));

        assertEq(factory.implementation(1),                  address(implementation));
        assertEq(factory.migratorForPath(1, 1),              address(initializer));
        assertEq(factory.versionOf(address(implementation)), 1);

        IMockInitializerV1 proxy = IMockInitializerV1(factory.newInstance(1, new bytes(0)));

        assertEq(proxy.factory(),        address(factory));
        assertEq(proxy.implementation(), address(implementation));

        // storageVariable is set to default value defined in MockInitializerV1
        assertEq(proxy.storageVariable(), 1313);

        proxy.setStorageVariable(8888);
        assertEq(proxy.storageVariable(), 8888);
    }

    function test_newInstance_withInitializationArgs() external {
        MockFactory          factory        = new MockFactory();
        MockInitializerV2    initializer    = new MockInitializerV2();
        MockImplementationV2 implementation = new MockImplementationV2();

        factory.registerMigrationPath(2, 2, address(initializer));
        factory.registerImplementation(2, address(implementation));

        assertEq(factory.implementation(2),                  address(implementation));
        assertEq(factory.migratorForPath(2, 2),              address(initializer));
        assertEq(factory.versionOf(address(implementation)), 2);

        // Create a new instance passing an argument
        IMockInitializerV2 proxy = IMockInitializerV2(factory.newInstance(2, abi.encode(uint256(9090))));

        assertEq(proxy.factory(),        address(factory));
        assertEq(proxy.implementation(), address(implementation));

        // Storage has the value passed to initializer
        assertEq(proxy.storageVariable(), 9090);
    }

    function test_upgradeability_withNoMigration() external {
        MockFactory          factory          = new MockFactory();
        MockInitializerV1    initializerV1    = new MockInitializerV1();
        MockInitializerV2    initializerV2    = new MockInitializerV2();
        MockImplementationV1 implementationV1 = new MockImplementationV1();
        MockImplementationV2 implementationV2 = new MockImplementationV2();

        // Register V1, its initializer, and deploy a proxy.
        factory.registerMigrationPath(1, 1, address(initializerV1));
        factory.registerImplementation(1, address(implementationV1));
        address proxy = factory.newInstance(1, new bytes(0));

        // storageVariable is set to default value defined in MockInitializerV1
        assertEq(MockImplementationV1(proxy).storageVariable(), 1313);

        // Register V2, its initializer, and a migrator.
        factory.registerMigrationPath(2, 2, address(initializerV2));
        factory.registerImplementation(2, address(implementationV2));

        assertEq(factory.migratorForPath(1, 2), address(0));

        // Migrate proxy from V1 to V2.
        factory.upgradeInstance(proxy, 2, new bytes(0));

        // Check if migration was successful.
        assertEq(IMockInitializerV2(proxy).implementation(),  address(implementationV2));

        // SetStorageVariable is no longer available in V2
        try MockImplementationV1(proxy).setStorageVariable(7777) {

            // Trying to call `setStorageVariable` will cause a revert
            assert(false);
        } catch {

            //Storage remained the same
            assertEq(MockImplementationV1(proxy).storageVariable(), 1313);
            assert(true);   
        }

        // Use new functionality available in V2
        MockImplementationV2(proxy).incrementStorageVariable();

        assertEq(MockImplementationV2(proxy).storageVariable(), 1314);
    }

    function test_upgradeability_withNoMigrationArgs() external {
        MockFactory                  factory          = new MockFactory();
        MockInitializerV1            initializerV1    = new MockInitializerV1();
        MockInitializerV2            initializerV2    = new MockInitializerV2();
        MockMigratorV1ToV2WithNoArgs migrator         = new MockMigratorV1ToV2WithNoArgs();
        MockImplementationV1         implementationV1 = new MockImplementationV1();
        MockImplementationV2         implementationV2 = new MockImplementationV2();

        // Register V1, its initializer, and deploy a proxy.
        factory.registerMigrationPath(1, 1, address(initializerV1));
        factory.registerImplementation(1, address(implementationV1));
        address proxy = factory.newInstance(1, new bytes(0));

        // storageVariable is set to default value defined in MockInitializerV1
        assertEq(MockImplementationV1(proxy).storageVariable(), 1313);

        // Set it to a different value
        MockImplementationV1(proxy).setStorageVariable(2222);

        // Register V2, its initializer, and a migrator.
        factory.registerMigrationPath(2, 2, address(initializerV2));
        factory.registerMigrationPath(1, 2, address(migrator));
        factory.registerImplementation(2, address(implementationV2));

        assertEq(factory.migratorForPath(1, 2), address(migrator));

        // Migrate proxy from V1 to V2.
        factory.upgradeInstance(proxy, 2, new bytes(0));

        // Check if migration was successful.
        assertEq(IMockInitializerV2(proxy).implementation(),  address(implementationV2));

        // storageVariable has modified to the migrator's default value
        assertEq(MockImplementationV2(proxy).storageVariable(), 1111);
    }

    function test_upgradeability_withMigrationArgs() external {
        MockFactory          factory          = new MockFactory();
        MockInitializerV1    initializerV1    = new MockInitializerV1();
        MockInitializerV2    initializerV2    = new MockInitializerV2();
        MockMigratorV1ToV2   migrator         = new MockMigratorV1ToV2();
        MockImplementationV1 implementationV1 = new MockImplementationV1();
        MockImplementationV2 implementationV2 = new MockImplementationV2();

        // Register V1, its initializer, and deploy a proxy.
        factory.registerMigrationPath(1, 1, address(initializerV1));
        factory.registerImplementation(1, address(implementationV1));
        address proxy = factory.newInstance(1, new bytes(0));
        
        // storageVariable is set to valuepassed to constructor
        assertEq(MockImplementationV1(proxy).storageVariable(), 1313);

        // Register V2, its initializer, and a migrator.
        factory.registerMigrationPath(2, 2, address(initializerV2));
        factory.registerMigrationPath(1, 2, address(migrator));
        factory.registerImplementation(2, address(implementationV2));

        assertEq(factory.migratorForPath(1, 2), address(migrator));

        // Migrate proxy from V1 to V2.
        factory.upgradeInstance(proxy, 2, abi.encode(uint256(9090)));

        // Check if migration was successful.
        assertEq(IMockInitializerV2(proxy).implementation(),  address(implementationV2));


        // storageVariable was upgraded during migration
        assertEq(MockImplementationV2(proxy).storageVariable(), 9090);

        // using v2 functionality
        MockImplementationV2(proxy).incrementStorageVariable();

        assertEq(MockImplementationV2(proxy).storageVariable(), 9091);
    }

    function test_independenceBetweenInstances() external {
        MockFactory          factory          = new MockFactory();
        MockInitializerV1    initializerV1    = new MockInitializerV1();
        MockInitializerV2    initializerV2    = new MockInitializerV2();
        MockImplementationV1 implementationV1 = new MockImplementationV1();
        MockImplementationV2 implementationV2 = new MockImplementationV2();

        factory.registerMigrationPath(1, 1, address(initializerV1));
        factory.registerImplementation(1, address(implementationV1));

        MockImplementationV1 proxy1 = MockImplementationV1(factory.newInstance(1, new bytes(0)));
        MockImplementationV1 proxy2 = MockImplementationV1(factory.newInstance(1, new bytes(0)));

        // Both instances start in the same state
        assertEq(proxy1.factory(),         address(factory));
        assertEq(proxy1.implementation(),  address(implementationV1));
        assertEq(proxy1.storageVariable(), 1313);

        assertEq(proxy2.factory(),         address(factory));
        assertEq(proxy2.implementation(),  address(implementationV1));
        assertEq(proxy2.storageVariable(), 1313);

        // Changing only one of the instances
        proxy1.setStorageVariable(8888);

        // Ensure only one was modified
        assertEq(proxy1.storageVariable(), 8888);
        assertEq(proxy2.storageVariable(), 1313);

        // Register V2, its initializer, and a migrator.
        factory.registerMigrationPath(2, 2, address(initializerV2));
        factory.registerImplementation(2, address(implementationV2));

        assertEq(factory.migratorForPath(1, 2), address(0));

        // Migrate only one instance
        factory.upgradeInstance(address(proxy2), 2, new bytes(0));

        // Check if migration was successful.
        assertEq(MockImplementationV2(address(proxy2)).implementation(),  address(implementationV2));
        assertEq(proxy1.implementation(),                                 address(implementationV1));
    }

    function test_newInstanceWithSalt() external {
        MockFactory          factory        = new MockFactory();
        MockImplementationV1 implementation = new MockImplementationV1();

        factory.registerImplementation(1, address(implementation));

        address proxy = factory.newInstanceWithSalt(1, new bytes(0), "salt");

        assertEq(proxy, 0x6FD86f82E0D16465c7c9898971A545B83d43a9e0);
    }
     
    function testFail_newInstanceWithSalt() external {
        MockFactory          factory        = new MockFactory();
        MockImplementationV1 implementation = new MockImplementationV1();

        factory.registerImplementation(1, address(implementation));
        factory.newInstanceWithSalt(1, new bytes(0), "salt");
        factory.newInstanceWithSalt(1, new bytes(0), "salt");
    }

    function testFail_newInstance_nonRegisteredImplementation() external {
        MockFactory factory = new MockFactory();

        address proxy = factory.newInstance(1, new bytes(0));
    }

    function testFail_upgrade_nonRegisteredImplementation() external {
        MockFactory          factory          = new MockFactory();
        MockInitializerV1    initializerV1    = new MockInitializerV1();
        MockImplementationV1 implementationV1 = new MockImplementationV1();

        // Register V1, its initializer, and deploy a proxy.
        factory.registerMigrationPath(1, 1, address(initializerV1));
        factory.registerImplementation(1, address(implementationV1));
        address proxy = factory.newInstance(1, new bytes(0));

        // Migrate proxy from V1 to V2.
        factory.upgradeInstance(proxy, 2, new bytes(0));
    }
    
}
