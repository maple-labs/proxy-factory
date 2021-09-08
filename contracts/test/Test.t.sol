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

        assertEq(proxy.alpha(),     1111);
        assertEq(proxy.beta(),      0);
        assertEq(proxy.charlie(),   0);
        assertEq(proxy.deltaOf(2),  0);
        assertEq(proxy.deltaOf(15), 0);

        assertEq(proxy.getLiteral(),  2222);
        assertEq(proxy.getConstant(), 1111);
        assertEq(proxy.getViewable(), 0);

        proxy.setBeta(8888);
        assertEq(proxy.beta(),                        8888);
        assertEq(proxy.setBetaAndReturnOldBeta(9999), 8888);
        assertEq(proxy.beta(),                        9999);

        proxy.setCharlie(3838);
        assertEq(proxy.charlie(),                           3838);
        assertEq(proxy.setCharlieAndReturnOldCharlie(8383), 3838);
        assertEq(proxy.charlie(),                           8383);

        proxy.setDeltaOf(2, 2929);
        assertEq(proxy.deltaOf(2),                             2929);
        assertEq(proxy.setDeltaOfAndReturnOldDeltaOf(2, 9292), 2929);
        assertEq(proxy.deltaOf(2),                             9292);

        proxy.setDeltaOf(15, 6464);
        assertEq(proxy.deltaOf(15),                             6464);
        assertEq(proxy.setDeltaOfAndReturnOldDeltaOf(15, 7474), 6464);
        assertEq(proxy.deltaOf(15),                             7474);
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

        assertEq(proxy.alpha(),     1111);
        assertEq(proxy.beta(),      1313);
        assertEq(proxy.charlie(),   1717);
        assertEq(proxy.deltaOf(2),  0);
        assertEq(proxy.deltaOf(15), 4747);

        assertEq(proxy.getLiteral(),  2222);
        assertEq(proxy.getConstant(), 1111);
        assertEq(proxy.getViewable(), 1313);

        proxy.setBeta(8888);
        assertEq(proxy.beta(),                        8888);
        assertEq(proxy.setBetaAndReturnOldBeta(9999), 8888);
        assertEq(proxy.beta(),                        9999);

        proxy.setCharlie(3838);
        assertEq(proxy.charlie(),                           3838);
        assertEq(proxy.setCharlieAndReturnOldCharlie(8383), 3838);
        assertEq(proxy.charlie(),                           8383);

        proxy.setDeltaOf(2, 2929);
        assertEq(proxy.deltaOf(2),                             2929);
        assertEq(proxy.setDeltaOfAndReturnOldDeltaOf(2, 9292), 2929);
        assertEq(proxy.deltaOf(2),                             9292);

        proxy.setDeltaOf(15, 6464);
        assertEq(proxy.deltaOf(15),                             6464);
        assertEq(proxy.setDeltaOfAndReturnOldDeltaOf(15, 7474), 6464);
        assertEq(proxy.deltaOf(15),                             7474);
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

        IMockInitializerV2 proxy = IMockInitializerV2(factory.newInstance(2, abi.encode(uint256(9090))));

        assertEq(proxy.factory(),        address(factory));
        assertEq(proxy.implementation(), address(implementation));

        assertEq(proxy.axiom(),     5555);
        assertEq(proxy.charlie(),   3434);
        assertEq(proxy.echo(),      3333);
        assertEq(proxy.derbyOf(2),  0);
        assertEq(proxy.derbyOf(15), 9090);

        assertEq(proxy.getLiteral(),  4444);
        assertEq(proxy.getConstant(), 5555);
        assertEq(proxy.getViewable(), 3333);

        proxy.setCharlie(6969);
        assertEq(proxy.charlie(),                           6969);
        assertEq(proxy.setCharlieAndReturnOldCharlie(4343), 6969);
        assertEq(proxy.charlie(),                           4343);

        proxy.setEcho(4040);
        assertEq(proxy.echo(),                        4040);
        assertEq(proxy.setEchoAndReturnOldEcho(4949), 4040);
        assertEq(proxy.echo(),                        4949);

        proxy.setDerbyOf(2, 6161);
        assertEq(proxy.derbyOf(2),                             6161);
        assertEq(proxy.setDerbyOfAndReturnOldDerbyOf(2, 6868), 6161);
        assertEq(proxy.derbyOf(2),                             6868);

        proxy.setDerbyOf(15, 7676);
        assertEq(proxy.derbyOf(15),                             7676);
        assertEq(proxy.setDerbyOfAndReturnOldDerbyOf(15, 2828), 7676);
        assertEq(proxy.derbyOf(15),                             2828);
    }

    function test_composability() external {
        MockFactory          factory        = new MockFactory();
        MockInitializerV1    initializer    = new MockInitializerV1();
        MockImplementationV1 implementation = new MockImplementationV1();

        factory.registerMigrationPath(1, 1, address(initializer));
        factory.registerImplementation(1, address(implementation));

        IMockInitializerV1 proxy1 = IMockInitializerV1(factory.newInstance(1, new bytes(0)));
        address proxy2            = factory.newInstance(1, new bytes(0));

        // Change proxy2 values.
        IMockInitializerV1(proxy2).setBeta(5959);
        IMockInitializerV1(proxy2).setCharlie(6565);
        IMockInitializerV1(proxy2).setDeltaOf(2, 4455);
        IMockInitializerV1(proxy2).setDeltaOf(15, 1166);

        assertEq(proxy1.getAnotherFactory(proxy2),        address(factory));
        assertEq(proxy1.getAnotherImplementation(proxy2), address(implementation));

        assertEq(proxy1.getAnotherAlpha(proxy2),       1111);
        assertEq(proxy1.getAnotherBeta(proxy2),        5959);
        assertEq(proxy1.getAnotherCharlie(proxy2),     6565);
        assertEq(proxy1.getAnotherDeltaOf(proxy2, 2),  4455);
        assertEq(proxy1.getAnotherDeltaOf(proxy2, 15), 1166);

        assertEq(proxy1.getAnotherLiteral(proxy2),  2222);
        assertEq(proxy1.getAnotherConstant(proxy2), 1111);
        assertEq(proxy1.getAnotherViewable(proxy2), 5959);

        proxy1.setAnotherBeta(proxy2, 8888);
        assertEq(proxy1.getAnotherBeta(proxy2),                       8888);
        assertEq(proxy1.setAnotherBetaAndReturnOldBeta(proxy2, 9999), 8888);
        assertEq(proxy1.getAnotherBeta(proxy2),                       9999);

        proxy1.setAnotherCharlie(proxy2, 3838);
        assertEq(proxy1.getAnotherCharlie(proxy2),                          3838);
        assertEq(proxy1.setAnotherCharlieAndReturnOldCharlie(proxy2, 8383), 3838);
        assertEq(proxy1.getAnotherCharlie(proxy2),                          8383);

        proxy1.setAnotherDelta(proxy2, 15, 6464);
        assertEq(proxy1.getAnotherDeltaOf(proxy2, 15),                          6464);
        assertEq(proxy1.setAnotherDeltaOfAndReturnOldDeltaOf(proxy2, 15, 7474), 6464);
        assertEq(proxy1.getAnotherDeltaOf(proxy2, 15),                          7474);

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

        // Set some values in proxy.
        MockImplementationV1(proxy).setBeta(7575);
        MockImplementationV1(proxy).setCharlie(1414);
        MockImplementationV1(proxy).setDeltaOf(2,  3030);
        MockImplementationV1(proxy).setDeltaOf(4,  9944);
        MockImplementationV1(proxy).setDeltaOf(15, 2323);

        // Register V2, its initializer, and a migrator.
        factory.registerMigrationPath(2, 2, address(initializerV2));
        factory.registerImplementation(2, address(implementationV2));

        assertEq(factory.migratorForPath(1, 2), address(0));

        // Migrate proxy from V1 to V2.
        factory.upgradeInstance(proxy, 2, new bytes(0));

        // Check if migration was successful.
        assertEq(IMockInitializerV2(proxy).implementation(),  address(implementationV2));

        assertEq(IMockInitializerV2(proxy).charlie(),   7575);  // Is old beta.
        assertEq(IMockInitializerV2(proxy).echo(),      1414);  // Is old charlie.
        assertEq(IMockInitializerV2(proxy).derbyOf(2),  3030);  // Should remain unchanged.
        assertEq(IMockInitializerV2(proxy).derbyOf(4),  9944);  // Should remain unchanged.
        assertEq(IMockInitializerV2(proxy).derbyOf(15), 2323);  // Should remain unchanged.

        assertEq(IMockInitializerV2(proxy).getLiteral(),  4444);
        assertEq(IMockInitializerV2(proxy).getConstant(), 5555);
        assertEq(IMockInitializerV2(proxy).getViewable(), 1414);
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

        // Set some values in proxy.
        MockImplementationV1(proxy).setBeta(7575);
        MockImplementationV1(proxy).setCharlie(1414);
        MockImplementationV1(proxy).setDeltaOf(2,  3030);
        MockImplementationV1(proxy).setDeltaOf(4,  9944);
        MockImplementationV1(proxy).setDeltaOf(15, 2323);

        // Register V2, its initializer, and a migrator.
        factory.registerMigrationPath(2, 2, address(initializerV2));
        factory.registerMigrationPath(1, 2, address(migrator));
        factory.registerImplementation(2, address(implementationV2));

        assertEq(factory.migratorForPath(1, 2), address(migrator));

        // Migrate proxy from V1 to V2.
        factory.upgradeInstance(proxy, 2, abi.encode(uint256(9090)));

        // Check if migration was successful.
        assertEq(IMockInitializerV2(proxy).implementation(),  address(implementationV2));

        assertEq(IMockInitializerV2(proxy).charlie(),   2828);  // Should be doubled from V1.
        assertEq(IMockInitializerV2(proxy).echo(),      3333);
        assertEq(IMockInitializerV2(proxy).derbyOf(2),  3030);  // Should remain unchanged.
        assertEq(IMockInitializerV2(proxy).derbyOf(4),  1188);  // Should be different due to migration case.
        assertEq(IMockInitializerV2(proxy).derbyOf(15), 9090);  // Should have been overwritten by migration arg.

        assertEq(IMockInitializerV2(proxy).getLiteral(),  4444);
        assertEq(IMockInitializerV2(proxy).getConstant(), 5555);
        assertEq(IMockInitializerV2(proxy).getViewable(), 3333);
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

        // Set some values in proxy.
        MockImplementationV1(proxy).setBeta(7575);
        MockImplementationV1(proxy).setCharlie(1414);
        MockImplementationV1(proxy).setDeltaOf(2,  3030);
        MockImplementationV1(proxy).setDeltaOf(4,  9944);
        MockImplementationV1(proxy).setDeltaOf(15, 2323);

        // Register V2, its initializer, and a migrator.
        factory.registerMigrationPath(2, 2, address(initializerV2));
        factory.registerMigrationPath(1, 2, address(migrator));
        factory.registerImplementation(2, address(implementationV2));

        assertEq(factory.migratorForPath(1, 2), address(migrator));

        // Migrate proxy from V1 to V2.
        factory.upgradeInstance(proxy, 2, abi.encode(uint256(9090)));

        // Check if migration was successful.
        assertEq(IMockInitializerV2(proxy).implementation(),  address(implementationV2));

        assertEq(IMockInitializerV2(proxy).charlie(),   2828);  // Should be doubled from V1.
        assertEq(IMockInitializerV2(proxy).echo(),      3333);
        assertEq(IMockInitializerV2(proxy).derbyOf(2),  3030);  // Should remain unchanged.
        assertEq(IMockInitializerV2(proxy).derbyOf(4),  1188);  // Should be different due to migration case.
        assertEq(IMockInitializerV2(proxy).derbyOf(15), 15); 

        assertEq(IMockInitializerV2(proxy).getLiteral(),  4444);
        assertEq(IMockInitializerV2(proxy).getConstant(), 5555);
        assertEq(IMockInitializerV2(proxy).getViewable(), 3333);
    }

    function test_newInstanceWithSalt() public {
        MockFactory          factory        = new MockFactory();
        MockImplementationV1 implementation = new MockImplementationV1();

        factory.registerImplementation(1, address(implementation));

        address proxy = factory.newInstanceWithSalt(1, new bytes(0), "salt");

        assertEq(proxy, 0x6FD86f82E0D16465c7c9898971A545B83d43a9e0);
    }
     

    function testFail_newInstanceWithSalt() public {
        MockFactory          factory        = new MockFactory();
        MockImplementationV1 implementation = new MockImplementationV1();

        factory.registerImplementation(1, address(implementation));
        factory.newInstanceWithSalt(1, new bytes(0), "salt");
        factory.newInstanceWithSalt(1, new bytes(0), "salt");
    }

    function testFail_newInstance_nonRegistered_implementation() public {
        MockFactory factory = new MockFactory();

        address proxy = factory.newInstance(1, new bytes(0));
    }

    function testFail_upgrade_nonRegistered_implementation() public {
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
