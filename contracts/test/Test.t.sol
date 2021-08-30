// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { DSTest } from "../../modules/ds-test/src/test.sol";

import { ProxyFactory }  from "../ProxyFactory.sol";

import {
    MockInitializerV1,
    IMockV1,
    MockV1,
    MockInitializerV2,
    MockMigratorV1ToV2,
    IMockV2,
    MockV2
} from "./mocks/Mocks.sol";

contract Test is DSTest {

    function test_newInstance_withNoInitializationArgs() external {
        ProxyFactory factory          = new ProxyFactory();
        MockInitializerV1 initializer = new MockInitializerV1();
        MockV1 implementation         = new MockV1();

        factory.registerImplementation(1, address(implementation), address(initializer));
        factory.setRecommendedVersion(1);

        assertEq(factory.versionOf(address(implementation)), 1);

        IMockV1 proxy = IMockV1(factory.newInstance(factory.recommendedVersion(), new bytes(0)));

        assertEq(factory.implementationFor(address(proxy)), address(implementation));
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

        proxy.setCharlie(3838);
        assertEq(proxy.charlie(),                           3838);
        assertEq(proxy.setCharlieAndReturnOldCharlie(8383), 3838);

        proxy.setDeltaOf(2, 2929);
        assertEq(proxy.deltaOf(2),                             2929);
        assertEq(proxy.setDeltaOfAndReturnOldDeltaOf(2, 9292), 2929);

        proxy.setDeltaOf(15, 6464);
        assertEq(proxy.deltaOf(15),                             6464);
        assertEq(proxy.setDeltaOfAndReturnOldDeltaOf(15, 7474), 6464);
    }

    function test_newInstance_withInitializationArgs() external {
        ProxyFactory factory          = new ProxyFactory();
        MockInitializerV2 initializer = new MockInitializerV2();
        MockV2 implementation         = new MockV2();

        factory.registerImplementation(2, address(implementation), address(initializer));
        factory.setRecommendedVersion(2);

        assertEq(factory.versionOf(address(implementation)), 2);

        IMockV2 proxy = IMockV2(factory.newInstance(factory.recommendedVersion(), abi.encode(uint256(9090))));

        assertEq(factory.implementationFor(address(proxy)), address(implementation));
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

        proxy.setEcho(4040);
        assertEq(proxy.echo(),                        4040);
        assertEq(proxy.setEchoAndReturnOldEcho(4949), 4040);

        proxy.setDerbyOf(2, 6161);
        assertEq(proxy.derbyOf(2),                             6161);
        assertEq(proxy.setDerbyOfAndReturnOldDerbyOf(2, 6868), 6161);

        proxy.setDerbyOf(15, 7676);
        assertEq(proxy.derbyOf(15),                             7676);
        assertEq(proxy.setDerbyOfAndReturnOldDerbyOf(15, 2828), 7676);
    }

    function test_composability() external {
        ProxyFactory factory          = new ProxyFactory();
        MockInitializerV1 initializer = new MockInitializerV1();
        MockV1 implementation         = new MockV1();

        factory.registerImplementation(1, address(implementation), address(initializer));
        factory.setRecommendedVersion(1);

        IMockV1 proxy1 = IMockV1(factory.newInstance(factory.recommendedVersion(), new bytes(0)));
        address proxy2 = factory.newInstance(factory.recommendedVersion(), new bytes(0));

        // change proxy2 values
        IMockV1(proxy2).setBeta(5959);
        IMockV1(proxy2).setCharlie(6565);
        IMockV1(proxy2).setDeltaOf(2, 4455);
        IMockV1(proxy2).setDeltaOf(15, 1166);

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

        proxy1.setAnotherCharlie(proxy2, 3838);
        assertEq(proxy1.getAnotherCharlie(proxy2),                          3838);
        assertEq(proxy1.setAnotherCharlieAndReturnOldCharlie(proxy2, 8383), 3838);

        proxy1.setAnotherDelta(proxy2, 15, 6464);
        assertEq(proxy1.getAnotherDeltaOf(proxy2, 15),                          6464);
        assertEq(proxy1.setAnotherDeltaOfAndReturnOldDeltaOf(proxy2, 15, 7474), 6464);

        // ensure proxy1 values have remained as default
        assertEq(proxy1.alpha(),     1111);
        assertEq(proxy1.beta(),      1313);
        assertEq(proxy1.charlie(),   1717);
        assertEq(proxy1.deltaOf(2),  0);
        assertEq(proxy1.deltaOf(15), 4747);

        assertEq(proxy1.getLiteral(),  2222);
        assertEq(proxy1.getConstant(), 1111);
        assertEq(proxy1.getViewable(), 1313);
    }

    function test_upgradeability() external {
        ProxyFactory factory            = new ProxyFactory();
        MockInitializerV1 initializerV1 = new MockInitializerV1();
        MockV1 implementationV1         = new MockV1();
        MockInitializerV2 initializerV2 = new MockInitializerV2();
        MockV2 implementationV2         = new MockV2();
        MockMigratorV1ToV2 migrator     = new MockMigratorV1ToV2();

        // Register and recommend V1
        factory.registerImplementation(1, address(implementationV1), address(initializerV1));
        factory.setRecommendedVersion(1);

        address proxy = factory.newInstance(factory.recommendedVersion(), new bytes(0));

        // Set some values in proxy
        MockV1(proxy).setBeta(7575);
        MockV1(proxy).setCharlie(1414);
        MockV1(proxy).setDeltaOf(2,  3030);
        MockV1(proxy).setDeltaOf(4,  9944);
        MockV1(proxy).setDeltaOf(15, 2323);

        // Register and recommend V2
        factory.registerImplementation(2, address(implementationV2), address(initializerV2));
        factory.setMigrationPath(1, 2, address(migrator));
        assertEq(factory.migratorForPath(1, 2), address(migrator));
        factory.setRecommendedVersion(2);

        // Migrate proxy from V1 to V2
        factory.upgradeImplementationFor(proxy, 2, abi.encode(uint256(9090)));

        // Check if migration was successful
        assertEq(factory.implementationFor(proxy), address(implementationV2));
        assertEq(IMockV2(proxy).implementation(),  address(implementationV2));

        assertEq(IMockV2(proxy).charlie(),   2828);  // should be doubled from V1
        assertEq(IMockV2(proxy).echo(),      3333);
        assertEq(IMockV2(proxy).derbyOf(2),  3030);  // should remain unchanged
        assertEq(IMockV2(proxy).derbyOf(4),  1188);  // should be different due to migration case
        assertEq(IMockV2(proxy).derbyOf(15), 9090);  // should have been overwritten by migration arg

        assertEq(IMockV2(proxy).getLiteral(),  4444);
        assertEq(IMockV2(proxy).getConstant(), 5555);
        assertEq(IMockV2(proxy).getViewable(), 3333);
    }

}
