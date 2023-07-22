// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //Returns the USD value of ETH
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        //Price ETH in USD returned by the contract
        (, int256 price,,,) = priceFeed.latestRoundData();
        //Price has 8 decimanls, ETH 18 decimals, trasformo price in 18 decimals e nel tipo uint256
        //2000,00000000
        return uint256(price * 1e10);
    }

    //Convert msg.value in USD
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        //1ETH
        //2000_000000000000000000
        uint256 ethPrice = getPrice(priceFeed);
        //Divido per 1e18 perchè ho moltiplicato 1e18 * 1e18 prima. In solidity prima moltiplico e poi divido.
        //2000_000000000000000000 * 1_000000000000000000 / 1e18
        // 2000 = 1ETH
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
        return ethAmountInUsd;
    }
}
