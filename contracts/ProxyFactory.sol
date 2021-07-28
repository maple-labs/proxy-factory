// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

contract Factory {
  
  mapping(uint256 => bytes32) public implementationHash;
  mapping(uint256 => address) public implementation;
  mapping(address => bool) public isImplementationNixed;
  mapping(address => address) public implementationFor;
  mapping(uint256 => uint256) public upgradePath;

  uint256 public latestVersion;

  function registerVersion(uint256 version, bytes32 codeHash) external {
    implementationHash[latestVersion = version] = codeHash;
  }

  function registerImplementation(uint256 version, address implementationAddress) external {
    bytes32 codeHash;    
    assembly { codeHash := extcodehash(implementationAddress) }
    require(implementationHash[version] == codeHash);
    implementation[version] = implementationAddress;
  }

  function newInstance() external returns (address proxy) {
    implementationFor[proxy = address(new Proxy())] = implementation[latestVersion];
  }

  function getImplementation() external view returns (address imp) {
    require(!isImplementationNixed[imp = implementationFor[msg.sender]]);
  }

  function updateImplementationFor(address proxy, uint256 oldVersion) external {
    address oldImplementation;
    require(isImplementationNixed[oldImplementation = implementationFor[proxy]]);
    require(implementation[oldVersion] == oldImplementation);
    require((implementationFor[proxy] = implementation[upgradePath[oldVersion]]) != address(0));
  }

}

contract Proxy {

  address public factory;

  constructor() payable {
    factory = msg.sender;
  }

  function callReferenceImplementation() internal {
    (bool success,) = Factory(factory).getImplementation().delegatecall(msg.data);
    require(success);
  }

  fallback() payable external {
    callReferenceImplementation();
  }

  receive() payable external {
    callReferenceImplementation();
  }

}
