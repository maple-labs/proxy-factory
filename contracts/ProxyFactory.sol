// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IProxied } from "./interfaces/IProxied.sol";

import { Proxy } from "./Proxy.sol";

contract ProxyFactory {
  
    mapping(uint256 => address) internal _implementation;

    mapping(address => uint256) internal _versionOf;

    mapping(uint256 => mapping(uint256 => address)) internal _migratorForPath;

    function _registerImplementation(uint256 version, address implementationAddress) internal virtual returns (bool success) {
        // Cannot already be registered and cannot be empty implementation
        if (_implementation[version] != address(0) || implementationAddress == address(0)) return false;

        _versionOf[implementationAddress] = version;
        _implementation[version]          = implementationAddress;

        return true;
    }

    function _newInstance(uint256 version, bytes calldata arguments) internal virtual returns (bool success, address proxy) {
        require(_implementation[version] != address(0), "PF:NI:NO_IMPLEMENTATION");
        proxy   = address(new Proxy());
        success = _initializeInstance(proxy, version, arguments);
    }

    function _newInstanceWithSalt(uint256 version, bytes calldata arguments, bytes32 salt) internal virtual returns (bool success, address proxy) {
        bytes memory creationCode = type(Proxy).creationCode;

        assembly {
            proxy := create2(0, add(creationCode, 32), mload(creationCode), salt)
        }

        if (proxy == address(0)) return (false, proxy);
    
        success = _initializeInstance(proxy, version, arguments);
    }

    function _initializeInstance(address proxy, uint256 version, bytes calldata arguments) internal virtual returns (bool success) {
        (success, ) = proxy.call(abi.encode(address(this), _implementation[version]));

        if (!success) return false;

        address initializer = _migratorForPath[version][version];

        if (initializer == address(0)) return true;

        (success, ) = proxy.call(abi.encodeWithSelector(IProxied.migrate.selector, initializer, arguments));
    }

    function _registerMigrator(uint256 fromVersion, uint256 toVersion, address migrator) internal virtual returns (bool success) {
        _migratorForPath[fromVersion][toVersion] = migrator;
        return true;
    }

    function _upgradeInstance(address proxy, uint256 toVersion, bytes calldata arguments) internal virtual returns (bool success) {
        address migrator       = _migratorForPath[_versionOf[IProxied(proxy).implementation()]][toVersion];
        address implementation = _implementation[toVersion];

        require(implementation != address(0), "PF:UI:NO_IMPLEMENTATION");
        
        IProxied(proxy).setImplementation(implementation);

        if (migrator == address(0)) return true;

        (success, ) = proxy.call(abi.encodeWithSelector(IProxied.migrate.selector, migrator, arguments));
    }

}
