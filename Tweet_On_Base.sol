// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Test_Tweet_On_Base is ERC20, ERC20Burnable, Pausable, Ownable, ReentrancyGuard { 
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * (10 ** 18);
    uint256 public constant MAX_SUPPLY = 5_000_000_000 * (10 ** 18); 

    mapping(address => uint256) private _liquidityProvided;
    mapping(address => uint256) private _liquidityProvidedTimestamp;

    bool private _circuitBreakerEnabled = false;

    constructor() ERC20("Tweet On Base", "Tweets") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    

    // Circuit Breaker modifier
    modifier circuitBreakerNotActive() {
        require(!_circuitBreakerEnabled, "Circuit breaker is active");
        _;
    }
    // Function to enable the circuit breaker
    function enableCircuitBreaker() public onlyOwner {
        _circuitBreakerEnabled = true;
    }

    // Function to disable the circuit breaker
    function disableCircuitBreaker() public onlyOwner {
        _circuitBreakerEnabled = false;
    }

    // Override the _transfer function to include burning 0.001% of the transaction
    function _transfer(address sender, address recipient, uint256 amount) internal override circuitBreakerNotActive {
        uint256 burnAmount = amount / 100000; // 0.001% of the transaction
        uint256 sendAmount = amount - burnAmount; // 99.999% of the transaction
        require(amount == sendAmount + burnAmount, "Burn value invalid");

        super._transfer(sender, recipient, sendAmount);
        _burn(sender, burnAmount);
    }
 
    // Override the _beforeTokenTransfer function to include burning 0.001% of the transaction and the _liquidityProvidedTimestamp mapping update

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        circuitBreakerNotActive
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function addLiquidity(uint256 amount) public {
        _transfer(msg.sender, address(this), amount);
        _liquidityProvided[msg.sender] += amount;
        _liquidityProvidedTimestamp[msg.sender] = block.timestamp;
    }
    function removeLiquidityAndClaimRewards(uint256 amount) public nonReentrant {
        require(amount <= _liquidityProvided[msg.sender], "Insufficient balance");
        require(block.timestamp >= _liquidityProvidedTimestamp[msg.sender] + 30 days, "Liquidity must be provided for at least 30 days to qualify for rewards");

        uint256 reward = calculateReward(msg.sender);
        require(totalSupply() + reward <= MAX_SUPPLY, "Reward exceeds max supply");

        _mint(msg.sender, reward); // Mint the reward to the liquidity provider
        _transfer(address(this), msg.sender, amount); // Transfer the liquidity back to the provider
        _liquidityProvided[msg.sender] -= amount;
        if (_liquidityProvided[msg.sender] == 0) {
            _liquidityProvidedTimestamp[msg.sender] = 0; // Reset the timestamp if all liquidity is removed
        } else {
            _liquidityProvidedTimestamp[msg.sender] = block.timestamp; // Update the timestamp for the remaining liquidity
        }
    }

    function calculateReward(address user) public view returns (uint256) {
        if (block.timestamp >= _liquidityProvidedTimestamp[user] + 30 days) {
            uint256 reward = (_liquidityProvided[user] * 5) / 100; // 5% reward
            return reward;
        }
        return 0;
    }

    // New function to allow the owner to add liquidity directly without rewards
    function ownerAddLiquidity(uint256 amount) public onlyOwner {
        _liquidityProvided[owner()] += amount;
        _liquidityProvidedTimestamp[owner()] = block.timestamp;
        _mint(address(this), amount); // Mint the tokens directly to the contract
    }

    // New function to allow the owner to remove liquidity directly without rewards
    function ownerRemoveLiquidity(uint256 amount) public onlyOwner nonReentrant {
        require(amount <= _liquidityProvided[owner()], "Insufficient balance");
        _liquidityProvided[owner()] -= amount;
        if (_liquidityProvided[owner()] == 0) {
            _liquidityProvidedTimestamp[owner()] = 0;
        }
        _transfer(address(this), owner(), amount); // Transfer the liquidity back to the owner
    }


}
