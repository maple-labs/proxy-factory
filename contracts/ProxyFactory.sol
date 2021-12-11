// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IProxied } from "./interfaces/IProxied.sol";

import { Proxy } from "./Proxy.sol";

/// @title A factory for Proxy contracts that proxy Proxied implementations.
contract ProxyFactory {

    mapping(uint256 => address) internal _implementationOf;

    mapping(address => uint256) internal _versionOf;

    mapping(uint256 => mapping(uint256 => address)) internal _migratorForPath;

    function _getImplementationOfProxy(address proxy_) private view returns (bool success_, address implementation_) {
        bytes memory returnData;
        ( success_, returnData ) = proxy_.staticcall(abi.encodeWithSelector(IProxied.implementation.selector));
        implementation_ = abi.decode(returnData, (address));
    }

    function _initializeInstance(address proxy_, uint256 version_, bytes memory arguments_) private returns (bool success_) {
        address initializer = _migratorForPath[version_][version_];

        if (initializer == address(0)) return arguments_.length == uint256(0);

        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.migrate.selector, initializer, arguments_));
    }

    function _newInstance(uint256 version_, bytes memory arguments_) internal virtual returns (bool success_, address proxy_) {
        address implementation = _implementationOf[version_];

        if (implementation == address(0)) return (false, address(0));

        proxy_   = address(new Proxy(address(this), implementation));
        success_ = _initializeInstance(proxy_, version_, arguments_);
    }

    function _newInstance(bytes memory arguments_, bytes32 salt_) internal virtual returns (bool success_, address proxy_) {
        proxy_ = address(new Proxy{ salt: salt_ }(address(this), address(0)));

        ( , address implementation ) = _getImplementationOfProxy(proxy_);

        uint256 version = _versionOf[implementation];

        success_ = (version != uint256(0)) && _initializeInstance(proxy_, version, arguments_);
    }

    function _registerImplementation(uint256 version_, address implementation_) internal virtual returns (bool success_) {
        if (
            version_ == uint256(0) ||
            _implementationOf[version_] != address(0) ||
            _versionOf[implementation_] != uint256(0) ||
            !_isContract(implementation_)
        ) return false;

        _implementationOf[version_] = implementation_;
        _versionOf[implementation_] = version_;

        return true;
    }

    function _registerMigrator(uint256 fromVersion_, uint256 toVersion_, address migrator_) internal virtual returns (bool success_) {
        if (fromVersion_ == uint256(0) || toVersion_ == uint256(0)) return false;

        if (migrator_ != address(0) && !_isContract(migrator_)) return false;

        _migratorForPath[fromVersion_][toVersion_] = migrator_;

        return true;
    }

    function _upgradeInstance(address proxy_, uint256 toVersion_, bytes memory arguments_) internal virtual returns (bool success_) {
        if (!_isContract(proxy_)) return false;

        address toImplementation = _implementationOf[toVersion_];

        if (toImplementation == address(0)) return false;

        address fromImplementation;
        ( success_, fromImplementation ) = _getImplementationOfProxy(proxy_);

        if (!success_) return false;

        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.setImplementation.selector, toImplementation));

        if (!success_) return false;

        address migrator = _migratorForPath[_versionOf[fromImplementation]][toVersion_];

        if (migrator == address(0)) return arguments_.length == uint256(0);

        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.migrate.selector, migrator, arguments_));
    }

    function _getDeterministicProxyAddress(bytes32 salt_) internal virtual view returns (address deterministicProxyAddress_) {
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

    function _isContract(address account_) internal view returns (bool isContract_) {
        uint256 size;

        assembly {
            size := extcodesize(account_)
        }

        return size != uint256(0);
    }

}
