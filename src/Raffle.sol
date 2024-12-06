// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

/**
 * @title Raffle contract
 * @author inukaG (onbehalf of AxionChainLabs)
 * @notice This contract is the main contract for the Raffle DApp
 * @dev Raffle contract for the Raffle dapp
 *
 */
contract Raffle {
    ////////////////////////////
    ////// STATE VARIABLES ////
    ////////////////////////////

    enum RaffelState {
        OPEN,
        CALCULATING
    }

    uint256 private i_intervalinSeconds;
    uint256 private i_ticketFee;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffelState private s_raffelState;
    address payable[] private s_players; // address array payable

    event RaffelEntered(address indexed player);
    event RaffelWinner(address indexed winner);

    error Raffle__PickWinnerNotNeeded(uint256 balance, uint256 length, uint256 state);
    error Raffel_notEnoughEth();
    error Raffel_notOpen();
    error Raffel_NotTransfered();

    constructor() {
        i_intervalinSeconds = 30;
        i_ticketFee = 0.001 ether;
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
    function checkRaffle() public view returns (bool upkeepNeeded) {
        bool isOpen = RaffelState.OPEN == s_raffelState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_intervalinSeconds);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded); // can we comment this out?
    }

    function pickWinner() external {
        // since func is external validation implemented
        bool checkGame = checkRaffle();
        if (!checkGame) {
            revert Raffle__PickWinnerNotNeeded(address(this).balance, s_players.length, uint256(s_raffelState));
        }
        s_raffelState = RaffelState.CALCULATING;
        uint256 winnerIndex = 9 % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_recentWinner = winner;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        s_raffelState = RaffelState.OPEN;

        emit RaffelWinner(winner); //cei check effects interactions
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffel_NotTransfered();
        }
    }

    ////////////////////////////
    /////// GETTER FUNCTIONS ////
    ////////////////////////////

    function getRaffelState() external view returns (RaffelState) {
        return s_raffelState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getTicketFee() external view returns (uint256) {
        return i_ticketFee;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getPlayerCount() external view returns (uint256) {
        return s_players.length;
    }
}
