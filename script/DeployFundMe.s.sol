// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

// few commands : 
// forge script script/DeployFundMe.s.sol

contract DeployFundMe is Script {
    function run() external returns(FundMe) {
        // before broadcast -> not a real "tx" : it will simulate this in a simulated environment
        HelperConfig helperConfig = new HelperConfig();
        (address ethUsdPriceFeed) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe; 
    }
}