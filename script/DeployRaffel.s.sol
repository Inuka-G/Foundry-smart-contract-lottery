// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.s.sol";

contract DeployRaffel is Script {
    function run() external {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
           (config.subscriptionId,config.vrfCoordinatorV2)= createSubscription.createSubscription(config.vrfCoordinatorV2);
        }

        vm.startBroadcast();
        Raffle raffel = new Raffle(
            config.ticketFee,
            config.intervalinSeconds,
            config.vrfCoordinatorV2,
            config.subscriptionId,
            config.gasLane,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
        return (raffel, helperConfig);
    }
}
