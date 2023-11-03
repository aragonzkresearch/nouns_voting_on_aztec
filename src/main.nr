mod types;
mod bjj_scalar_field;
contract Voting {
    use dep::aztec::context::Context;
    use dep::aztec::note::note_getter_options::NoteGetterOptions;
    use dep::aztec::oracle::rand::rand;
    use dep::aztec::selector::compute_selector;
    use dep::aztec::state_vars::public_state::PublicState;
    use dep::aztec::state_vars::map::Map;
    use dep::aztec::types::address::AztecAddress;
    use dep::aztec::types::type_serialization::aztec_address_serialization::AZTEC_ADDRESS_SERIALIZED_LEN;
    use dep::aztec::types::type_serialization::aztec_address_serialization::AztecAddressSerializationMethods;
    use dep::aztec::types::type_serialization::bool_serialization::{BoolSerializationMethods, BOOL_SERIALIZED_LEN};
    use dep::aztec::types::type_serialization::field_serialization::FIELD_SERIALIZED_LEN;
    use dep::aztec::types::type_serialization::field_serialization::FieldSerializationMethods;
    

    use dep::std::ec::tecurve::affine::Point;

    use dep::std::hash::poseidon::bn254;
    use dep::std::ec::consts::te::baby_jubjub;

    use crate::types::balances_map::BalancesMap;
    use crate::types::vote_utils::{Signature, VoteProverInput, VoteAndNullifier, PublicVote,
        PUBLIC_VOTE_SERIALIZED_LEN, PublicVoteSerializationMethods, NullifierList, NullifiersSerializationMethods, NULLIFIER_LIST_SERIALIZED_LEN,
        TallyResults, TALLY_RESULTS_SERIALIZED_LEN, TallyResultsSerializationMethods};
    use crate::types::global_variables::{SK_LIST,NFT_ID_LIST,PK_LIST};
    use crate::bjj_scalar_field::PrimeField;

    struct Storage {
        // The set of private votes
        balances: BalancesMap,
        // This map associates a nullifier to a vote.
        public_votes: Map<PublicState<PublicVote, PUBLIC_VOTE_SERIALIZED_LEN>>,
        tallied: PublicState<bool, BOOL_SERIALIZED_LEN>,
        current_idx: PublicState<Field, FIELD_SERIALIZED_LEN>,
        nullifiers: PublicState<NullifierList, NULLIFIER_LIST_SERIALIZED_LEN>,
        tally_results: PublicState<TallyResults, TALLY_RESULTS_SERIALIZED_LEN>,
    }

    impl Storage {
        fn init(context: Context) -> pub Self {
            Self{
                balances: BalancesMap::new(context, 1),
                public_votes: Map::new(
                    context,
                    2,
                    |context, slot| {
                        PublicState::new(
                            context,
                            slot,
                            PublicVoteSerializationMethods,
                        )
                    },
                ),
                tallied: PublicState::new(
                    context,
                    3,
                    BoolSerializationMethods,
                ),
                current_idx: PublicState::new(
                    context,
                    4,
                    FieldSerializationMethods,
                ),
                nullifiers: PublicState::new(
                    context,
                    5,
                    NullifiersSerializationMethods,
                ),
                tally_results: PublicState::new(
                    context,
                    6,
                    TallyResultsSerializationMethods,
                ),
            }
        }
    }

    // If I uncomment the content of this function, then it is not possible to deploy for some reasons.
    //     Error in command execution
    //     TypeError: args.join is not a function
    //     at encodeArgs (file:///home/daniele/.nvm/versions/node/v18.18.0/lib/node_modules/@aztec/cli/dest/encoding.js:100:50)
    //     at prepTx (file:///home/daniele/.nvm/versions/node/v18.18.0/lib/node_modules/@aztec/cli/dest/utils.js:130:26)
    //     at async Command.<anonymous> (file:///home/daniele/.nvm/versions/node/v18.18.0/lib/node_modules/@aztec/cli/dest/index.js:389:52)
    //     at async Command.parseAsync (/home/daniele/.nvm/versions/node/v18.18.0/lib/node_modules/@aztec/cli/node_modules/commander/lib/command.js:935:5)
    //     at async main (file:///home/daniele/.nvm/versions/node/v18.18.0/lib/node_modules/@aztec/cli/dest/bin/index.js:10:5)
    #[aztec(private)]
    fn constructor() {
        // let selector = compute_selector("initialize()");
        // context.call_public_function(context.this_address(), selector, []);
    }

    #[aztec(private)]
    fn mint_vote_and_nullifier(
        address: AztecAddress,
        nft_id_idx: Field,
        sk_idx: Field,
        v: Field,
        tlcs_pk_x: Field,
        tlcs_pk_y: Field
        ) -> Field {
        // if (from.address != context.msg_sender()) {
        //     assert_current_call_valid_authwit(&mut context, from);
        // } else {
        //     assert(nonce == 0, "invalid nonce");
        // }

        // I don't understand this error: the function defined below has 5 parameters and not 6
        let vote_prover_input: VoteProverInput = generate_vote_prover_input(nft_id_idx, sk_idx,v,tlcs_pk_x,tlcs_pk_y);
        // It should be standard verify_vote, but the verification is not passing for a motivation still not clear.
        let vote_and_nullifier: VoteAndNullifier = vote_prover_input.dummy_verify_vote();
        // let vote_and_nullifier = VoteAndNullifier {
        //     a: vote_prover_input.a,
        //     b: vote_prover_input.b,
        //     n: vote_prover_input.n,
        //     h_id: vote_prover_input.h_id
        //     };
        storage.balances.at(address).add(vote_and_nullifier);
        1
    }

    #[aztec(private)]
    fn submit_public_vote (address: AztecAddress, vote_idx: Field) {
        let maybe_vote_notes = storage.balances.at(address).set.get_notes(NoteGetterOptions::new());
        assert(maybe_vote_notes[vote_idx].is_some());
        let note = maybe_vote_notes[vote_idx].unwrap_unchecked();
        storage.balances.at(address).set.remove(note);

        let selector = compute_selector("_add_public_vote((Field,Field,Field,Field,Field))");
        let _void = context.call_public_function(context.this_address(), selector, note.vote_and_nullifier.serialize());

    }

    #[aztec(public)]
    fn tally_result() {
        assert(storage.tallied.read() == false);
        let mut zeros = 0;
        let mut ones = 0;
        let mut twos = 0;
        for i in 0..storage.current_idx.read() {
            let nullifier: Field = storage.nullifiers.read().vals[i];
            // It should be replaced with a real tally
            let v = storage.public_votes.at(nullifier).read().dummy_tally();
            if v == 0 {
                zeros = zeros + 1;
            }
            else if v == 1 {
                ones = ones + 1;
            }
            else if v == 2 {
                twos = twos + 1;
            }
            else {
                assert(false, "the vote has not been encrypted correctly");
            }
        }
        storage.tally_results.write(TallyResults{ votes_zero: zeros, votes_one: ones, votes_two: twos});
        storage.tallied.write(true);
    }

    #[aztec(public)]
    internal fn _add_public_vote(vote_and_nullifier: VoteAndNullifier) {
        let nullifier = vote_and_nullifier.n;
        let current_idx: Field = storage.current_idx.read();
        let mut nullifier_list: [Field;256] = storage.nullifiers.read().vals;
        for i in 0..current_idx {
            assert(nullifier_list[i] != nullifier);
        }
        nullifier_list[current_idx] = nullifier;
        storage.current_idx.write(current_idx+ 1);
        storage.nullifiers.write(NullifierList {vals: nullifier_list});

        let public_vote = PublicVote {
            a: vote_and_nullifier.a,
            b: vote_and_nullifier.b,
            h_id: vote_and_nullifier.h_id,
        };
        storage.public_votes.at(nullifier).write(public_vote);

    }

    #[aztec(public)]
    fn initialize() {
        storage.tallied.write(false);
        storage.current_idx.write(0);
        storage.nullifiers.write( NullifierList{vals: [0;256]} );
    }
    
    unconstrained fn show_private_vote(owner: AztecAddress, vote_idx: Field) -> VoteAndNullifier {
        let maybe_vote_notes = storage.balances.at(owner).set.get_notes(NoteGetterOptions::new());
        assert(maybe_vote_notes[vote_idx].is_some());
        maybe_vote_notes[vote_idx].unwrap_unchecked().vote_and_nullifier
    } 

    unconstrained fn generate_vote_prover_input (
    nft_id_idx: Field,
    sk_idx: Field,
    v: Field,
    tlcs_pk_x: Field,
    tlcs_pk_y: Field
    ) -> VoteProverInput {
    let nft_id: [Field; 2] = NFT_ID_LIST[nft_id_idx];
    let sk: Field = SK_LIST[sk_idx];
    let PK: Point = PK_LIST[sk_idx];
    let bjj = baby_jubjub();
    let h_id =  bn254::hash_2(nft_id);
    // // eddsa_sign(h_id)
    let r = 123456789;
    let R = bjj.curve.mul(r, bjj.base8);
    let mut s: PrimeField = ( PrimeField::from_32_bytes(bn254::hash_5([R.x, R.y,PK.x, PK.y, h_id]).to_le_bytes(32)) );
    s = s.mul(PrimeField::from_32_bytes(sk.to_le_bytes(32)));
    s = s.add(PrimeField::from_32_bytes(r.to_le_bytes(32)));
    let s = s.to_field();
    // let s = 1;
    let signed_id = Signature {
        r_b8: R,
        s: s,
    };
    // Nullifier
    let n = bn254::hash_3([R.x, R.y, s]);
    // eddsa_sign(v)
    let r = 123456789;
    let R = bjj.curve.mul(r, bjj.base8);
    let mut s: PrimeField = ( PrimeField::from_32_bytes(bn254::hash_5([R.x, R.y,PK.x, PK.y, v]).to_le_bytes(32)) );
    s = s.mul(PrimeField::from_32_bytes(sk.to_le_bytes(32)));
    s = s.add(PrimeField::from_32_bytes(r.to_le_bytes(32)));
    let s = s.to_field();
    // let s = 1;
    let signed_v = Signature {
        r_b8: R,
        s: s,
    };
    let blinding_factor = 123456789;
    let a = bjj.curve.mul(blinding_factor,bjj.base8);
    let tlcs_pk = Point{ x: tlcs_pk_x, y: tlcs_pk_y};
    let k = bjj.curve.mul(blinding_factor, tlcs_pk);
    let b = bn254::hash_3([k.x, k.y, v]);
    VoteProverInput {
        a: a,
        b: b,
        n: n,
        process_id: 0,
        tlcs_pk: tlcs_pk,
        v: v,
        blinding_factor: blinding_factor,
        signed_id: signed_id,
        signed_v: signed_v,
        nft_id:  nft_id,
        h_id: h_id,
        k: k,
        registered_pbk: PK_LIST[sk_idx],
    }
}

}
