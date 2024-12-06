// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";

contract DeployRaffel is Script {
    function run() public returns (Raffle raffle) {
        vm.startBroadcast();
        Raffle raffle = new Raffle();
        vm.stopBroadcast();
    }
}
