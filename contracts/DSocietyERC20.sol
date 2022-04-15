// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DSocietyERC20 is ERC20, AccessControl {

    constructor() ERC20("Decentralized Society Token", "DST") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }

}