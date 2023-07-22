// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__notOwner();

contract FundMe {
    //Per usare PriceConverter come uint256
    using PriceConverter for uint256;

    //Per tenere traccia di quanto ha mandato ciascuno
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;
    //Array di chi manda i soldi
    address[] private s_funders;

    //conversionRate ha 18 decimali quindi devo confrontarlo connun numero con 18decimali
    //Constant se la variabile non viene mai modificata - save gas. Non allocata nello storage ma nel bytecode.
    //21141 * 141 Gwei = 21242 * 141000000000 Wei = 0,002995122 ETH = 8.9 $
    uint256 public constant MINIMUM_USD = 5e18;

    // variabili che vengono settate fuori dalla riga dove vengono definite possonon essere immutable
    //Non allocata nello storage ma nel bytecode.
    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        //the sender in tis case is the deployer of the contract
        i_owner = msg.sender;
        //Crea istanza contratto usando interfaccia
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    //Payable permette di mandare soldi al contract
    function fund() public payable {
        //aggiungo getConversionRate per essere sicuro che mandi almeno 5$ in ETH - voglio il valore in $
        //msg.value viene passato in automatico in getConversionRate (che aspetta un imput) perchè è di tipo uint256
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!"); //1e18 = 1ETH - msg-value global variable
        //addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value; equivalent to
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender); //msg.sender è una global variable, è colui che chiama la funzione
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function cheaperWithdraw() public onlyOwner {
        //We define a memory variable instead of a storage variable
        uint256 fundersLenght = s_funders.length;
        for (uint256 funderIndex = 0; funderIndex < fundersLenght; funderIndex++) {
            //Set the address to the funder
            address funder = s_funders[funderIndex];
            //Reset the amount
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            //Set the address to the funder
            address funder = s_funders[funderIndex];
            //Reset the amount
            s_addressToAmountFunded[funder] = 0;
        }
        //Reset the array to a blanck using the new keyword
        s_funders = new address[](0);
        //withdraw the array

        //transfer - automatically rever (2300 gas)
        //msg.sender = address
        //payable msg.sender = payable address
        //payable(msg.sender).transfer(address(this).balance);
        //send - revert if I add the boll variable (2300 gas)

        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require (sendSuccess, "Send failed");

        //call. Call in questo caso è vuoto perchè non chiama nessuna funzione quindi "". Restituisce due variabili un bool e un data. I dati sono ritornati dalla funzione chiamata, nel nostro caso è vuoto perchè non chiamo nessuna funzione.
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        //first execute the code and then the require
        //_;

        //require(msg.sender == i_owner, "revert! not the i_owner");

        //Whatever else is in the function
        //First execute the require and then the code

        if (msg.sender != i_owner) {
            revert FundMe__notOwner();
        }
        _;
    }

    //Se qualcuno manda ETH al contratto senza chiamare la funzione fund() automaticamente viene chiamata fund()
    //receive and fallback

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    receive() external payable {
        fund();
    }

    //viene triggherata se calldata non è vuoto
    fallback() external payable {
        fund();
    }

    /* 
    ** View / Pure function - Getters
    */
    //These functions are used to check if they are populated correctly
    function getAmountToAddressFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunders(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
