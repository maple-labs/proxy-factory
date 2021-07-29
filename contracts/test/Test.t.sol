// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { DSTest } from "../../modules/ds-test/src/test.sol";

import { IProxy, Proxy } from "../Proxy.sol";
import { ProxyFactory }  from "../ProxyFactory.sol";

interface IMockImplementation is IProxy {
    
    function foo() external view returns (uint256);

    function barOf(uint256) external view returns (uint256);

    function constantFoo() external view returns (uint256);

    function pureFunction1() external pure returns (uint256);

    function pureFunction2() external pure returns (uint256);

    function viewFunction() external view returns (uint256);

    function setFoo(uint256 newFoo) external;

    function setFooAndReturnOldFoo(uint256 newFoo) external returns (uint256 oldFoo);

    function setBarOf(uint256 key, uint256 newBar) external;

    function getAnotherFoo(address other) external view returns (uint256);

    function setAnotherFoo(address other, uint256 newFoo) external;

    function getAnotherBarOf(address other, uint256 key) external view returns (uint256);

    function setAnotherBarOf(address other, uint256 key, uint256 value) external;

}

contract MockImplementation is Proxy {

    uint256 public          foo;
    uint256 public constant constantFoo = 1111;

    mapping(uint256 => uint256) public barOf;

    function pureFunction1() external pure returns (uint256) {
        return 2222;
    }

    function pureFunction2() external pure returns (uint256) {
        return constantFoo;
    }

    function viewFunction() external view returns (uint256) {
        return foo;
    }

    function setFoo(uint256 newFoo) external {
        foo = newFoo;
    }

    function setFooAndReturnOldFoo(uint256 newFoo) external returns (uint256 oldFoo) {
        oldFoo = foo;
        foo = newFoo;
    }

    function setBarOf(uint256 key, uint256 newBar) external {
        barOf[key] = newBar;
    }

    function getAnotherFoo(address other) external view returns (uint256) {
        return IMockImplementation(other).foo();
    }

    function setAnotherFoo(address other, uint256 newFoo) external {
        return IMockImplementation(other).setFoo(newFoo);
    }

    function getAnotherBarOf(address other, uint256 key) external view returns (uint256) {
        return IMockImplementation(other).barOf(key);
    }

    function setAnotherBarOf(address other, uint256 key, uint256 value) external {
        return IMockImplementation(other).setBarOf(key, value);
    }

}

interface IMockImprovedImplementation is IMockImplementation {

    function baz() external view returns (uint256);

    function setBaz(uint256 newBaz) external;

    function getAnotherBaz(address other) external view returns (uint256);

    function setAnotherBaz(address other, uint256 newBaz) external;

}

contract MockImprovedImplementation is MockImplementation {

    uint256 public baz;

    function setBaz(uint256 newBaz) external {
        baz = newBaz;
    }

    function getAnotherBaz(address other) external view returns (uint256) {
        return IMockImprovedImplementation(other).foo();
    }

    function setAnotherBaz(address other, uint256 newBaz) external {
        return IMockImprovedImplementation(other).setFoo(newBaz);
    }

}

contract Test is DSTest {

    function getCodeHash(address implementation) internal view returns (bytes32 codeHash) {
        assembly { codeHash := extcodehash(implementation) }
    }

    function test_simpleCreation() external {
        ProxyFactory factory              = new ProxyFactory();
        MockImplementation implementation = new MockImplementation();

        factory.registerVersion(1, getCodeHash(address(implementation)));
        factory.registerImplementation(1, address(implementation));

        IMockImplementation proxy = IMockImplementation(factory.newInstance());
        
        assertEq(factory.implementationFor(address(proxy)), address(implementation));
        assertEq(proxy.implementation(),                    address(implementation));

        proxy.setFoo(8888);
        assertEq(proxy.foo(),                        8888);
        assertEq(proxy.pureFunction1(),              2222);
        assertEq(proxy.pureFunction2(),              1111);
        assertEq(proxy.viewFunction(),               8888);
        assertEq(proxy.setFooAndReturnOldFoo(9999),  8888);
        assertEq(proxy.foo(),                        9999);

        proxy.setBarOf(3333, 4444);
        proxy.setBarOf(5555, 6666);
        assertEq(proxy.barOf(3333), 4444);
        assertEq(proxy.barOf(5555), 6666);
    }

    function test_composability() external {
        ProxyFactory factory              = new ProxyFactory();
        MockImplementation implementation = new MockImplementation();

        factory.registerVersion(1, getCodeHash(address(implementation)));
        factory.registerImplementation(1, address(implementation));

        IMockImplementation proxy1 = IMockImplementation(factory.newInstance());
        IMockImplementation proxy2 = IMockImplementation(factory.newInstance());
        
        proxy1.setFoo(7777);
        proxy1.setBarOf(3333, 4444);

        assertEq(proxy2.getAnotherFoo(address(proxy1)),         7777);
        assertEq(proxy2.getAnotherBarOf(address(proxy1), 3333), 4444);

        proxy2.setAnotherFoo(address(proxy1), 9999);
        proxy2.setAnotherBarOf(address(proxy1), 3333, 6666);

        assertEq(proxy2.getAnotherFoo(address(proxy1)),         9999);
        assertEq(proxy2.getAnotherBarOf(address(proxy1), 3333), 6666);
    }

    function test_upgradeability() external {
        ProxyFactory factory               = new ProxyFactory();
        MockImplementation implementation1 = new MockImplementation();
        
        factory.registerVersion(1, getCodeHash(address(implementation1)));
        factory.registerImplementation(1, address(implementation1));

        address proxy = factory.newInstance();

        IMockImplementation(proxy).setFoo(8888);
        IMockImplementation(proxy).setBarOf(3333, 4444);
        IMockImplementation(proxy).setBarOf(5555, 6666);

        MockImprovedImplementation implementation2 = new MockImprovedImplementation();
        factory.registerVersion(2, getCodeHash(address(implementation2)));
        factory.registerImplementation(2, address(implementation2));

        factory.setUpgradePath(1, 2);
        factory.updateImplementationFor(proxy, 1);

        assertEq(factory.implementationFor(address(proxy)),           address(implementation2));
        assertEq(IMockImprovedImplementation(proxy).implementation(), address(implementation2));

        IMockImprovedImplementation(proxy).setBarOf(5555, 7777);
        IMockImprovedImplementation(proxy).setBaz(9999);

        assertEq(IMockImprovedImplementation(proxy).foo(),       8888);
        assertEq(IMockImprovedImplementation(proxy).barOf(3333), 4444);
        assertEq(IMockImprovedImplementation(proxy).barOf(5555), 7777);
        assertEq(IMockImprovedImplementation(proxy).baz(),       9999);
    }

}
