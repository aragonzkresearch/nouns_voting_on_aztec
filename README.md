# Nouns Voting on Aztec
This project shows a PoC of the implementation of [Nouns Voting protocol on Aztec]([URL](https://research.aragon.org/nouns-tech.html)).
Currently we have a [Solidity smart contract](https://github.com/aragonzkresearch/nouns-anonymous-voting).
The main difference of the Aztec.nr smart contract, at the current state of the work, is that the presented Noir contract is meant to represent a single voting process.
## Main idea
The main idea is to re-use some of the existing logic for the Token contract in order to define our voting system.

Instead of the struct **TokenNote** as a building block of the private state, we define the **VoteNote**.
To mint a correct VoteNote, the user must give a prove that he knows a secret **VoteProverInput** which satisfy some particular constraints, which ensure that it has been minted in a legitimate way:
    - The voter knows a secret key paired to a public in a specific list of public keys (zk-registry).
    - The voter owns an NFT in a specific list.
    - The voter has encrypted his vote and NFT using a Public Key from the Time Lock Cryptographic Service.

### Public State
The public state is made by:
    - A list of nullifiers;
    - A map from those nullifiers to corresponding PublicVote
    - A boolean variable which tells you if a specific vote has been tallied.
    - The tally result.

### Minting a vote
In order to mint a vote in the private state, the prover has to prove the assertions of the function **verify_vote**.
Once the vote has been minted, then it can be pushed to the public state via the function **submit_vote**. This function does not enforce constraints, but simply call an internal public function which adds the vote to the public state.

### Tally result
Once the votes have been made public and the TLCS secret is known, then the public function **tally_result** can be called. It will produce the number of votes for each choice (0/1/2).

## Roadblocks
### Misleading error messages when running a function
In the current implementation it is possible to compile and deploy the contract, but there are some weird errors when one tries to run the function. The errors are misleading and it is not possible to fix it. In particular it's not evident the line at which the error is produced.
### Misleading error messages when deploying with non-trivial constructor
Also in this case, there are errors which are not understandable. 