// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IProxied } from "./interfaces/IProxied.sol";

import { Proxy } from "./Proxy.sol";

contract ProxyFactory {
  
    mapping(uint256 => address) internal _implementation;

    mapping(address => uint256) internal _versionOf;

    mapping(uint256 => mapping(uint256 => address)) internal _migratorForPath;

    function _registerImplementation(uint256 version_, address implementationAddress_) internal virtual returns (bool success_) {
        // Cannot already be registered and cannot be empty implementation
        if (_implementation[version_] != address(0) || implementationAddress_ == address(0)) return false;

        _versionOf[implementationAddress_] = version_;
        _implementation[version_]          = implementationAddress_;

        return true;
    }

    function _newInstance(uint256 version_, bytes memory arguments_) internal virtual returns (bool success_, address proxy_) {
        require(_implementation[version_] != address(0), "PF:NI:NO_IMPLEMENTATION");
        proxy_   = address(new Proxy());
        success_ = _initializeInstance(proxy_, version_, arguments_);
    }

    function _newInstanceWithSalt(uint256 version_, bytes memory arguments_, bytes32 salt_) internal virtual returns (bool success_, address proxy_) {
        bytes memory creationCode = type(Proxy).creationCode;

        assembly {
            proxy_ := create2(0, add(creationCode, 32), mload(creationCode), salt_)
        }

        if (proxy_ == address(0)) return (false, proxy_);
    
        success_ = _initializeInstance(proxy_, version_, arguments_);
    }

    function _initializeInstance(address proxy_, uint256 version_, bytes memory arguments_) internal virtual returns (bool success_) {
        (success_, ) = proxy_.call(abi.encode(address(this), _implementation[version_]));

        if (!success_) return false;

        address initializer = _migratorForPath[version_][version_];

        if (initializer == address(0)) return true;

        (success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.migrate.selector, initializer, arguments_));
    }

    function _registerMigrator(uint256 fromVersion_, uint256 toVersion_, address migrator_) internal virtual returns (bool success_) {
        _migratorForPath[fromVersion_][toVersion_] = migrator_;
        return true;
    }

    function _upgradeInstance(address proxy_, uint256 toVersion_, bytes memory arguments_) internal virtual returns (bool success_) {
        address migrator       = _migratorForPath[_versionOf[IProxied(proxy_).implementation()]][toVersion_];
        address implementation = _implementation[toVersion_];

        require(implementation != address(0), "PF:UI:NO_IMPLEMENTATION");
        
        IProxied(proxy_).setImplementation(implementation);

        if (migrator == address(0)) return true;

        (success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.migrate.selector, migrator, arguments_));
    }

}
