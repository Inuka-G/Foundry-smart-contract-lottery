// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle contract
 * @author inukaG
 * @notice This contract is the main contract for the Raffle dapp
 * @dev Raffle contract for the Raffle dapp
 *
 */
contract Raffel is VRFConsumerBaseV2Plus {
    error Raffel_notEnoughEth();
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_ticketFee;
    uint256 private immutable i_intervalinSeconds;

    uint256 private s_lastTimeStamp;
    address payable[] private s_players; // address array payable
    event RaffelEntered(address indexed player);

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
    }

    function enterRaffle() external payable {
        if (msg.value < i_ticketFee) {
            revert Raffel_notEnoughEth();
        }
        s_players.push(payable(msg.sender));
        emit RaffelEntered(msg.sender);
    }

    function pickWinner() external {
        if ((block.timestamp - s_lastTimeStamp) < i_intervalinSeconds) {
            revert();
        }
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
    ) internal virtual override {}
}
