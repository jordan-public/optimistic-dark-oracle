# Video

Download video [here](./Dark%20Optimistic%20Oracle%20-%20HD%201080p.mov) or see on YouTube [here](https://youtu.be/Oaw0wOiqXZg).

# How to run it

## Deployment

The code can be run on-chain after deploying using the following command from the main menu:
```
./deploy.sh
```

However, to prepare the script proper address, private key and record has to be entered correctly in ```deploy.sh```, as instructed in the Aleo samples.

## Local execution

Each function call has to contain proper parameters entered in ```inputs/dorcl.in```. The output from one command contains values which have to be copied in the input for the next command. For example, with parameters:
```
[createAssertion]
details: AssertionDetails = AssertionDetails {
    title:  0field,
    contentHash: 0field,
    asserter: aleo18jtgsuuu3rluye2tnevugl662nzhw7pw8tcmfrvss25mw36apvrsu97lyx,
    asserterDeposit: 10u64,
    voterFee: 1u64,
    disputeDeadlineBlockHeight: 0u32,
    votingDeadlineBlockHeight: 1000u32,
};

```
the following command outputs:
```
jordan@p21 dorcl % leo run createAssertion
       Leo ✅ Compiled 'main.leo' into Aleo instructions

⛓  Constraints

 •  'dorcl.aleo/createAssertion' - 3,393 constraints (called 1 time)

➡️  Output

 • {
  owner: aleo1nr7zdkwml9tuy93x4k49zx8msgwjtcyykgat0mp0tu54kwmjeg8s97hljf.private,
  id: 6483909679030553276222748262902265455236698137743464346806854780005049792424field.private,
  details: {
    title: 0field.private,
    contentHash: 0field.private,
    asserter: aleo18jtgsuuu3rluye2tnevugl662nzhw7pw8tcmfrvss25mw36apvrsu97lyx.private,
    asserterDeposit: 10u64.private,
    voterFee: 1u64.private,
    disputeDeadlineBlockHeight: 0u32.private,
    votingDeadlineBlockHeight: 1000u32.private
  },
  _nonce: 628742935784324823208890032747019379011412115376911041885899818651721559914group.public
}

       Leo ✅ Finished 'dorcl.aleo/createAssertion' (in "/Users/jordan/optimistic-dark-oracle/dorcl/build")

```

Then to call the next function copy the "id:" field to "assertionId" and put the proper value in the "fee:" as follows:
```
[disputeAssertion]
fee: u64 = 10u64;
assertionId: field = 6483909679030553276222748262902265455236698137743464346806854780005049792424field;
```
Then the next command can be called as follows: 
```
jordan@p21 dorcl % leo run disputeAssertion
       Leo ✅ Compiled 'main.leo' into Aleo instructions

⛓  Constraints

 •  'dorcl.aleo/disputeAssertion' - 0 constraints (called 1 time)

       Leo ✅ Finished 'dorcl.aleo/disputeAssertion' (in "/Users/jordan/optimistic-dark-oracle/dorcl/build")

```

And so on. The workflow is as follows:
```
createAssertion
    maybe disputeAssertion
        then new_voting_right (for each voter)
            then either
                confirm
            or
                deny
        after votingDeadlineBlockHeight the result is available
```
