// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract Ca is ERC20, ERC20Burnable, Ownable {
  address liquidity;
  address rewards;

  mapping(address => bool) public transferWhitelist;

  constructor(uint256 _supply, address _rewards, address _liquidity) ERC20("Cyber Arena Token", "CAT") {
    _mint(msg.sender, _supply);
    rewards = _rewards;
    liquidity = _liquidity;
  }

  function isWhitelisted(address owner) public view returns (bool) {
    return transferWhitelist[owner];
  }

  function addToTransferWhitelist(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
        transferWhitelist[addresses[i]] = true;
    }
  }

  function transfer(address to, uint256 amount) public virtual override returns (bool) {
  if (transferWhitelist[to]) {
    return super.transfer(to, amount);
  }
  burn(25*amount/100000);
  super.transfer(rewards, 50*amount/100000);
  super.transfer(liquidity, 25*amount/100000);
  return super.transfer(to, 99*amount/100);
  }
}
