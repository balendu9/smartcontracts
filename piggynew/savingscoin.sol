// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Savingscoin is ERC20{
    constructor() ERC20("SAVINGSCOIN", "SVNG"){
        _mint(msg.sender,10000000*10**18);
    }
}