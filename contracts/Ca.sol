// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Ca is ERC20, ERC20Burnable, Ownable {
  address liquidity;
  address rewards;

  mapping(address => bool) public transferWhitelist;

  constructor(uint256 _supply, address _rewards, address _liquidity) ERC20("Cyber Arena Token", "CAT") {
    _mint(msg.sender, _supply);
    rewards = _rewards;
    liquidity = _liquidity;
  }

  event AddressesWhitelisted(address[] addresses);

  function isWhitelisted(address owner) external view returns (bool) {
    return transferWhitelist[owner];
  }

  function addToTransferWhitelist(address[] calldata addresses) external onlyOwner {
    uint256 length = addresses.length;
    for (uint256 i = 0; i < length; i++) {
        transferWhitelist[addresses[i]] = true;
    }

    emit AddressesWhitelisted(addresses);
  }

  function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
    if (transferWhitelist[from] || transferWhitelist[to]) {
      return super._transfer(from, to, amount);
    }
    
    _burn(from, 25*amount/10000);
    super._transfer(from, rewards, 50*amount/10000);
    super._transfer(from, liquidity, 25*amount/10000);
    return super._transfer(from, to, 99*amount/100);
    }
}
