// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
interface IUSDC {
  // ERC20
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  // IEIP712
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  // IERC1271

  function isValidSignature(
    bytes32 hash,
    bytes memory signature
  ) external view returns (bytes4 magicValue);

  // IFIATV1
  function initialize(
    string memory tokenName,
    string memory tokenSymbol,
    string memory tokenCurrency,
    uint8 tokenDecimals,
    address newMasterMinter,
    address newPauser,
    address newBlacklister,
    address newOwner
  ) external;
  function mint(address _to, uint256 _amount) external returns (bool);
  function minterAllowance(address minter) external view returns (uint256);
  function isMinter(address account) external view returns (bool);
  function configureMinter(address minter, uint256 minterAllowedAmount) external returns (bool);
  function removeMinter(address minter) external returns (bool);
  function burn(uint256 _amount) external;
  function updateMasterMinter(address _newMasterMinter) external;
  // IFIATV2
  function initializeV2_1(address lostAndFound) external;
  function version() external pure returns (string memory);
  function initializeV2_2(
    address[] calldata accountsToBlacklist,
    string calldata newSymbol
  ) external;
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    bytes memory signature
  ) external;
  function transferWithAuthorization(
    address from,
    address to,
    uint256 value,
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    bytes memory signature
  ) external;
  function receiveWithAuthorization(
    address from,
    address to,
    uint256 value,
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    bytes memory signature
  ) external;
  function cancelAuthorization(address authorizer, bytes32 nonce, bytes memory signature) external;
  function cancelAuthorization(
    address authorizer,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
  function increaseAllowance(address spender, uint256 increment) external returns (bool);
  function decreaseAllowance(address spender, uint256 decrement) external returns (bool);
  function initializeV2(string calldata newName) external;
  // IOwnable
  function owner() external view returns (address);
  function setOwner(address newOwner) external;
  function transferOwnership(address newOwner) external;
  // IPausable
  function pause() external;
  function unpause() external;
  function updatePauser(address _newPauser) external;
  // IRescuable
  function rescuer() external view returns (address);
  function rescueERC20(IERC20 tokenContract, address to, uint256 amount) external;
  function updateRescuer(address newRescuer) external;
  // lib Address
  function isContract(address account) external view returns (bool);
  function nonces(address owner) external view returns (uint256);
  function authorizationState(address authorizer, bytes32 nonce) external view returns (bool);
}
