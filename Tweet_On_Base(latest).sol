// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "contracts/token/ERC20/ERC20.sol";
import "contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "contracts/access/Ownable.sol";
import "contracts/security/ReentrancyGuard.sol";

contract Tweet_On_Base is ERC20, ERC20Burnable, Ownable, ReentrancyGuard { 
    uint256 public constant INITIAL_SUPPLY = 10_000_000 * (10 ** 2);
    uint256 public constant MAX_SUPPLY = 50_000_000_000 * (10 ** 2); 
    mapping(address => uint256) private _liquidityProvided;
    mapping(address => uint256) private _liquidityProvidedTimestamp;

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }
        
    constructor() ERC20("Tweet On Base", "Tweets") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
    function _transfer(address sender, address recipient, uint256 amount) internal override {
    uint256 burnAmount = amount / 100000; 
    uint256 sendAmount = amount - burnAmount; 
    require(amount == sendAmount + burnAmount, "Burn value invalid");

   
    if (sender != msg.sender) {
        super._burn(sender, burnAmount);
    }

    super._transfer(sender, recipient, sendAmount);
}

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    override
{
    super._beforeTokenTransfer(from, to, amount);
}


    function addLiquidity(uint256 amount) public {
        _transfer(msg.sender, address(this), amount);
        _liquidityProvided[msg.sender] += amount;
        _liquidityProvidedTimestamp[msg.sender] = block.timestamp;
    }
    function undoAddLiquidity(uint256 amount) public {
        _transfer(address(this), msg.sender, amount);
        _liquidityProvided[msg.sender] -= amount;
        _liquidityProvidedTimestamp[msg.sender] = block.timestamp;
    }

    event RewardClaimed(address indexed user, uint256 reward);

    function removeLiquidityAndClaimRewards(uint256 amount) public nonReentrant {
        require(amount <= _liquidityProvided[msg.sender], "Insufficient balance");
        require(block.timestamp >= _liquidityProvidedTimestamp[msg.sender] + 30 days, "Liquidity must be provided for at least 30 days to qualify for rewards");

        uint256 reward = calculateReward(msg.sender);
        require(totalSupply() + reward <= MAX_SUPPLY, "Reward exceeds max supply");

        // Mint the reward tokens only after the 30-day period
        if (reward > 0) {
            _mint(msg.sender, reward);
            emit RewardClaimed(msg.sender, reward); // Emit the event
        }

        _transfer(address(this), msg.sender, amount);
        _liquidityProvided[msg.sender] -= amount;

        if (_liquidityProvided[msg.sender] == 0) {
            _liquidityProvidedTimestamp[msg.sender] = 0;
        } else {
            _liquidityProvidedTimestamp[msg.sender] = block.timestamp;
        }
    }

    function calculateReward(address user) public view returns (uint256) {
        if (block.timestamp >= _liquidityProvidedTimestamp[user] + 30 days) {
            uint256 reward = (_liquidityProvided[user] * 5) / 100;
            if (totalSupply() + reward <= MAX_SUPPLY) {
                return reward;
            }
        }
        return 0;
    }
    function ownerAddLiquidity(uint256 amount) public onlyOwner {
        _liquidityProvided[owner()] += amount;
        _liquidityProvidedTimestamp[owner()] = block.timestamp;
        _mint(address(this), amount);
    }

    function ownerRemoveLiquidity(uint256 amount) public onlyOwner nonReentrant {
        require(amount <= _liquidityProvided[owner()], "Insufficient balance");
        _liquidityProvided[owner()] -= amount;
        if (_liquidityProvided[owner()] == 0) {
            _liquidityProvidedTimestamp[owner()] = 0;
        }
        _transfer(address(this), owner(), amount); 
    }


}
