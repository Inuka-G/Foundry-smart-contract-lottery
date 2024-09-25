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
    uint256 private immutable i_ticketFee;

    constructor(uint ticketFee) {
        i_ticketFee = ticketFee;
    }

    function enterRaffle() public payable {}
    function pickWinner() public {}
    function getTicketFee() external view returns (uint256) {
        return i_ticketFee;
    }   
}
