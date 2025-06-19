// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DecentralizedAutonomousOrganization {
    // Struct to represent a proposal
    struct Proposal {
        uint256 id;
        string description;
        uint256 amount;
        address payable recipient;
        uint256 voteCount;
        uint256 deadline;
        bool executed;
        mapping(address => bool) voters;
    }
    
    // State variables
    address public owner;
    uint256 public proposalCount;
    uint256 public memberCount;
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant MIN_VOTES_REQUIRED = 3;
    
    // Mappings
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public members;
    mapping(address => uint256) public memberTokens;
    
    // Events
    event MemberAdded(address member, uint256 tokens);
    event ProposalCreated(uint256 proposalId, string description, uint256 amount, address recipient);
    event VoteCast(uint256 proposalId, address voter);
    event ProposalExecuted(uint256 proposalId, uint256 amount, address recipient);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function");
        _;
    }
    
    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        members[msg.sender] = true;
        memberTokens[msg.sender] = 1;
        memberCount = 1;
    }
    
    // Core Function 1: Add Member
    function addMember(address _member, uint256 _tokens) external onlyOwner {
        require(_member != address(0), "Invalid member address");
        require(!members[_member], "Address is already a member");
        require(_tokens > 0, "Tokens must be greater than 0");
        
        members[_member] = true;
        memberTokens[_member] = _tokens;
        memberCount++;
        
        emit MemberAdded(_member, _tokens);
    }
    
    // Core Function 2: Create Proposal
    function createProposal(
        string memory _description,
        uint256 _amount,
        address payable _recipient
    ) external onlyMember returns (uint256) {
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount <= address(this).balance, "Insufficient contract balance");
        
        proposalCount++;
        
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.description = _description;
        newProposal.amount = _amount;
        newProposal.recipient = _recipient;
        newProposal.voteCount = 0;
        newProposal.deadline = block.timestamp + VOTING_PERIOD;
        newProposal.executed = false;
        
        emit ProposalCreated(proposalCount, _description, _amount, _recipient);
        
        return proposalCount;
    }
    
    // Core Function 3: Vote on Proposal
    function voteOnProposal(uint256 _proposalId) external onlyMember validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!proposal.voters[msg.sender], "You have already voted on this proposal");
        require(!proposal.executed, "Proposal has already been executed");
        
        proposal.voters[msg.sender] = true;
        proposal.voteCount += memberTokens[msg.sender];
        
        emit VoteCast(_proposalId, msg.sender);
        
        // Auto-execute if minimum votes reached
        if (proposal.voteCount >= MIN_VOTES_REQUIRED) {
            executeProposal(_proposalId);
        }
    }
    
    // Internal function to execute proposal
    function executeProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCount >= MIN_VOTES_REQUIRED, "Not enough votes");
        
        proposal.executed = true;
        
        if (proposal.amount > 0) {
            proposal.recipient.transfer(proposal.amount);
        }
        
        emit ProposalExecuted(_proposalId, proposal.amount, proposal.recipient);
    }
    
    // Function to deposit funds to the DAO
    function depositFunds() external payable {
        require(msg.value > 0, "Must send some ETH");
    }
    
    // Function to check if address is a member
    function isMember(address _address) external view returns (bool) {
        return members[_address];
    }
    
    // Function to get proposal details
    function getProposal(uint256 _proposalId) external view validProposal(_proposalId) returns (
        uint256 id,
        string memory description,
        uint256 amount,
        address recipient,
        uint256 voteCount,
        uint256 deadline,
        bool executed
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.description,
            proposal.amount,
            proposal.recipient,
            proposal.voteCount,
            proposal.deadline,
            proposal.executed
        );
    }
    
    // Function to get contract balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Function to check if user has voted on a proposal
    function hasVoted(uint256 _proposalId, address _voter) external view validProposal(_proposalId) returns (bool) {
        return proposals[_proposalId].voters[_voter];
    }
    
    // Fallback function to receive ETH
    receive() external payable {
        // Allow the contract to receive ETH
    }
}
