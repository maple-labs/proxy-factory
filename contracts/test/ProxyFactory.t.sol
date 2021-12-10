// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { DSTest } from "../../modules/ds-test/src/test.sol";

import { Proxy } from "../Proxy.sol";

import {
    IMockImplementationV1,
    IMockImplementationV2,
    MaliciousImplementation,
    MockFactory,
    MockImplementationV1,
    MockImplementationV2,
    MockInitializerV1,
    MockInitializerV2,
    MockMigratorV1ToV2,
    MockMigratorV1ToV2WithNoArgs,
    ProxyWithIncorrectCode
} from "./mocks/Mocks.sol";

contract ProxyFactoryTests is DSTest {

    // TODO: test_registerImplementation

    // TODO: testFail_registerImplementation_reuseVersion

    // TODO: testFail_registerImplementation_zeroImplementation

     function test_registerDuplicateImplementation() external {
        MockFactory          factory        = new MockFactory();
        MockImplementationV1 implementation = new MockImplementationV1();

        assertEq(factory.implementation(1),                  address(0));
        assertEq(factory.migratorForPath(1, 1),              address(0));
        assertEq(factory.versionOf(address(implementation)), 0);

        factory.registerImplementation(1, address(implementation));

        assertEq(factory.implementation(1),                  address(implementation));
        assertEq(factory.migratorForPath(1, 1),              address(0));
        assertEq(factory.versionOf(address(implementation)), 1);

        try factory.registerImplementation(2, address(implementation)) { assertTrue(false, "Able to register duplicate implementation"); } catch { }
    }

    function test_newInstance_withNoInitialization() external {
        MockFactory          factory        = new MockFactory();
        MockImplementationV1 implementation = new MockImplementationV1();

        factory.registerImplementation(1, address(implementation));

        assertEq(factory.implementation(1),                  address(implementation));
        assertEq(factory.migratorForPath(1, 1),              address(0));
        assertEq(factory.versionOf(address(implementation)), 1);

        IMockImplementationV1 proxy = IMockImplementationV1(factory.newInstance(1, new bytes(0)));

        assertEq(proxy.factory(),        address(factory));
        assertEq(proxy.implementation(), address(implementation));

        assertEq(proxy.alpha(),    1111);
        assertEq(proxy.beta(),     0);
        assertEq(proxy.charlie(),  0);
        assertEq(proxy.deltaOf(2), 0);

        assertEq(proxy.getLiteral(),  2222);
        assertEq(proxy.getConstant(), 1111);
        assertEq(proxy.getViewable(), 0);

        proxy.setBeta(8888);
        assertEq(proxy.beta(), 8888);


        proxy.setCharlie(3838);
        assertEq(proxy.charlie(), 3838);

        proxy.setDeltaOf(2, 2929);
        assertEq(proxy.deltaOf(2), 2929);
    }

    function test_newInstance_withNoInitializationArgs() external {
        MockFactory          factory        = new MockFactory();
        MockInitializerV1    initializer    = new MockInitializerV1();
        MockImplementationV1 implementation = new MockImplementationV1();

        factory.registerMigrator(1, 1, address(initializer));
        factory.registerImplementation(1, address(implementation));

        assertEq(factory.implementation(1),                  address(implementation));
        assertEq(factory.migratorForPath(1, 1),              address(initializer));
        assertEq(factory.versionOf(address(implementation)), 1);

        IMockImplementationV1 proxy = IMockImplementationV1(factory.newInstance(1, new bytes(0)));

        assertEq(proxy.factory(),        address(factory));
        assertEq(proxy.implementation(), address(implementation));

        assertEq(proxy.alpha(),    1111);
        assertEq(proxy.beta(),     1313);
        assertEq(proxy.charlie(),  1717);
        assertEq(proxy.deltaOf(2), 0);

        assertEq(proxy.getLiteral(),  2222);
        assertEq(proxy.getConstant(), 1111);
        assertEq(proxy.getViewable(), 1313);

        proxy.setBeta(8888);
        assertEq(proxy.beta(), 8888);


        proxy.setCharlie(3838);
        assertEq(proxy.charlie(), 3838);


        proxy.setDeltaOf(2, 2929);
        assertEq(proxy.deltaOf(2), 2929);
    }

    function test_newInstance_withInitializationArgs() external {
        MockFactory          factory        = new MockFactory();
        MockInitializerV2    initializer    = new MockInitializerV2();
        MockImplementationV2 implementation = new MockImplementationV2();

        factory.registerMigrator(2, 2, address(initializer));
        factory.registerImplementation(2, address(implementation));

        assertEq(factory.implementation(2),                  address(implementation));
        assertEq(factory.migratorForPath(2, 2),              address(initializer));
        assertEq(factory.versionOf(address(implementation)), 2);

        IMockImplementationV2 proxy = IMockImplementationV2(factory.newInstance(2, abi.encode(uint256(9090))));

        assertEq(proxy.factory(),        address(factory));
        assertEq(proxy.implementation(), address(implementation));

        assertEq(proxy.axiom(),    5555);
        assertEq(proxy.charlie(),  3434);
        assertEq(proxy.echo(),     3333);
        assertEq(proxy.derbyOf(2), 0);

        assertEq(proxy.getLiteral(),  4444);
        assertEq(proxy.getConstant(), 5555);
        assertEq(proxy.getViewable(), 3333);

        proxy.setCharlie(6969);
        assertEq(proxy.charlie(), 6969);

        proxy.setEcho(4040);
        assertEq(proxy.echo(), 4040);

        proxy.setDerbyOf(2, 6161);
        assertEq(proxy.derbyOf(2), 6161);
    }

    function testFail_newInstance_nonRegisteredImplementation() external {
        MockFactory factory = new MockFactory();
        factory.newInstance(1, new bytes(0));
    }

    // TODO: testFail_newInstance_invalidVersion

    // TODO: testFail_newInstance_invalidArguments?

    function test_newInstance_withSaltAndNoInitialization() external {
        MockFactory          factory        = new MockFactory();
        MockImplementationV1 implementation = new MockImplementationV1();

        factory.registerImplementation(1, address(implementation));

        bytes32 salt = keccak256(abi.encodePacked("salt"));

        assertEq(factory.getDeterministicProxyAddress(salt), 0x14FA484Bd9D11d9d970226a7b9FD03A5ae37Be60);
        assertEq(factory.newInstance(1, new bytes(0), salt), 0x14FA484Bd9D11d9d970226a7b9FD03A5ae37Be60);
    }

    // TODO: test_newInstanceWithSalt_withNoInitializationArgs

    // TODO: test_newInstanceWithSalt_withInitializationArgs

    // TODO: testFail_newInstanceWithSalt_nonRegisteredImplementation

    // TODO: testFail_newInstanceWithSalt_invalidVersion

    // TODO: testFail_newInstanceWithSalt_invalidArguments?

    function testFail_newInstance_withReusedSalt() external {
        MockFactory          factory        = new MockFactory();
        MockImplementationV1 implementation = new MockImplementationV1();

        bytes32 salt = keccak256(abi.encodePacked("salt"));

        factory.registerImplementation(1, address(implementation));
        factory.newInstance(1, new bytes(0), salt);
        factory.newInstance(1, new bytes(0), salt);
    }

    // TODO: test_registerMigrator_set

    // TODO: test_registerMigrator_unset

    function testFail_registerMigrator_withInvalidMigrator() external {
        (new MockFactory()).registerMigrator(1, 2, address(1));
    }

    function test_upgradeInstance_withNoMigration() external {
        MockFactory          factory          = new MockFactory();
        MockInitializerV1    initializerV1    = new MockInitializerV1();
        MockInitializerV2    initializerV2    = new MockInitializerV2();
        MockImplementationV1 implementationV1 = new MockImplementationV1();
        MockImplementationV2 implementationV2 = new MockImplementationV2();

        // Register V1, its initializer, and deploy a proxy.
        factory.registerMigrator(1, 1, address(initializerV1));
        factory.registerImplementation(1, address(implementationV1));
        address proxy = factory.newInstance(1, new bytes(0));

        // Set some values in proxy.
        IMockImplementationV1(proxy).setBeta(7575);
        IMockImplementationV1(proxy).setCharlie(1414);
        IMockImplementationV1(proxy).setDeltaOf(2,  3030);
        IMockImplementationV1(proxy).setDeltaOf(4,  9944);
        IMockImplementationV1(proxy).setDeltaOf(15, 2323);

        // Register V2, its initializer, and a migrator.
        factory.registerMigrator(2, 2, address(initializerV2));
        factory.registerImplementation(2, address(implementationV2));

        assertEq(factory.migratorForPath(1, 2), address(0));

        // Check state before migration.
        assertEq(IMockImplementationV1(proxy).implementation(),  address(implementationV1));

        assertEq(IMockImplementationV1(proxy).beta(),      7575);
        assertEq(IMockImplementationV1(proxy).charlie(),   1414);
        assertEq(IMockImplementationV1(proxy).deltaOf(2),  3030);
        assertEq(IMockImplementationV1(proxy).deltaOf(4),  9944);
        assertEq(IMockImplementationV1(proxy).deltaOf(15), 2323);

        assertEq(IMockImplementationV1(proxy).getLiteral(),  2222);
        assertEq(IMockImplementationV1(proxy).getConstant(), 1111);
        assertEq(IMockImplementationV1(proxy).getViewable(), 7575);

        // Migrate proxy from V1 to V2.
        factory.upgradeInstance(proxy, 2, new bytes(0));

        // Check if migration was successful.
        assertEq(IMockImplementationV2(proxy).implementation(),  address(implementationV2));

        assertEq(IMockImplementationV2(proxy).charlie(),   7575);  // Is old beta.
        assertEq(IMockImplementationV2(proxy).echo(),      1414);  // Is old charlie.
        assertEq(IMockImplementationV2(proxy).derbyOf(2),  3030);  // Delta was renamed to Derby, but the values remain unchanged.
        assertEq(IMockImplementationV2(proxy).derbyOf(4),  9944);  // Delta was renamed to Derby, but the values remain unchanged.
        assertEq(IMockImplementationV2(proxy).derbyOf(15), 2323);  // Delta was renamed to Derby, but the values remain unchanged.

        assertEq(IMockImplementationV2(proxy).getLiteral(),  4444);
        assertEq(IMockImplementationV2(proxy).getConstant(), 5555);
        assertEq(IMockImplementationV2(proxy).getViewable(), 1414);
    }

    function test_upgradeInstance_withMigrationArgs() external {
        MockFactory          factory          = new MockFactory();
        MockInitializerV1    initializerV1    = new MockInitializerV1();
        MockInitializerV2    initializerV2    = new MockInitializerV2();
        MockMigratorV1ToV2   migrator         = new MockMigratorV1ToV2();
        MockImplementationV1 implementationV1 = new MockImplementationV1();
        MockImplementationV2 implementationV2 = new MockImplementationV2();

        // Register V1, its initializer, and deploy a proxy.
        factory.registerMigrator(1, 1, address(initializerV1));
        factory.registerImplementation(1, address(implementationV1));
        address proxy = factory.newInstance(1, new bytes(0));

        // Set some values in proxy.
        IMockImplementationV1(proxy).setBeta(7575);
        IMockImplementationV1(proxy).setCharlie(1414);
        IMockImplementationV1(proxy).setDeltaOf(2,  3030);
        IMockImplementationV1(proxy).setDeltaOf(4,  9944);
        IMockImplementationV1(proxy).setDeltaOf(15, 2323);

        // Register V2, its initializer, and a migrator.
        factory.registerMigrator(2, 2, address(initializerV2));
        factory.registerMigrator(1, 2, address(migrator));
        factory.registerImplementation(2, address(implementationV2));

        assertEq(factory.migratorForPath(1, 2), address(migrator));

        // Check state before migration.
        assertEq(IMockImplementationV1(proxy).implementation(),  address(implementationV1));

        assertEq(IMockImplementationV1(proxy).beta(),      7575);
        assertEq(IMockImplementationV1(proxy).charlie(),   1414);
        assertEq(IMockImplementationV1(proxy).deltaOf(2),  3030);
        assertEq(IMockImplementationV1(proxy).deltaOf(4),  9944);
        assertEq(IMockImplementationV1(proxy).deltaOf(15), 2323);

        assertEq(IMockImplementationV1(proxy).getLiteral(),  2222);
        assertEq(IMockImplementationV1(proxy).getConstant(), 1111);
        assertEq(IMockImplementationV1(proxy).getViewable(), 7575);

        uint256 migrationArgument = 9090;

        // Migrate proxy from V1 to V2.
        factory.upgradeInstance(proxy, 2, abi.encode(migrationArgument));

        // Check if migration was successful.
        assertEq(IMockImplementationV2(proxy).implementation(),  address(implementationV2));

        assertEq(IMockImplementationV2(proxy).charlie(),   2828);              // Should be doubled from V1.
        assertEq(IMockImplementationV2(proxy).echo(),      3333);
        assertEq(IMockImplementationV2(proxy).derbyOf(2),  3030);              // Delta from V1 was renamed to Derby
        assertEq(IMockImplementationV2(proxy).derbyOf(4),  1188);              // Should be different due to migration case.
        assertEq(IMockImplementationV2(proxy).derbyOf(15), migrationArgument); // Should have been overwritten by migration arg.

        assertEq(IMockImplementationV2(proxy).getLiteral(),  4444);
        assertEq(IMockImplementationV2(proxy).getConstant(), 5555);
        assertEq(IMockImplementationV2(proxy).getViewable(), 3333);
    }

    function test_upgradeInstance_withNoMigrationArgs() external {
        MockFactory                  factory          = new MockFactory();
        MockInitializerV1            initializerV1    = new MockInitializerV1();
        MockInitializerV2            initializerV2    = new MockInitializerV2();
        MockMigratorV1ToV2WithNoArgs migrator         = new MockMigratorV1ToV2WithNoArgs();
        MockImplementationV1         implementationV1 = new MockImplementationV1();
        MockImplementationV2         implementationV2 = new MockImplementationV2();

        // Register V1, its initializer, and deploy a proxy.
        factory.registerMigrator(1, 1, address(initializerV1));
        factory.registerImplementation(1, address(implementationV1));
        address proxy = factory.newInstance(1, new bytes(0));

        // Set some values in proxy.
        IMockImplementationV1(proxy).setBeta(7575);
        IMockImplementationV1(proxy).setCharlie(1414);
        IMockImplementationV1(proxy).setDeltaOf(2,  3030);
        IMockImplementationV1(proxy).setDeltaOf(4,  9944);
        IMockImplementationV1(proxy).setDeltaOf(15, 2323);

        // Register V2, its initializer, and a migrator.
        factory.registerMigrator(2, 2, address(initializerV2));
        factory.registerMigrator(1, 2, address(migrator));
        factory.registerImplementation(2, address(implementationV2));

        assertEq(factory.migratorForPath(1, 2), address(migrator));

        // Check state before migration.
        assertEq(IMockImplementationV1(proxy).implementation(),  address(implementationV1));

        assertEq(IMockImplementationV1(proxy).beta(),      7575);
        assertEq(IMockImplementationV1(proxy).charlie(),   1414);
        assertEq(IMockImplementationV1(proxy).deltaOf(2),  3030);
        assertEq(IMockImplementationV1(proxy).deltaOf(4),  9944);
        assertEq(IMockImplementationV1(proxy).deltaOf(15), 2323);

        assertEq(IMockImplementationV1(proxy).getLiteral(),  2222);
        assertEq(IMockImplementationV1(proxy).getConstant(), 1111);
        assertEq(IMockImplementationV1(proxy).getViewable(), 7575);

        // Migrate proxy from V1 to V2.
        factory.upgradeInstance(proxy, 2, new bytes(0));

        // Check if migration was successful.
        assertEq(IMockImplementationV2(proxy).implementation(),  address(implementationV2));

        assertEq(IMockImplementationV2(proxy).charlie(),   2828);  // Should be doubled from V1.
        assertEq(IMockImplementationV2(proxy).echo(),      3333);
        assertEq(IMockImplementationV2(proxy).derbyOf(2),  3030);  // Delta from V1 was renamed to Derby
        assertEq(IMockImplementationV2(proxy).derbyOf(4),  1188);  // Should be different due to migration case.
        assertEq(IMockImplementationV2(proxy).derbyOf(15), 15);

        assertEq(IMockImplementationV2(proxy).getLiteral(),  4444);
        assertEq(IMockImplementationV2(proxy).getConstant(), 5555);
        assertEq(IMockImplementationV2(proxy).getViewable(), 3333);
    }

    function testFail_upgradeInstance_nonRegisteredImplementation() external {
        MockFactory          factory          = new MockFactory();
        MockInitializerV1    initializerV1    = new MockInitializerV1();
        MockImplementationV1 implementationV1 = new MockImplementationV1();

        // Register V1, its initializer, and deploy a proxy.
        factory.registerMigrator(1, 1, address(initializerV1));
        factory.registerImplementation(1, address(implementationV1));
        address proxy = factory.newInstance(1, new bytes(0));

        // Migrate proxy from V1 to V2.
        factory.upgradeInstance(proxy, 2, new bytes(0));
    }

    // TODO: testFail_upgradeInstance_invalidVersion

    // TODO: testFail_upgradeInstance_proxyHasInvalidImplementation

    // TODO: testFail_upgradeInstance_invalidArguments?

    function test_composability() external {
        MockFactory          factory        = new MockFactory();
        MockInitializerV1    initializer    = new MockInitializerV1();
        MockImplementationV1 implementation = new MockImplementationV1();

        factory.registerMigrator(1, 1, address(initializer));
        factory.registerImplementation(1, address(implementation));

        IMockImplementationV1 proxy1 = IMockImplementationV1(factory.newInstance(1, new bytes(0)));
        address proxy2               = factory.newInstance(1, new bytes(0));

        // Change proxy2 values.
        IMockImplementationV1(proxy2).setBeta(5959);

        assertEq(proxy1.getAnotherBeta(proxy2), 5959);

        proxy1.setAnotherBeta(proxy2, 8888);
        assertEq(proxy1.getAnotherBeta(proxy2), 8888);

        // Ensure proxy1 values have remained as default.
        assertEq(proxy1.alpha(),     1111);
        assertEq(proxy1.beta(),      1313);
        assertEq(proxy1.charlie(),   1717);
        assertEq(proxy1.deltaOf(2),  0);
        assertEq(proxy1.deltaOf(15), 4747);

        assertEq(proxy1.getLiteral(),  2222);
        assertEq(proxy1.getConstant(), 1111);
        assertEq(proxy1.getViewable(), 1313);
    }

    function test_failureWithNonContract() external {
        MockFactory             factory        = new MockFactory();
        MaliciousImplementation implementation = new MaliciousImplementation();

        // Registering malicious implementation
        factory.registerImplementation(1, address(implementation));

        assertEq(factory.implementation(1),                  address(implementation));
        assertEq(factory.migratorForPath(1, 1),              address(0));
        assertEq(factory.versionOf(address(implementation)), 1);

        IMockImplementationV1 proxy = IMockImplementationV1(factory.newInstance(1, new bytes(0)));

        try proxy.alpha() { assertTrue(false, "Proxy didn't revert"); } catch { } 
    }

}
