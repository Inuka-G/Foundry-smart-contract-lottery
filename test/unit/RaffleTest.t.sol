// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffel} from "../../script/DeployRaffel.s.sol";
import {Raffle} from "../../src/Raffle.sol";

contract RaffleTest is Test {
    Raffle raffleContract;

    function setUp() public {
        DeployRaffel deployRaffel = new DeployRaffel();
        raffleContract = deployRaffel.run();
        vm.deal(address(5), 9999 ether);
    }

    function testPlayerCountIfOneEnters() public {
        vm.prank(address(5));

        // raffleContract.enterRaffle{value: 0.001 ether}();
        uint256 playerCount = raffleContract.getPlayerCount();

        // assert(playerCount == 1);
    }
}
