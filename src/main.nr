mod types;
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
    use dep::aztec::types::type_serialization::field_serialization::FIELD_SERIALIZED_LEN;
    use dep::aztec::types::type_serialization::field_serialization::FieldSerializationMethods;
    

    use dep::std::ec::tecurve::affine::Point;

    use dep::std::hash::poseidon::bn254;
    use dep::std::ec::consts::te::baby_jubjub;

    use crate::types::balances_map::BalancesMap;
    use crate::types::vote_utils::{Signature, VoteProverInput,PublicVote,PublicVoteAndNullifier, 
        PUBLIC_VOTE_SERIALIZED_LEN, PublicVoteSerializationMethods};
    use crate::types::global_variables::{SK_LIST,NFT_ID_LIST,PK_LIST};

    struct Storage {
        balances: BalancesMap,
        nullifiers: PublicState<Field,FIELD_SERIALIZED_LEN>,
        public_votes: PublicState<PublicVote,PUBLIC_VOTE_SERIALIZED_LEN>,
    }

    impl Storage {
        fn init(context: Context) -> pub Self {
            Self{
                balances: BalancesMap::new(context, 1),
                nullifiers: PublicState::new(
                    context,
                    2,
                    FieldSerializationMethods,
                ),
                public_votes: PublicState::new(
                    context,
                    3,
                    PublicVoteSerializationMethods,
                ),
            }
        }
    }

    #[aztec(private)]
    fn constructor() {
        // let selector = compute_selector("_initialize((Field))");
        // context.call_public_function(context.this_address(), selector, [admin.address]);
    }

    #[aztec(private)]
    fn mint_vote_prover_input(
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
        storage.balances.at(address).add(vote_prover_input);
        1
    }

    // #[aztec(private)]
    // internal fn verify_vote(vote_prover_input: VoteProverInput) -> PublicVoteAndNullifier {
    //     vote_prover_input.verify_vote()
    // }

    // #[aztec(public)]
    // fn submit_public_vote (address: AztecAddress, vote_idx: Field) {
    //     let options = NoteGetterOptions::new();
    //     let maybe_vote_note = storage.balances.at(address).set.get_notes(options)[vote_idx];
    //     assert(maybe_vote_note.is_some(), "Error: the vote index is too high.");
    //     let vote_prover_input = maybe_vote_note.unwrap_unchecked().vote;
    //     let public_vote_and_nullifier = verify_vote(vote_prover_input);
    //     let public_vote = public_vote_and_nullifier.public_vote;
    //     let nullifier = public_vote_and_nullifier.nullifier;
    //     storage.nullifiers.write(nullifier);
    //     storage.public_votes.write(public_vote);
    // }

    

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
        // eddsa_sign(h_id)
        let r = rand();
        let R = bjj.curve.mul(r,bjj.base8);
        let s = bn254::hash_5([R.x, R.y,PK.x, PK.y, h_id])*sk + r;
        let signed_id = Signature {
            r_b8: R,
            s: s,
        };
        // Nullifier
        let n = bn254::hash_3([R.x, R.y, s]);
        // eddsa_sign(v)
        let r = rand();
        let R = bjj.curve.mul(r, bjj.base8);
        let s = bn254::hash_5([R.x, R.y,PK.x, PK.y, v])*sk + r;
        let signed_v = Signature {
            r_b8: R,
            s: s,
        };
        let blinding_factor = rand();
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
