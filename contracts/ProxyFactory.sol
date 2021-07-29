// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IProxyFactory } from "./interfaces/IProxyFactory.sol";

import { Proxy } from "./Proxy.sol";

contract ProxyFactory is IProxyFactory {
  
    mapping(uint256 => bytes32) public override implementationHash;
    mapping(uint256 => address) public override implementation;
    mapping(address => address) public override implementationFor;
    mapping(uint256 => uint256) public override upgradePath;

    uint256 public override latestVersion;
    uint256 public override latestImplementation;

    function registerVersion(uint256 version, bytes32 codeHash) external override {
        require(version != 0);
        require(implementationHash[version] == bytes32(0));
        require((implementationHash[latestVersion = version] = codeHash) != bytes32(0));
    }

    function registerImplementation(uint256 version, address implementationAddress) external override {
        require(version != 0);
        bytes32 codeHash;    
        assembly { codeHash := extcodehash(implementationAddress) }
        require(implementationHash[version] == codeHash);
        implementation[latestImplementation = version] = implementationAddress;
    }

    function setUpgradePath(uint256 oldVersion, uint256 newVersion) external override {
        upgradePath[oldVersion] = newVersion;
    }

    function newInstance() external override returns (address proxy) {
        implementationFor[proxy = address(new Proxy())] = implementation[latestImplementation];
    }

    function getImplementation() external override view returns (address imp) {
        return implementationFor[msg.sender];
    }

    function updateImplementationFor(address proxy, uint256 oldVersion) external override {
        require(implementation[oldVersion] == implementationFor[proxy]);
        require((implementationFor[proxy] = implementation[upgradePath[oldVersion]]) != address(0));
    }

}
