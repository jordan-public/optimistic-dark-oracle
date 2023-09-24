// The 'dorcl' program.
program dorcl.aleo {
    // The following part is built on the pattern of secret voting,
    // however it is modified to be suitable for UMA-like assertions,
    // which have deadlines for dispute and dispute resolution.

    // Assertion details
    struct AssertionDetails {
        title: field,
        contentHash: field,
        asserter: address,
        asserterDeposit: u64, // assuming disputer deposit is the same
        voterFee: u64,
        disputeDeadlineBlockHeight: u32,
        votingDeadlineBlockHeight: u32,
    }

    // Proposal record records proposal info publicly
    record Assertion {
        owner: address,
        id: field,
        details: AssertionDetails,
    }

    // Save all assertions' info publicly.
    mapping assertions: field => AssertionDetails; // assertionId => AssertionDetails

    // Deposits to vote (private)
    record VotingRight {
        owner: address,
        assertionId: field,
    }

    // For reward distribution
    record VotingReceipt {
        owner: address,
        assertionId: field,
        outcome: bool,
    }

    mapping disputers: field => address; // assertionId => disputerAddress

    mapping confirm_votes: field => u64; // assertionId => confirming votes

    mapping dispute_votes: field => u64; // assertionId => disputing votes

    // Propose a new proposal to vote on.
    transition createAssertion(public details: AssertionDetails) -> Assertion {
        // Authenticate asserter
        assert_eq(self.caller, details.asserter);

        // Generate a new proposal id.
        let id: field = BHP256::hash_to_field(details.contentHash);

        // Return the newly created assertion
        // Finalize the proposal id.
        return Assertion {
            owner: self.caller,
            id,
            details,
        } then finalize(self.caller, details.asserterDeposit, id);
    }
    // Create a new assertionId
    finalize createAssertion(sender: address, fee: u64, public id: field) {
        //burn_public(fee);
        let sender_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
        Mapping::set(account, sender, sender_amount - fee); // Non wrapping - can fail if underfunded
        //
        Mapping::set(confirm_votes, id, 0u64); // no confirmations yet
        Mapping::set(dispute_votes, id, 0u64); // no disputes yer
    }

    transition disputeAssertion(fee: u64, assertionId: field) {
        return then finalize(self.caller, fee, assertionId);
    }
    finalize disputeAssertion(sender: address, fee: u64, assertionId: field) {
        //burn_public(fee);
        let sender_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
        Mapping::set(account, sender, sender_amount - fee); // Non wrapping - can fail if underfunded
        //
        let assertionParts: AssertionDetails = Mapping::get(assertions, assertionId);
        assert(assertionParts.disputeDeadlineBlockHeight <= block.height);
        let d: address = Mapping::get_or_use(disputers, assertionId, 0u64 as address);
        assert(d == 0u64 as address);
        Mapping::set(disputers, assertionId, sender);
    }

    // Create a new ticket to vote with.
    transition new_voting_right(
        sender: token,
        fee: u64,
        assertionId: field,
    ) -> (VotingRight, token) {

        // Pay for the right
        // burn_private(fee);
        let difference: u64 = sender.amount - fee;
        // Produce a token record with the change amount for the sender.
        let remaining: token = token {
            owner: sender.owner,
            amount: difference,
        };
        //

        // Finalize the proposal id for the ticket.
        return (VotingRight {
            owner: sender.owner,
            assertionId,
        }, remaining) then finalize(fee, assertionId);
    }
    finalize new_voting_right(fee: u64, assertionId: field) {
        let assertionParts: AssertionDetails = Mapping::get(assertions, assertionId);
        assert_eq(fee, assertionParts.voterFee);
    }

    // Vote privately to agree with a proposal.
    transition confirm(v: VotingRight) -> VotingReceipt {
        // Finalize this vote
        return VotingReceipt { owner: self.caller, assertionId: v.assertionId, outcome: true } then finalize(v.assertionId);
    }
    finalize confirm(assertionId: field) {
        let assertionParts: AssertionDetails = Mapping::get(assertions, assertionId);
        assert(assertionParts.votingDeadlineBlockHeight <= block.height);
        // Publicly increment the number of agree votes.
        let current: u64 = Mapping::get_or_use(confirm_votes, assertionId, 0u64);
        Mapping::set(confirm_votes, assertionId, current + 1u64);
    }

    // Vote privately to disagree with a proposal.
    transition deny(v: VotingRight) -> VotingReceipt {
        // Finalize this vote.
        return VotingReceipt { owner: self.caller, assertionId: v.assertionId, outcome: false } then finalize(v.assertionId);
    }
    finalize deny(assertionId: field) {
        let assertionParts: AssertionDetails = Mapping::get(assertions, assertionId);
        assert(assertionParts.votingDeadlineBlockHeight <= block.height);
        // Publicly increment the number of disagree votes.
        let current: u64 = Mapping::get_or_use(dispute_votes, assertionId, 0u64);
        Mapping::set(dispute_votes, assertionId, current + 1u64);
    }

    transition collectVotingAward(award: u64, r: VotingReceipt) -> token {
        assert(self.caller == r.owner);
        return token {
                owner: self.caller,
                amount: award,
            } then finalize(award, r.assertionId, r.outcome);
    }
    finalize collectVotingAward(award: u64, assertionId: field, outcome: bool) {
        let assertionParts: AssertionDetails = Mapping::get(assertions, assertionId);
        assert(assertionParts.votingDeadlineBlockHeight > block.height);
        let y: u64 = Mapping::get_or_use(confirm_votes, assertionId, 0u64);
        let n: u64 = Mapping::get_or_use(dispute_votes, assertionId, 0u64);
        assert(outcome ? y > n : y <=n); // Otherwise revert
        assert(award == assertionParts.voterFee);
    }

// Token
    // On-chain storage of an `account` map, with `address` as the key,
    // and `u64` as the value.
    mapping account: address => u64;

    record token {
        // The token owner.
        owner: address,
        // The token amount.
        amount: u64,
    }

    // The code below based on the token sample, with token burning added.
    // The only reason it is inside, is so that the transfer functions
    // for incentivization and penalties are in the same program.

    /* Burn */

    transition burn_public(public amount: u64) {
        return then finalize(self.caller, amount);
    }
    finalize burn_public(public sender: address, public amount: u64) {
        // Decrements `account[sender]` by `amount`.
        // If `account[sender]` does not exist, it will be created.
        // If `account[sender] - amount` underflows, `transfer_public` is reverted.
        let sender_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
        Mapping::set(account, sender, sender_amount - amount);
    }

    transition burn_private(sender: token, amount: u64) -> (token) {
        // Checks the given token record has sufficient balance.
        // This `sub` operation is safe, and the proof will fail if an overflow occurs.
        // `difference` holds the change amount to be returned to sender.
        let difference: u64 = sender.amount - amount;

        // Produce a token record with the change amount for the sender.
        let remaining: token = token {
            owner: sender.owner,
            amount: difference,
        };

        // Output the sender's change record and the receiver's record.
        return (remaining);
    }

    /* Mint */

    // The function `mint_public` issues the specified token amount for the token receiver publicly on the network.
    transition mint_public(public receiver: address, public amount: u64) {
        // Mint the tokens publicly by invoking the computation on-chain.
        return then finalize(receiver, amount);
    }

    finalize mint_public(public receiver: address, public amount: u64) {
        // Increments `account[receiver]` by `amount`.
        // If `account[receiver]` does not exist, it will be created.
        // If `account[receiver] + amount` overflows, `mint_public` is reverted.
        let receiver_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, receiver_amount + amount);
    }

    // The function `mint_private` initializes a new record with the specified amount of tokens for the receiver.
    transition mint_private(receiver: address, amount: u64) -> token {
        return token {
            owner: receiver,
            amount: amount,
        };
    }

    /* Transfer */
    transition transfer_public(public receiver: address, public amount: u64) {
        // Transfer the tokens publicly, by invoking the computation on-chain.
        return then finalize(self.caller, receiver, amount);
    }

    finalize transfer_public(public sender: address, public receiver: address, public amount: u64) {
        // Decrements `account[sender]` by `amount`.
        // If `account[sender]` does not exist, it will be created.
        // If `account[sender] - amount` underflows, `transfer_public` is reverted.
        let sender_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
        Mapping::set(account, sender, sender_amount - amount);
        
        // Increments `account[receiver]` by `amount`.
        // If `account[receiver]` does not exist, it will be created.
        // If `account[receiver] + amount` overflows, `transfer_public` is reverted.
        let receiver_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, receiver_amount + amount);
    }

    // The function `transfer_private` sends the specified token amount to the token receiver from the specified token record.
    transition transfer_private(sender: token, receiver: address, amount: u64) -> (token, token) {
        // Checks the given token record has sufficient balance.
        // This `sub` operation is safe, and the proof will fail if an overflow occurs.
        // `difference` holds the change amount to be returned to sender.
        let difference: u64 = sender.amount - amount;

        // Produce a token record with the change amount for the sender.
        let remaining: token = token {
            owner: sender.owner,
            amount: difference,
        };

        // Produce a token record for the specified receiver.
        let transferred: token = token {
            owner: receiver,
            amount: amount,
        };

        // Output the sender's change record and the receiver's record.
        return (remaining, transferred);
    }

    // The function `transfer_private_to_public` turns a specified token amount from a token record into public tokens for the specified receiver.
    // This function preserves privacy for the sender's record, however it publicly reveals the token receiver and the token amount.
    transition transfer_private_to_public(sender: token, public receiver: address, public amount: u64) -> token {
        // Checks the given token record has a sufficient token amount.
        // This `sub` operation is safe, and the proof will fail if an underflow occurs.
        // `difference` holds the change amount for the caller.
        let difference: u64 = sender.amount - amount;

        // Produces a token record with the change amount for the caller.
        let remaining: token = token {
            owner: sender.owner,
            amount: difference,
        };

        // Output the sender's change record.
        // Increment the token amount publicly for the token receiver.
        return remaining then finalize(receiver, amount);
    }

    finalize transfer_private_to_public(public receiver: address, public amount: u64) {
        // Increments `account[receiver]` by `amount`.
        // If `account[receiver]` does not exist, it will be created.
        // If `account[receiver] + amount` overflows, `transfer_private_to_public` is reverted.
        let receiver_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, receiver_amount + amount);
    }

    // The function `transfer_public_to_private` turns a specified token amount from `account` into a token record for the specified receiver.
    // This function preserves privacy for the receiver's record, however it publicly reveals the caller and the specified token amount.
    transition transfer_public_to_private(public receiver: address, public amount: u64) -> token {
        // Produces a token record for the token receiver.
        let transferred: token = token {
            owner: receiver,
            amount: amount,
        };

        // Output the receiver's record.
        // Decrement the token amount of the caller publicly.
        return transferred then finalize(self.caller, amount);
    }

    finalize transfer_public_to_private(public sender: address, public amount: u64) {
        // Decrements `account[sender]` by `amount`.
        // If `account[sender]` does not exist, it will be created.
        // If `account[sender] - amount` underflows, `transfer_public_to_private` is reverted.
        let sender_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
        Mapping::set(account, sender, sender_amount - amount);
    }
}