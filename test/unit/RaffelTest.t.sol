// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffel} from "../../script/DeployRaffel.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {console} from "forge-std/console.sol";

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

    function testCheckUpKeepFalseIfnoBalance() public {
        vm.warp(block.timestamp + intervalinSeconds + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckupReturnFalseIfRaffleISntOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketFee}();
        vm.warp(block.timestamp + intervalinSeconds + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testPerformUpKeepRevertsIfCheckUpKeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffelState rState = raffle.getRaffelState();

        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
        );
        raffle.performUpkeep("");
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketFee}();
        vm.warp(block.timestamp + intervalinSeconds + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsreqId() public raffleEntered {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffelState raffleState = raffle.getRaffelState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    function testFulfillRandomCanOnlyBeCalledAfterPerformUpKeep(uint256 requestId) public raffleEntered {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2).fulfillRandomWords(requestId, address(raffle));
    }

    function testFullfillrandomeWordsPicksAwiinerAndresetandSendMoney() public raffleEntered {
        uint256 startingIndex = 1;
        uint256 aditionalEntries = 5;
        address expectedWinner = address(5);
        for (uint256 i = startingIndex; i < startingIndex + aditionalEntries; i++) {
            address player = address(uint160(i));
            vm.deal(player, 2 ether);
            vm.prank(player);
            raffle.enterRaffle{value: ticketFee}();
        }
        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2).fulfillRandomWords(uint256(requestId), address(raffle));

        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffelState raffleState = raffle.getRaffelState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = ticketFee * (aditionalEntries + 1);
        assert(recentWinner == expectedWinner);

        assert(uint256(raffleState) == 0);
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
