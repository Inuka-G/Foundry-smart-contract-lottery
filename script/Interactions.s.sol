// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {console} from "forge-std/console.sol";

contract RandomGenSubcription {
    uint256 public s_requestId;
    uint256 public s_subscriptionId;
    IVRFCoordinatorV2Plus s_vrfCoordinator;
    address owner;

    LinkTokenInterface linkToken;

    ////////////////////////
    ///////MODIFIERS////////
    ////////////////////////

    modifier onlyOwner() {
        console.log("onwer", address(owner));
        console.log("msg.sender", msg.sender);
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor(address vrfCoordinatorV2Plus, address link_token_contract) {
        s_vrfCoordinator = IVRFCoordinatorV2Plus(vrfCoordinatorV2Plus);
        linkToken = LinkTokenInterface(link_token_contract);
        //Create a new subscription when you deploy the contract.
        _createNewSubscription();
        owner = msg.sender;
    }

    // Create a new subscription when the contract is initially deployed.
    function _createNewSubscription() private {
        s_subscriptionId = s_vrfCoordinator.createSubscription();
        // Add this contract as a consumer of its own subscription.
        s_vrfCoordinator.addConsumer(s_subscriptionId, address(this));
        console.log("Subscription ID: ", s_subscriptionId);
    }

    // Assumes this contract owns link.
    // 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) external onlyOwner {
        console.log("balance LINK of caller", linkToken.balanceOf(msg.sender));
        console.log("block number ", block.number);
        linkToken.transferAndCall(
            address(s_vrfCoordinator),
            amount,
            abi.encode(s_subscriptionId)
        );
    }

    function addConsumer(address consumerAddress) external {
        // Add a consumer contract to the subscription.
        s_vrfCoordinator.addConsumer(s_subscriptionId, consumerAddress);
    }

    function removeConsumer(address consumerAddress) external {
        // Remove a consumer contract from the subscription.
        s_vrfCoordinator.removeConsumer(s_subscriptionId, consumerAddress);
    }

    function cancelSubscription(address receivingWallet) external {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        s_vrfCoordinator.cancelSubscription(s_subscriptionId, receivingWallet);
        s_subscriptionId = 0;
    }

    // Transfer this contract's funds to an address.
    // 1000000000000000000 = 1 LINK
    function withdraw(uint256 amount, address to) external {
        linkToken.transfer(to, amount);
    }

    //////////////////////////////////////
    ///////GETTER FUNCTIONS///////////////
    //////////////////////////////////////

    function getSubscriptionId() external view returns (uint256) {
        return s_subscriptionId;
    }

    function getRequestId() external view returns (uint256) {
        return s_requestId;
    }
}
