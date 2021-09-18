// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IProxied } from "./interfaces/IProxied.sol";

import { Proxy } from "./Proxy.sol";

contract ProxyFactory {

    mapping(uint256 => address) internal _implementationOf;

    mapping(address => uint256) internal _versionOf;

    mapping(uint256 => mapping(uint256 => address)) internal _migratorForPath;

    function _createPredeterminateInstance(bytes32 salt_) internal returns (address proxy_) {
        bytes memory creationCode = type(Proxy).creationCode;

        assembly {
            proxy_ := create2(0, add(creationCode, 32), mload(creationCode), salt_)
        }
    }

    function _initializeInstance(
        address proxy_,
        uint256 version_,
        address implementation_,
        bytes memory arguments_
    ) internal virtual returns (bool success_) {
        if (proxy_ == address(0)) return false;

        if (implementation_ == address(0)) return false;

        ( success_, ) = proxy_.call(abi.encode(address(this), implementation_));

        if (!success_) return false;

        address initializer = _migratorForPath[version_][version_];

        if (initializer == address(0)) return true;

        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.migrate.selector, initializer, arguments_));
    }

    function _newInstance(uint256 version_, bytes memory arguments_) internal virtual returns (bool success_, address proxy_) {
        success_ = _initializeInstance(proxy_ = address(new Proxy()), version_, _implementationOf[version_], arguments_);
    }

    function _newInstanceWithSalt(uint256 version_, bytes memory arguments_, bytes32 salt_) internal virtual returns (bool success_, address proxy_) {
        success_ = _initializeInstance(proxy_ = _createPredeterminateInstance(salt_), version_, _implementationOf[version_], arguments_);
    }

    function _registerImplementation(uint256 version_, address implementationAddress_) internal virtual returns (bool success_) {
        // Cannot already be registered and cannot be empty implementation
        if (_implementationOf[version_] != address(0) || implementationAddress_ == address(0)) return false;

        _versionOf[implementationAddress_] = version_;
        _implementationOf[version_]        = implementationAddress_;

        return true;
    }

    function _registerMigrator(uint256 fromVersion_, uint256 toVersion_, address migrator_) internal virtual returns (bool success_) {
        _migratorForPath[fromVersion_][toVersion_] = migrator_;

        return true;
    }

    function _upgradeInstance(address proxy_, uint256 toVersion_, bytes memory arguments_) internal virtual returns (bool success_) {
        address implementation = _implementationOf[toVersion_];

        if (implementation == address(0)) return false;

        address migrator = _migratorForPath[_versionOf[IProxied(proxy_).implementation()]][toVersion_];

        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.setImplementation.selector, implementation));

        if (!success_) return false;

        if (migrator == address(0)) return true;

        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.migrate.selector, migrator, arguments_));
    }

}
