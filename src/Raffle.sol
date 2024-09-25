// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

/**
 * @title Raffle contract
 * @author inukaG
 * @notice This contract is the main contract for the Raffle dapp
 * @dev Raffle contract for the Raffle dapp
 *
 */
contract Raffel {
    error Raffel_notEnoughEth();
    uint256 private immutable i_ticketFee;
    uint256 private immutable i_intervalinSeconds;
    uint256 private s_lastTimeStamp;
    address payable[] private s_players; // address array payable
    event RaffelEntered(address indexed player);

    constructor(uint ticketFee, uint256 intervalinSeconds) {
        i_ticketFee = ticketFee;
        i_intervalinSeconds = intervalinSeconds;
        s_lastTimeStamp = block.timestamp;
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
    }

    function getTicketFee() external view returns (uint256) {
        return i_ticketFee;
    }
}
