// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IProxied } from "./interfaces/IProxied.sol";

import { Proxy } from "./Proxy.sol";

/// @title A factory for Proxy contracts that proxy Proxied implementations.
contract ProxyFactory {

    bytes32 internal constant PROXY_CODE_HASH = keccak256(type(Proxy).runtimeCode);

    mapping(uint256 => address) internal _implementationOf;

    mapping(address => uint256) internal _versionOf;

    mapping(uint256 => mapping(uint256 => address)) internal _migratorForPath;

    function _initializeInstance(address proxy_, uint256 version_, bytes memory arguments_) internal virtual returns (bool success_) {
        if (!_isContract(proxy_)) return false;

        address initializer = _migratorForPath[version_][version_];

        if (initializer == address(0)) return true;

        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.migrate.selector, initializer, arguments_));
    }

    function _newInstance(uint256 version_, bytes memory arguments_) internal virtual returns (bool success_, address proxy_) {
        address implementation = _implementationOf[version_];

        success_ =
            implementation != address(0) &&
            _initializeInstance(proxy_ = address(new Proxy(address(this), implementation)), version_, arguments_);
    }

    function _newInstance(uint256 version_, bytes memory arguments_, bytes32 salt_) internal virtual returns (bool success_, address proxy_) {
        address implementation = _implementationOf[version_];

        success_ =
            implementation != address(0) &&
            _initializeInstance(proxy_ = address(new Proxy{ salt: salt_ }(address(this), address(0))), version_, arguments_);
    }

    function _registerImplementation(uint256 version_, address implementationAddress_) internal virtual returns (bool success_) {
        // Cannot already be registered and cannot be empty implementation.
        if (
            _implementationOf[version_] != address(0) || 
            _versionOf[implementationAddress_] != 0   || 
            !_isContract(implementationAddress_)
        ) return false;

        // TODO _versionOf[implementation] might already exist and here we're overriding it.
        _versionOf[implementationAddress_] = version_;
        _implementationOf[version_]        = implementationAddress_;

        return true;
    }

    function _registerMigrator(uint256 fromVersion_, uint256 toVersion_, address migrator_) internal virtual returns (bool success_) {
        if (migrator_ != address(0) && !_isContract(migrator_)) return false;

        _migratorForPath[fromVersion_][toVersion_] = migrator_;

        return true;
    }

    function _upgradeInstance(address proxy_, uint256 toVersion_, bytes memory arguments_) internal virtual returns (bool success_) {
        if (!_isContract(proxy_)) return false;

        address toImplementation = _implementationOf[toVersion_];

        if (toImplementation == address(0)) return false;

        bytes memory returnData;

        ( success_, returnData ) = proxy_.call(abi.encodeWithSelector(IProxied.implementation.selector));

        if (!success_) return false;

        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.setImplementation.selector, toImplementation));

        if (!success_) return false;

        // Get the "fromImplementation" from `returnData`, then the version of the "fromImplementation", then get the `migrator` of the upgrade path.
        address migrator = _migratorForPath[_versionOf[abi.decode(returnData, (address))]][toVersion_];

        if (migrator == address(0)) return true;

        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.migrate.selector, migrator, arguments_));
    }

    function _getDeterministicProxyAddress(bytes32 salt_) internal virtual view returns (address proxyAddress_) {
        // See https://docs.soliditylang.org/en/v0.8.7/control-structures.html#salted-contract-creations-create2
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt_,
                            keccak256(abi.encodePacked(type(Proxy).creationCode, abi.encode(address(this), address(0))))
                        )
                    )
                )
            )
        );
    }

    function _isContract(address account_) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account_)
        }

        return size != uint256(0);
    }

}
