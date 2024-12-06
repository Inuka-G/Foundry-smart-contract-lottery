// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {RandomGenSubcription} from "./Interactions.s.sol";


contract DeployRaffel is Script {
    uint256 subIdForChainLink;

    function run() external returns (Raffle, HelperConfig) {
        deployContract();
        
       
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        vm.roll(block.number + 1);
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // if (config.subscriptionId == 0) {
        //     RandomGenSubcription randomGenSubcription = new RandomGenSubcription(
        //         config.vrfCoordinatorV2,
        //         config.link
        //     );

        //     randomGenSubcription.topUpSubscription(100 ether);
        //     subIdForChainLink=randomGenSubcription.getSubscriptionId();
        //     console.log("Subscription ID for ChainLink: ", subIdForChainLink);
        // }

        vm.startBroadcast();
        if (block.chainid == 31337) {
            RandomGenSubcription randomGenSubcription = new RandomGenSubcription(
                    config.vrfCoordinatorV2,
                    config.link
                );
        }
        // vm.roll(block.number + 5);

        // randomGenSubcription.topUpSubscription(100);
        // subIdForChainLink = randomGenSubcription.getSubscriptionId();
        console.log("Subscription ID for ChainLink: ", subIdForChainLink);

        Raffle raffel = new Raffle(
            config.ticketFee,
            config.intervalinSeconds,
            config.vrfCoordinatorV2,
            config.subscriptionId,
            config.gasLane,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
vm.warp(block.timestamp + (100 * 3)); 
        return (raffel, helperConfig);
    }
}


