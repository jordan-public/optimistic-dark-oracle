# optimistic-dark-oracle
Optimistic Oracle with Zero Knowledge Voting

## Demo

See demo and video [here](./demo/README.md).

## Abstract

We built a rudimentary Optimistic Oracle akin to UMA. This is a proof of concept in secret Zero Knowledge (ZK) voting, in an effort to obstruct and/or eliminate voter corruption.

## Introduction - Optimistic Oracles

Optimistic oracle is an on-chain protocol which allows participants to assert claims and vouch for them financially, and use the assertion as a "guarantee" for further actions. Anyone can dispute the assertion within an allotted deadline and collect an award if proven right, while the asserter is financially punished for the incorrect assertion. The resolution is achieved through voting by the stakeholders. The most successful such Optimistic Oracle is UMA, and it is used for guaranteeing asset transfers (Across), betting markets / binary options (Polymarket) and many other places. 

## Dark Optimistic Oracle

UMA uses 2-phase commit for the voting. Voters add "salt" to the answer and submit a hash of the above as commitment. In the second phase the voters submit the hash pre-image, revealing how they originally voted. This prevents the voters from looking at each other's voting. 

We go one step further, and re-implement a rudimentary Optimistic Oracle, where the entire voting process is hidden by Zero Knowledge proofs. No one can find how specific voter voted, even after the voting is completed. At the end of the voting only a Zero Knowledge proof of the voting outcome is available for verification. 

In addition, each voter has a Zero Knowledge proof (Voting Receipt) of their voting action, which allows the voter to collect the award for voting for the "correct" outcome. The user can submit this proof to the protocol and collect the award in an obfuscated manner, similar to a ZCash transaction.

To obfuscate the payment transactions a token is implemented which allows for both public and private minting, burning and transfers of assets.

## Technology

The protocol is written in Leo and deployed on the Aleo blockchain. Each transaction consists of:
- SnarkVM operation, which creates a ZK proof for the needs of secrecy.
- SnarkOS operation, which records the encrypted secret records as well as the non-secret information to the Aleo blockchain.

## Conclusion

The Aleo technology is very new and there are some missing convenience components. Notably because of the missing upcoming Aleo indexer, each transaction outcome Records have to be "remembered" on order re-use them in future calls, such as claiming the voting rewards or secret asset transfer claims. Yet, in the nearest future this is a very promising technology.