// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.20;
interface IUSDT {
  // con. Ownable
  function Ownable() external;
  function transferOwnership(address newOwner) external;

  // con. ERC20Basic
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external;
  event Transfer(address indexed from, address indexed to, uint256 value);
  // con. ERC20

  function allowance(address owner, address spender) external returns (uint256);
  function approve(address spender, uint256 amount) external;
  function transferFrom(address from, address to, uint256 value) external;
  // con. BasicToken
  // function transfer(address _to, uint256 _value) external;
  // function balanceOf(address _owner) external returns (uint256 balance);
  // con. StandardToken
  // function transferFrom(address _from, address _to, uint _value) external;
  // function approve(address _spender, uint _value) external;
  // function allowance(
  //     address _owner,
  //     address _spender
  // ) external returns (uint remaining);
  // con. Pausable
  function pause() external;
  function unpause() external;
  event Pause();
  event Unpause();
  // con. BlackList
  function getBlackListStatus(address _maker) external returns (bool);
  function getOwner() external returns (address);
  function addBlackList(address _evilUser) external;
  function removeBlackList(address _clearedUser) external;
  function destroyBlackFunds(address _blackListedUser) external;
  event DestroyedBlackFunds(address _blackListedUser, uint _balance);

  event AddedBlackList(address _user);

  event RemovedBlackList(address _user);
  // con. UpgradedStandardToken
  function transferByLegacy(address from, address to, uint value) external;
  function transferFromByLegacy(address sender, address from, address spender, uint value) external;
  function approveByLegacy(address from, address spender, uint value) external;
  // con. TetherToken
  function TetherToken(
    uint _initialSupply,
    string memory _name,
    string memory _symbol,
    uint _decimals
  ) external;
  // function transfer(address _to, uint _value) external;
  // function transferFrom(address _from, address _to, uint _value) external;
  // function balanceOf(address who) external returns (uint);
  // function approve(address _spender, uint _value) external;
  // function allowance(
  //     address _owner,
  //     address _spender
  // ) external returns (uint remaining);
  function deprecate(address _upgradedAddress) external;
  // function totalSupply() external returns (uint);
  function issue(uint amount) external;
  function redeem(uint amount) external;
  function setParams(uint newBasisPoints, uint newMaxFee) external;
  // Called when new token are issued
  event Issue(uint amount);

  // Called when tokens are redeemed
  event Redeem(uint amount);

  // Called when contract is deprecated
  event Deprecate(address newAddress);

  // Called if contract ever adds fees
  event Params(uint feeBasisPoints, uint maxFee);
}
