use dep::aztec::types::type_serialization::TypeSerializationInterface;
use dep::std::ec::tecurve::affine::Point;
use dep::std::eddsa::eddsa_poseidon_verify as eddsa_verify;
use dep::std::hash::poseidon::bn254;
use dep::std::ec::consts::te::baby_jubjub;



use crate::types::global_variables::{NFT_ID_LIST,PK_LIST};

global VOTE_PROVER_INPUT_LEN: Field = 22;

struct Signature
{
    r_b8: Point,
    s: Field,
}

struct VoteProverInput {
        // Public inputs
    a: Point,
    b: Field, // Hash of k,v,id
    n: Field,
    process_id: Field,
    tlcs_pk: Point, // Public key of TLCS
    
    // Private inputs
    v: Field, // in {0,1,2}
    blinding_factor: Field, // TODO: Formerly r: [u1; MAX_BITS]
    signed_id: Signature, //sigma
    signed_v: Signature, // tau
    nft_id: [Field; 2],
    h_id: Field,
    k: Point,
    registered_pbk: Point,
}

struct PublicVote {
    a: Point,
    b: Field,
    h_id: Field,
}

impl PublicVote {
    fn dummy_tally(self) -> Field {
        1
    }
}

global PUBLIC_VOTE_SERIALIZED_LEN: Field = 4;

fn deserializeVote(fields: [Field; PUBLIC_VOTE_SERIALIZED_LEN]) -> PublicVote {
    PublicVote {
        a: Point { x: fields[0], y: fields[1]},
        b: fields[2],
        h_id: fields[3],
    }
}

fn serializeVote(value: PublicVote) -> [Field; PUBLIC_VOTE_SERIALIZED_LEN] {
    [value.a.x, value.a.y, value.b, value.h_id]
}

global PublicVoteSerializationMethods = TypeSerializationInterface {
    deserialize: deserializeVote,
    serialize: serializeVote,
};

struct VoteAndNullifier {
    a: Point,
    b: Field,
    n: Field,
    h_id: Field,
}

impl VoteAndNullifier {
    fn serialize(self) -> [Field;5] {
        [self.a.x, self.a.y, self.b, self.n, self.h_id]
    }
}

impl VoteProverInput{
    fn serialize(self) -> [Field; VOTE_PROVER_INPUT_LEN] {
      [self.a.x, self.a.y, self.b, self.n, self.process_id, 
        self.tlcs_pk.x, self.tlcs_pk.y, self.v, self.blinding_factor,
        self.signed_id.r_b8.x, self.signed_id.r_b8.y, self.signed_id.s,
        self.signed_v.r_b8.x, self.signed_v.r_b8.y, self.signed_v.s, 
        self.nft_id[0], self.nft_id[1],
        self.h_id, self.k.x, self.k.y,
        self.registered_pbk.x, self.registered_pbk.y,
        ] 
    }
    
    fn verify_vote (self) -> VoteAndNullifier {
        let bjj_curve = baby_jubjub().curve;

        // Check signatures
        assert(eddsa_verify(self.registered_pbk.x, self.registered_pbk.y, self.signed_id.s, self.signed_id.r_b8.x, self.signed_id.r_b8.y, self.h_id));
        assert(eddsa_verify(self.registered_pbk.x, self.registered_pbk.y, self.signed_v.s, self.signed_v.r_b8.x, self.signed_v.r_b8.y, bn254::hash_1([self.v])));

        // Check ID hash
        assert(self.h_id == bn254::hash_2([self.nft_id[0], self.nft_id[1]]));

        // Check nullifier
        assert(self.n == bn254::hash_3([self.signed_id.r_b8.x, self.signed_id.r_b8.y, self.signed_id.s]));

        // Check vote encryption
        let b8 = baby_jubjub().base8;
        assert(bjj_curve.mul(self.blinding_factor, b8).eq(self.a));
        assert(self.k.eq(bjj_curve.mul(self.blinding_factor, self.tlcs_pk))); // TODO
        assert(self.b == bn254::hash_3([self.k.x, self.k.y, self.v]));
        assert((self.v == 0) | (self.v == 1) | (self.v == 2)); // Check validity of vote
        
        // Check that the registered public key and nft_id are in the corresponding list
        let mut b0 = point_eq(self.registered_pbk, PK_LIST[0]);
        let mut b1 = array_eq(self.nft_id, NFT_ID_LIST[0]);

        for i in 1..256{
            b0 = b0 | point_eq(self.registered_pbk, PK_LIST[i]);
            b1 = b1 | array_eq(self.nft_id, NFT_ID_LIST[i]);
        }
        assert(b0 & b1);
        VoteAndNullifier{
            a: self.a,
            b: self.b,
            n: self.n,
            h_id: self.h_id
            }
    }

    fn dummy_verify_vote(self) -> VoteAndNullifier {
        VoteAndNullifier{
            a: self.a,
            b: self.b,
            n: self.n,
            h_id: self.h_id
            }
    }
}


fn point_eq(p: Point, q: Point) -> bool {
    (p.x == q.x ) & (p.y == q.y)
}

fn array_eq(p: [Field;2], q: [Field;2]) -> bool {
    (p[0] == q[0]) & (p[1] == q[1])
}


struct NullifierList {
    vals: [Field; 256],
}

global NULLIFIER_LIST_SERIALIZED_LEN = 256;

fn deserializeNullifierList(fields: [Field; NULLIFIER_LIST_SERIALIZED_LEN]) -> NullifierList {
    NullifierList {
        vals: fields,
    }
}

fn serializeNullifierList(value: NullifierList) -> [Field; NULLIFIER_LIST_SERIALIZED_LEN] {
    value.vals
}

global NullifiersSerializationMethods = TypeSerializationInterface {
    deserialize: deserializeNullifierList,
    serialize: serializeNullifierList,
};

struct TallyResults {
    votes_zero: Field,
    votes_one: Field,
    votes_two: Field,
}

global TALLY_RESULTS_SERIALIZED_LEN = 3;
fn deserializeTallyResults(fields: [Field; TALLY_RESULTS_SERIALIZED_LEN]) -> TallyResults {
    TallyResults {
        votes_zero: fields[0],
        votes_one: fields[1],
        votes_two: fields[2],
    }
}

fn serializeTallyResults(value: TallyResults) -> [Field; TALLY_RESULTS_SERIALIZED_LEN] {
    [value.votes_zero, value.votes_one, value.votes_two]
}

global TallyResultsSerializationMethods = TypeSerializationInterface {
    deserialize: deserializeTallyResults,
    serialize: serializeTallyResults,
};