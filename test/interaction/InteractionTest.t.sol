// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//Using the Foundry test package
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interaction.s.sol";

contract InteractionsTest is Test {

    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000
    uint256 constant STARTING_BALANCE = 1 ether; //1000000000000000000
    uint256 constant GAS_PRICE = 1;

    function setUp () external {

        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); //Give user some ETH
    }

    function testUserCanFundInteractions() public {
  
        //Initializing a contract which is a script called FundFundMe
        FundFundMe fundFundMe = new FundFundMe();
        
        // vm.prank(USER);
        // vm.deal(USER, 1e18);

        //Using its fundFundMe function he just funded the contract.
        fundFundMe.fundFundMe(address(fundMe));
        
        // address funder = fundMe.getFunders(0);
        // console.log("Funder: %s", funder);
        // //Checking the funder should be USER
        // assertEq(funder, USER);
        
        //Withdraw test
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));
        assert(address(fundMe).balance == 0);
    }

}