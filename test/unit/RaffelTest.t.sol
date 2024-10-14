// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffel} from "../../script/DeployRaffel.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffelTest is Test {
    event RaffelEntered(address indexed player);
    event RaffelWinner(address indexed winner);
    Raffle public raffle;
    HelperConfig public helperConfig;
    uint256 ticketFee;
    uint256 intervalinSeconds;
    address vrfCoordinatorV2;
    uint256 subscriptionId;
    bytes32 gasLane; // keyHash
    uint32 callbackGasLimit;
    address public PLAYER = makeAddr("player");

    function setUp() external {
        DeployRaffel deployer = new DeployRaffel();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        ticketFee = config.ticketFee;
        intervalinSeconds = config.intervalinSeconds;
        vrfCoordinatorV2 = config.vrfCoordinatorV2;
        subscriptionId = config.subscriptionId;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        vm.deal(PLAYER, 10 ether);
    }

    function testRaffleInializesInOpenState() public view {
        assert(raffle.getRaffelState() == Raffle.RaffelState.OPEN);
    }

    function testRaffleRevertWhenYouDontPAyEnoughEth() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffel_notEnoughEth.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: ticketFee}();
        // Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        // Arrange
        vm.prank(PLAYER);

        // Act / Assert
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffelEntered(PLAYER);
        raffle.enterRaffle{value: ticketFee}();
    }
        function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketFee}();
        vm.warp(block.timestamp + intervalinSeconds + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Act / Assert
        vm.expectRevert(Raffle.Raffel_notOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketFee}();
    }
}
