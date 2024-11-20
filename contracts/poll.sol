// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Poll {
    enum PollState { Active, Finalized }
    PollState public state;

    address public owner;
    string public title;
    string public description;
    bytes32[] public options;
    uint256 public votingDeadlineBlock;
    uint256 public minBetAmount;
    bytes32 public winningOption;
    uint256 public totalBetPool;

    mapping(address => bytes32) public voteCommits;
    mapping(address => bytes32) public revealedVotes;
    mapping(address => bytes32) public betCommits;
    mapping(address => uint256) public lockedBetAmounts;
    mapping(bytes32 => uint256) public optionVoteCounts;
    mapping(bytes32 => uint256) public optionBetPools;

    event VoteCommitted(address voter);
    event VoteRevealed(address voter, bytes32 option);
    event BetCommitted(address bettor, uint256 amount);
    event BetRevealed(address bettor, bytes32 option, uint256 amount);
    event PollFinalized(bytes32 winningOption);
    event RewardClaimed(address claimer, uint256 amount);

    constructor(
        address _owner,
        string memory _title,
        string memory _description,
        bytes32[] memory _options,
        uint256 _votingDeadlineBlock,
        uint256 _minBetAmount
    ) {
        require(_options.length > 1, "Must have at least two options");
        owner = _owner;
        title = _title;
        description = _description;
        options = _options;
        votingDeadlineBlock = _votingDeadlineBlock;
        minBetAmount = _minBetAmount;
        state = PollState.Active;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier inState(PollState _state) {
        require(state == _state, "Invalid poll state");
        _;
    }

    modifier beforeDeadline() {
        require(block.number <= votingDeadlineBlock, "Voting deadline passed");
        _;
    }

    modifier afterDeadline() {
        require(block.number > votingDeadlineBlock, "Voting period not over");
        _;
    }

    function vote(bytes32 _commit) external beforeDeadline {
        require(voteCommits[msg.sender] == bytes32(0), "Already voted");
        voteCommits[msg.sender] = _commit;
        emit VoteCommitted(msg.sender);
    }
function revealVote(bytes32 _vote, bytes32 _salt) external afterDeadline {
        require(voteCommits[msg.sender] != bytes32(0), "No vote committed");
        require(revealedVotes[msg.sender] == bytes32(0), "Already revealed");

        bytes32 hash = keccak256(abi.encodePacked(_vote, _salt));
        require(voteCommits[msg.sender] == hash, "Invalid reveal");

        revealedVotes[msg.sender] = _vote;
        optionVoteCounts[_vote] += 1; // Count vote for the revealed option
        emit VoteRevealed(msg.sender, _vote);
    }

    function bet(bytes32 _commit) external payable beforeDeadline {
        require(msg.value >= minBetAmount, "Bet amount too low");
        require(betCommits[msg.sender] == bytes32(0), "Already bet");

        betCommits[msg.sender] = _commit;
        lockedBetAmounts[msg.sender] = msg.value; // Lock bet amount
        emit BetCommitted(msg.sender, msg.value);
    }

    function revealBet(bytes32 _bet, bytes32 _salt) external afterDeadline {
        require(betCommits[msg.sender] != bytes32(0), "No bet committed");

        bytes32 hash = keccak256(abi.encodePacked(_bet, _salt));
        require(betCommits[msg.sender] == hash, "Invalid reveal");

        optionBetPools[_bet] += lockedBetAmounts[msg.sender]; // Add to the pool of the revealed option
        emit BetRevealed(msg.sender, _bet, lockedBetAmounts[msg.sender]);
    }

    function finalizeVoting() external afterDeadline inState(PollState.Active) {
        // Determine the winning option
        bytes32 currentWinningOption;
        uint256 maxVotes = 0;

        for (uint256 i = 0; i < options.length; i++) {
            bytes32 option = options[i];
            totalBetPool += optionBetPools[option];
            if (optionVoteCounts[option] > maxVotes) {
                maxVotes = optionVoteCounts[option];
                currentWinningOption = option;
            }
        }

        winningOption = currentWinningOption;
        state = PollState.Finalized;

        emit PollFinalized(winningOption);
    }

    function claimReward() external inState(PollState.Finalized) {
        uint256 userBet = lockedBetAmounts[msg.sender];
        require(userBet > 0, "No bet to claim");
        lockedBetAmounts[msg.sender] = 0;

        bytes32 userBetOption = revealedVotes[msg.sender];
        require(userBetOption == winningOption, "Incorrect bet");

        // Calculate reward
        uint256 reward = (userBet * totalBetPool) / optionVoteCounts[winningOption];


        // TODO: send reward to the user
        // (bool success, ) = msg.sender.call{value: reward}("");
        // require(success, "Reward transfer failed");

        emit RewardClaimed(msg.sender, reward);
    }
}