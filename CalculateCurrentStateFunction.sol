// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ProposalContract {

    address owner;

    uint256 private counter; // Counter    


    struct Proposal {
        string title; // Title of the proposal
        string description; // Description of the proposal
        uint256 approve; // Number of approve votes
        uint256 reject; // Number of reject votes
        uint256 pass; // Number of pass votes
        uint256 total_vote_to_end; // When the total votes in the proposal reaches this limit, proposal ends
        bool current_state; // This shows the current state of the proposal, meaning whether if passes of fails
        bool is_active; // This shows if others can vote to our contract
    }

    mapping(uint256 => Proposal) proposal_history; // Recordings of previous proposals

    address[]  private voted_addresses;

        constructor() {
        owner = msg.sender;
        voted_addresses.push(msg.sender);
    } 

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier active() {
        require(proposal_history[counter].is_active == true, "The proposal is not active");
        _;
    }

    modifier newVoter(address _address) {
        require(!isVoted(_address), "Address has already voted");
        _;
    }

    function setOwner(address new_owner) external onlyOwner {
        owner = new_owner;
    }   
    
    function create(string calldata _title, string calldata _description, uint256 _total_vote_to_end) external
        onlyOwner {
            counter += 1;
            proposal_history[counter] = Proposal(_title, _description, 0, 0, 0, _total_vote_to_end, false, true);
    }

    function vote(uint8 choice) external active newVoter(msg.sender){
        // First part
        Proposal storage proposal = proposal_history[counter];
        uint256 total_vote = proposal.approve + proposal.reject + proposal.pass;

        voted_addresses.push(msg.sender);
    
        // Second part
        if (choice == 1) {
            proposal.approve += 1;
            proposal.current_state = calculateCurrentState();
        } else if (choice == 2) {
            proposal.reject += 1;
            proposal.current_state = calculateCurrentState();
        } else if (choice == 0) {
            proposal.pass += 1;
            proposal.current_state = calculateCurrentState();
        }
    
        // Third part
        if ((proposal.total_vote_to_end - total_vote == 1) && (choice == 1 || choice == 2 || choice == 0)) {
            proposal.is_active = false;
            voted_addresses = [owner];
        }
    }

    function calculateCurrentState() private view returns (bool) {
        Proposal storage proposal = proposal_history[counter];

        uint256 approve = proposal.approve;
        uint256 reject = proposal.reject;
        uint256 pass = proposal.pass;

        uint256 totalVotes = approve + reject + pass;

        // Adjust the total vote count to be divisible by 3
        if (totalVotes % 3 == 1) {
            pass += 2;
        } else if (totalVotes % 3 == 2) {
            pass += 1;
        }

        totalVotes = approve + reject + pass;

        // Approval requires the approve count to be at least 2/3 of the total votes
        if (approve * 3 >= totalVotes * 2) {
            return true;
        } else {
            return false;
        }
    }
}
