// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract SimulateGame is Script{
    function run()public{
        address contractAddress=DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        console.log("Raffle Contract Address: ", contractAddress);
    }



}
