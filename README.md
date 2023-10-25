# Nouns Voting on Aztec
This project shows a PoC of the implementation of [Nouns Voting protocol on Aztec]([URL](https://research.aragon.org/nouns-tech.html)).
Currently we have a [Solidity smart contract](https://github.com/aragonzkresearch/nouns-anonymous-voting).
The main difference of the Aztec.nr smart contract, at the current state of the work, is that the presented Noir contract is meant to represent a single voting process.
## Main idea
The main idea is to re-use some of the existing logic for the Token contract in order to define our voting system.

Instead of the struct **TokenNote** as a building block of the private state, we define the **VoteProverInputStruct**. The "vote prover input" is piece of data, which is needed by the prover in order to produce a vote and give a proof that the vote has been generated correctly.

The **PublicVote** and the **Nullifier** structs are the building blocks of the public state. The **Nullifier** is uniquely bounded to a specific pair (NFT, zk-reg public key) and it is used to avoid double voting.
Both these structs are a subset of the VoteProverInput. We want that everyone is able to produce a valid **PublicVote** if and only if the corresponding **Nullifier** is not in the public list and there exists a valid **VoteProverInput** struct which contains both of them.
Here "valid" means that the function "**verify_vote**" is successful.

The function **verify_vote** is the same of the one described by Nouns, in fact it checks:
- The vote has been encrypted correctly
- The knowledge of the secret key behind the zk-registry public key
- The fact that it has been used to correctly sign the nft_id and the vote.

In this case we are doing some simplification: we do not require that there are storage proofs for NFTs and ZK-registry public keys, but we're just enforcing that they belong to some hard-coded lists.

## Roadblock
I am successful at defining the private state as balances_map, where in this case the balance is a set of **VoteNote** (vote prover input notes). I want to define the public state as set of nullifiers and of public votes.
The hope would be to call **verify_vote** from a public function which adds nullifier and public vote to the public state. Ideally it should publicly verify a snark proof for the function verify_vote.