// SPDX-License-Identifier: MIT

//Interact directly with the functions using a script
//Fund
//Withdraw

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";
// import {HelperConfig} from "./HelperConfig.s.sol";

contract FundFundMe is Script{

    uint256 constant SEND_VALUE = 0.1 ether;
    //Fund the FundMe contract
    function fundFundMe(address mostRecentlyDeployed) public{
        vm.startBroadcast();
        FundMe(payable (mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("FundMe funded with %s", SEND_VALUE);
    }

    function run() external {
        //Use the DevOpsTools to get the most recent deployed address of FundMe (so it isn't necessary to hardcode the address)
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        vm.startBroadcast();
        //Run function call the fundFundMe function that funds the FundMe contract
        fundFundMe(mostRecentlyDeployed);
        vm.stopBroadcast();
    }

}

contract WithdrawFundMe is Script{

    function withdrawFundMe(address mostRecentlyDeployed) public{
        vm.startBroadcast();
        FundMe(payable (mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        //Use the DevOpsTools to get the most recent deployed address of FundMe (so it isn't necessary to hardcode the address)
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        vm.startBroadcast();
        //Run function call the fundFundMe function that funds the FundMe contract
        withdrawFundMe(mostRecentlyDeployed);
        vm.stopBroadcast();
    }

}