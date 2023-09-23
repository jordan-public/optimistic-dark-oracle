program dorcl.aleo;

struct AssertionDetails:
    title as field;
    contentHash as field;
    asserter as address;
    asserterDeposit as u64;
    voterFee as u64;
    disputeDeadlineBlockHeight as u32;
    votingDeadlineBlockHeight as u32;

record Assertion:
    owner as address.private;
    id as field.private;
    details as AssertionDetails.private;

record VotingRight:
    owner as address.private;
    assertionId as field.private;

record token:
    owner as address.private;
    amount as u64.private;


mapping assertions:
	key left as field.public;
	value right as AssertionDetails.public;


mapping disputers:
	key left as field.public;
	value right as address.public;


mapping confirm_votes:
	key left as field.public;
	value right as u64.public;


mapping dispute_votes:
	key left as field.public;
	value right as u64.public;


mapping account:
	key left as address.public;
	value right as u64.public;

function createAssertion:
    input r0 as AssertionDetails.public;
    assert.eq self.caller r0.asserter;
    hash.bhp256 r0.contentHash into r1 as field;
    cast self.caller r1 r0 into r2 as Assertion.record;
    output r2 as Assertion.record;

    finalize self.caller r0.asserterDeposit r1;

finalize createAssertion:
    input r0 as address.public;
    input r1 as u64.public;
    input r2 as field.public;
    get.or_use account[r0] 0u64 into r3;
    sub r3 r1 into r4;
    set r4 into account[r0];
    set 0u64 into confirm_votes[r2];
    set 0u64 into dispute_votes[r2];


function disputeAssertion:
    input r0 as u64.private;
    input r1 as field.private;

    finalize self.caller r0 r1;

finalize disputeAssertion:
    input r0 as address.public;
    input r1 as u64.public;
    input r2 as field.public;
    get.or_use account[r0] 0u64 into r3;
    sub r3 r1 into r4;
    set r4 into account[r0];
    get assertions[r2] into r5;
    lte r5.disputeDeadlineBlockHeight block.height into r6;
    assert.eq r6 true;
    cast 0u64 into r7 as address;
    get.or_use disputers[r2] r7 into r8;
    cast 0u64 into r9 as address;
    is.eq r8 r9 into r10;
    assert.eq r10 true;
    set r0 into disputers[r2];


function new_voting_right:
    input r0 as token.record;
    input r1 as u64.private;
    input r2 as field.private;
    sub r0.amount r1 into r3;
    cast r0.owner r3 into r4 as token.record;
    cast r0.owner r2 into r5 as VotingRight.record;
    output r5 as VotingRight.record;
    output r4 as token.record;

    finalize r1 r2;

finalize new_voting_right:
    input r0 as u64.public;
    input r1 as field.public;
    get assertions[r1] into r2;
    assert.eq r0 r2.voterFee;


function confirm:
    input r0 as VotingRight.record;

    finalize r0.assertionId;

finalize confirm:
    input r0 as field.public;
    get assertions[r0] into r1;
    lte r1.votingDeadlineBlockHeight block.height into r2;
    assert.eq r2 true;
    get.or_use confirm_votes[r0] 0u64 into r3;
    add r3 1u64 into r4;
    set r4 into confirm_votes[r0];


function deny:
    input r0 as VotingRight.record;

    finalize r0.assertionId;

finalize deny:
    input r0 as field.public;
    get assertions[r0] into r1;
    lte r1.votingDeadlineBlockHeight block.height into r2;
    assert.eq r2 true;
    get.or_use dispute_votes[r0] 0u64 into r3;
    add r3 1u64 into r4;
    set r4 into dispute_votes[r0];


function burn_public:
    input r0 as u64.public;

    finalize self.caller r0;

finalize burn_public:
    input r0 as address.public;
    input r1 as u64.public;
    get.or_use account[r0] 0u64 into r2;
    sub r2 r1 into r3;
    set r3 into account[r0];


function burn_private:
    input r0 as token.record;
    input r1 as u64.private;
    sub r0.amount r1 into r2;
    cast r0.owner r2 into r3 as token.record;
    output r3 as token.record;


function mint_public:
    input r0 as address.public;
    input r1 as u64.public;

    finalize r0 r1;

finalize mint_public:
    input r0 as address.public;
    input r1 as u64.public;
    get.or_use account[r0] 0u64 into r2;
    add r2 r1 into r3;
    set r3 into account[r0];


function mint_private:
    input r0 as address.private;
    input r1 as u64.private;
    cast r0 r1 into r2 as token.record;
    output r2 as token.record;


function transfer_public:
    input r0 as address.public;
    input r1 as u64.public;

    finalize self.caller r0 r1;

finalize transfer_public:
    input r0 as address.public;
    input r1 as address.public;
    input r2 as u64.public;
    get.or_use account[r0] 0u64 into r3;
    sub r3 r2 into r4;
    set r4 into account[r0];
    get.or_use account[r1] 0u64 into r5;
    add r5 r2 into r6;
    set r6 into account[r1];


function transfer_private:
    input r0 as token.record;
    input r1 as address.private;
    input r2 as u64.private;
    sub r0.amount r2 into r3;
    cast r0.owner r3 into r4 as token.record;
    cast r1 r2 into r5 as token.record;
    output r4 as token.record;
    output r5 as token.record;


function transfer_private_to_public:
    input r0 as token.record;
    input r1 as address.public;
    input r2 as u64.public;
    sub r0.amount r2 into r3;
    cast r0.owner r3 into r4 as token.record;
    output r4 as token.record;

    finalize r1 r2;

finalize transfer_private_to_public:
    input r0 as address.public;
    input r1 as u64.public;
    get.or_use account[r0] 0u64 into r2;
    add r2 r1 into r3;
    set r3 into account[r0];


function transfer_public_to_private:
    input r0 as address.public;
    input r1 as u64.public;
    cast r0 r1 into r2 as token.record;
    output r2 as token.record;

    finalize self.caller r1;

finalize transfer_public_to_private:
    input r0 as address.public;
    input r1 as u64.public;
    get.or_use account[r0] 0u64 into r2;
    sub r2 r1 into r3;
    set r3 into account[r0];
