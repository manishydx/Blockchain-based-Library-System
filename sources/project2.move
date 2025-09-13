module 0x1::SimpleVoting {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::vector;

    /// Struct representing a voting proposal
    struct Proposal has store, key {
        title: vector<u8>,     // Title of the proposal
        yes_votes: u64,        // Number of yes votes
        no_votes: u64,         // Number of no votes
        voting_cost: u64,      // Cost per vote in tokens
        total_funds: u64,      // Total funds collected from voting
    }

    /// Struct to track if an address has voted
    struct VoteRecord has store, key {
        voted_addresses: vector<address>,
    }

    /// Function to create a new voting proposal
    public fun create_proposal(
        creator: &signer, 
        title: vector<u8>, 
        voting_cost: u64
    ) {
        let proposal = Proposal {
            title,
            yes_votes: 0,
            no_votes: 0,
            voting_cost,
            total_funds: 0,
        };
        
        let vote_record = VoteRecord {
            voted_addresses: vector::empty<address>(),
        };
        
        move_to(creator, proposal);
        move_to(creator, vote_record);
    }

    /// Function for users to cast their vote by paying tokens
    public fun cast_vote(
        voter: &signer, 
        proposal_owner: address, 
        vote_yes: bool
    ) acquires Proposal, VoteRecord {
        let voter_addr = signer::address_of(voter);
        let proposal = borrow_global_mut<Proposal>(proposal_owner);
        let vote_record = borrow_global_mut<VoteRecord>(proposal_owner);
        
        // Check if voter has already voted
        assert!(!vector::contains(&vote_record.voted_addresses, &voter_addr), 1);
        
        // Collect voting fee
        let payment = coin::withdraw<AptosCoin>(voter, proposal.voting_cost);
        coin::deposit<AptosCoin>(proposal_owner, payment);
        
        // Record the vote
        if (vote_yes) {
            proposal.yes_votes = proposal.yes_votes + 1;
        } else {
            proposal.no_votes = proposal.no_votes + 1;
        };
        
        // Mark voter as having voted
        vector::push_back(&mut vote_record.voted_addresses, voter_addr);
        proposal.total_funds = proposal.total_funds + proposal.voting_cost;
    }
}