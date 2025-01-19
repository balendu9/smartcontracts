// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";

contract PIGGYCOIN is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 200_000_000 * 10**18;

    constructor() ERC20("PIGGYCOIN", "PGY") {
        _mint(msg.sender, 100_000_000 * 10**18); // Initial supply
    }

    /**
     * @dev Mint new tokens up to the maximum supply.
     * Can only be called by the owner.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds maximum supply");
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens from the caller's account.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Burn tokens on behalf of another account.
     * The caller must have sufficient allowance from the account.
     */
    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }
}
