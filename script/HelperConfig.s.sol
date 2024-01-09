// 1. deploy mock when we are on a local anvil chain
// 2. keep track of contract address across different chains 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script { // bcs we are using vm keyword in getAnvilEthConfig()
    // if we are on a local anvil we deploy mocks
    // otherwise we grab the existing address from the live network
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if(block.chainid == 11155111) { 
            activeNetworkConfig = getSepoliaEthConfig();
        } else if(block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getorCreateAnvilEthConfig();
        }
    }
    
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory){
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory){
        NetworkConfig memory ethConfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return ethConfig;
    }

    function getorCreateAnvilEthConfig() public returns (NetworkConfig memory){
        // this is basically saying that if we have already deployed anvil one do not deploy another just use previous one. Address defaults to 0 bcs
        if(activeNetworkConfig.priceFeed != address(0)){
            return activeNetworkConfig;
        }
        // deploy the mocks
        // return the addresses
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilConfig;
    }
}