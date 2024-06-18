// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";

/// @custom:security-contact Sparemoney.club@domainsbyproxy.com
contract OnePoundFish is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    constructor(address initialOwner)
        ERC20("OnePoundFish", "OnePoundFish")
        ERC20Permit("OnePoundFish")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}