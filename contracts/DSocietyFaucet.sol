// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DSocietyERC20Faucet is AccessControl{

    event TransferSent(address _from, uint _amount);

    IERC20 public DSocial;

    //amount allowed to be requested at a time
    uint public amountAllowed = 0.1 * 10 ** 18;

    //mapping to keep track of requested rokens
    //Address and blocktime + 1 day is saved in TimeLock
    mapping(address => uint) public lockTime;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setDSocialContract(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        DSocial = IERC20(_address);
    }

    function faucetBalance() public view returns(uint) {
        return DSocial.balanceOf(address(this));
    }

    //function to send tokens from faucet to an address
    function request() public {

        //perform a few checks to make sure function can execute
        require(block.timestamp > lockTime[msg.sender], "lock time has not expired. Please try again later");
        require(DSocial.balanceOf(address(this)) > amountAllowed, "faucet is low on tokens");

        //if the balance of this contract is greater then the requested amount send funds
        DSocial.transfer(msg.sender, amountAllowed);        
 
        //updates locktime 1 day from now
        lockTime[msg.sender] = block.timestamp + 1 days;
        emit TransferSent(msg.sender, amountAllowed);
    }

}