// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    uint256 public constant SEPOLIA_ETH_CHAIN_ID = 11155111;
    uint256 public constant MAIN_NET_ETH_CHAIN_ID = 1;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_ETH_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD priceFeed address
    }

    constructor() {
        if (block.chainid == SEPOLIA_ETH_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == MAIN_NET_ETH_CHAIN_ID) {
            activeNetworkConfig = getMainNetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaEthConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaEthConfig;
    }

    function getMainNetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainNetEthConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainNetEthConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator priceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_ETH_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(priceFeed)
        });

        return anvilConfig;
    }
}
