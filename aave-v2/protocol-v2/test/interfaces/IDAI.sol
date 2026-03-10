// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IDAI {
  // --- Auth ---
  function wards(address) external view returns (uint256);
  function rely(address guy) external;
  function deny(address guy) external;

  // --- ERC20 Metadata ---
  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function version() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint256);

  // --- ERC20 Balances & Allowances ---
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);
  function nonces(address) external view returns (uint256);

  // --- Events ---
  event Approval(address indexed src, address indexed guy, uint256 wad);
  event Transfer(address indexed src, address indexed dst, uint256 wad);

  // --- Token Functions ---
  function transfer(address dst, uint256 wad) external returns (bool);
  function transferFrom(address src, address dst, uint256 wad) external returns (bool);
  function mint(address usr, uint256 wad) external;
  function burn(address usr, uint256 wad) external;
  function approve(address usr, uint256 wad) external returns (bool);

  // --- Alias Functions ---
  function push(address usr, uint256 wad) external;
  function pull(address usr, uint256 wad) external;
  function move(address src, address dst, uint256 wad) external;

  // --- Permit (EIP-2612) ---
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function permit(
    address holder,
    address spender,
    uint256 nonce,
    uint256 expiry,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}
