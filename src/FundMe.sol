// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();
error FundMe__CallFailed();
error FundMe__NotEnoughETH();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    address[] private s_funders;
    mapping(address funder => uint256 amountFunded)
        private s_addressToAmountFunded;

    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // if (msg.value.getConversionRate() < MINIMUM_USD) {revert FundMe__NotEnoughETH();}
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You didn't send enough ETH."
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Not owner");
        for (
            uint256 fundersIndex = 0;
            fundersIndex < s_funders.length;
            fundersIndex++
        ) {
            address funder = s_funders[fundersIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the funders array
        s_funders = new address[](0);

        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable (msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call, the recommeded way of sending eth
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
        // if (!callSuccess) {revert FundMe__CallFailed();}
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // view/pure functions
    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
