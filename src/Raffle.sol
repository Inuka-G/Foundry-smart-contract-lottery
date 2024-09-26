// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle contract
 * @author inukaG (onbehalf of AxionChainLabs)
 * @notice This contract is the main contract for the Raffle DApp
 * @dev Raffle contract for the Raffle dapp
 *
 */
contract Raffel is VRFConsumerBaseV2Plus {
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );
    error Raffel_notEnoughEth();
    error Raffel_NotTransfered();
    error Raffel_notOpen();
    enum RaffelState {
        OPEN,
        CALCULATING
    }
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_ticketFee;
    uint256 private immutable i_intervalinSeconds;

    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffelState private s_raffelState;
    address payable[] private s_players; // address array payable
    event RaffelEntered(address indexed player);
    event RaffelWinner(address indexed winner);

    constructor(
        uint256 ticketFee,
        uint256 intervalinSeconds,
        address vrfCoordinatorV2,
        uint256 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        i_intervalinSeconds = intervalinSeconds;
        i_ticketFee = ticketFee;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;

        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
        s_raffelState = RaffelState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_ticketFee) {
            revert Raffel_notEnoughEth();
        }
        if (s_raffelState != RaffelState.OPEN) {
            revert Raffel_notOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffelEntered(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = RaffelState.OPEN == s_raffelState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >
            i_intervalinSeconds);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */

    // pickwinner func rename to performUpkeep

    // function pickWinner() external {
    //     if ((block.timestamp - s_lastTimeStamp) < i_intervalinSeconds) {
    //         revert();
    //     }
    //     s_raffelState = RaffelState.CALCULATING;
    //     uint256 requestId = s_vrfCoordinator.requestRandomWords(
    //         VRFV2PlusClient.RandomWordsRequest({
    //             keyHash: i_gasLane,
    //             subId: i_subscriptionId,
    //             requestConfirmations: REQUEST_CONFIRMATIONS,
    //             callbackGasLimit: i_callbackGasLimit,
    //             numWords: NUM_WORDS,
    //             extraArgs: VRFV2PlusClient._argsToBytes(
    //                 VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
    //             )
    //         })
    //     );
    // }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffelState)
            );
        }
        s_raffelState = RaffelState.CALCULATING;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function getTicketFee() external view returns (uint256) {
        return i_ticketFee;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal virtual override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_recentWinner = winner;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        s_raffelState = RaffelState.OPEN;

        emit RaffelWinner(winner); //cei check effects interactions
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffel_NotTransfered();
        }
    }
}
