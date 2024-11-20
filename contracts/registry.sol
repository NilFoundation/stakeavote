// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./poll.sol";

contract Register {
    struct PollInfo {
        address pollAddress;
        string title;
        // bool isActive;
    }

    // mapping(address => bool) public isRegistered;
    PollInfo[] public polls;

    // event UserRegistered(address user);
    event PollCreated(address pollAddress, string title);

    // Register a new user (placeholder, currently non-functional)
    // function registerUser() external {
        // require(!isRegistered[msg.sender], "User already registered");
        // isRegistered[msg.sender] = true;
        // emit UserRegistered(msg.sender);
    // }

    // Create a new poll
    function createPoll(
        string calldata title,
        string calldata description,
        string[] calldata options,
        uint256 votingDeadline,
        uint256 minBetAmount
    ) external returns (address pollAddress) {
        require(options.length > 1, "At least two options required");
        require(votingDeadline > block.timestamp, "Invalid voting deadline");

        // Deploy a new poll contract, upadate for the nil's
        Poll poll = new Poll(msg.sender, title, description, options, votingDeadline, minBetAmount);
        pollAddress = address(poll);
        polls.push(PollInfo(pollAddress, title, true));

        emit PollCreated(pollAddress, title);
    }

    // Get all polls
    function getAllPolls() external view returns (PollInfo[] memory) {
        return polls;
    }
}