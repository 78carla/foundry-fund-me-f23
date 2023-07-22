// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//Using the Foundry test package
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000
    uint256 constant STARTING_BALANCE = 1 ether; //1000000000000000000

    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //New instance of FundMe
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        //Create a new instance of DeployFundMe script (is a smart contract too)
        DeployFundMe deployFundMe = new DeployFundMe();
        //Run the deploy script and get the FundMe contract
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); //Give user some ETH
    }

    function testMinimuDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeeVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); //The next line should revert
        fundMe.fund(); //Send 0 ETH
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //The next TX will be sent by user
        //Send 10 ETH
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAmountToAddressFunded(address(USER));
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunder() public {
        vm.prank(USER); //The next TX will be sent by user
        //Send 10 ETH
        fundMe.fund{value: SEND_VALUE}();
        //Funders address
        address funders = fundMe.getFunders(0);
        assertEq(funders, USER);
    }

    modifier funded() {
        vm.prank(USER); //The next TX will be sent by user
        fundMe.fund{value: SEND_VALUE}(); //Send 10 ETH
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER); //The next TX will be sent by user (not owner)
        vm.expectRevert(); //The next line should revert
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange - set the test
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();
        //Act - the action I want to test
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        //Assert - control the result
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() public funded {
        //Arrange - set the test
        uint160 numberOfFunders = 10;
        uint160 startingFunderInsex = 1;

        //Funders fund the contract
        for (uint160 i = startingFunderInsex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            //address(0) - generate an address that doesn't exist
            hoax(address(i), SEND_VALUE);
            //fund the fundMe contract
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

         //Act - the action I want to test
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);

    }

    function testWithdrawWithMultipleFundersCheaper() public funded {
        //Arrange - set the test
        uint160 numberOfFunders = 10;
        uint160 startingFunderInsex = 1;

        //Funders fund the contract
        for (uint160 i = startingFunderInsex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            //address(0) - generate an address that doesn't exist
            hoax(address(i), SEND_VALUE);
            //fund the fundMe contract
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

         //Act - the action I want to test
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);

    }
}
