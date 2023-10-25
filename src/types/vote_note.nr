use dep::aztec::note::note_header::NoteHeader;
use dep::aztec::note::note_interface::NoteInterface;
use dep::aztec::types::address::AztecAddress;
use dep::std::ec::tecurve::affine::Point;

use crate::types::vote_utils::{Signature,VoteProverInput};


global VOTE_NOTE_LEN: Field = 23;

struct VoteNote {
    vote: VoteProverInput,
    owner: AztecAddress,
    header: NoteHeader,
}

impl VoteNote {
    pub fn new(vote: VoteProverInput, owner: AztecAddress) -> Self {
        Self{
            vote,
            owner,
            header: NoteHeader::empty(),
        }
    }

    fn serialize(self) -> [Field; VOTE_NOTE_LEN] {
        [self.vote.a.x, self.vote.a.y, self.vote.b, self.vote.n, self.vote.process_id, 
        self.vote.tlcs_pk.x, self.vote.tlcs_pk.y, self.vote.v, self.vote.blinding_factor,
        self.vote.signed_id.r_b8.x, self.vote.signed_id.r_b8.y, self.vote.signed_id.s,
        self.vote.signed_v.r_b8.x, self.vote.signed_v.r_b8.y, self.vote.signed_v.s, 
        self.vote.nft_id[0], self.vote.nft_id[1],
        self.vote.h_id, self.vote.k.x, self.vote.k.y,
        self.vote.registered_pbk.x, self.vote.registered_pbk.y,
        self.owner.address]
    }

    fn deserialize(preimage: [Field; VOTE_NOTE_LEN]) -> Self {
        Self{
            vote: VoteProverInput{
                    a: Point::new(preimage[0], preimage[1]),
                    b: preimage[2],
                    n: preimage[3],
                    process_id: preimage[4],
                    tlcs_pk: Point::new(preimage[5], preimage[6]),
                    v: preimage[7],
                    blinding_factor: preimage[8],
                    signed_id: Signature{r_b8: Point::new(preimage[9],preimage[10]), s: preimage[11]},
                    signed_v: Signature{r_b8: Point::new(preimage[12],preimage[13]), s: preimage[14]},
                    nft_id: [preimage[15], preimage[16]],
                    h_id: preimage[17],
                    k: Point::new(preimage[18], preimage[19]),
                    registered_pbk: Point::new(preimage[20], preimage[21]),
                    },
            owner: AztecAddress::new(preimage[22]),
            header: NoteHeader::empty(),
        }
    }

    fn set_header(&mut self, header: NoteHeader) {
        self.header = header;
    }
}

fn deserialize(preimage: [Field; VOTE_NOTE_LEN]) -> VoteNote {
    VoteNote::deserialize(preimage)
}

fn serialize(note: VoteNote) -> [Field; VOTE_NOTE_LEN] {
    note.serialize()
}

fn compute_note_hash(note: VoteNote) -> Field {
    0
}

fn compute_nullifier(note: VoteNote) -> Field {
    0
}

fn get_header(note: VoteNote) -> NoteHeader {
    note.header
}

fn set_header(note: &mut VoteNote, header: NoteHeader) {
    note.set_header(header)
}

global VoteNoteMethods = NoteInterface {
    deserialize,
    serialize,
    compute_note_hash,
    compute_nullifier,
    get_header,
    set_header,
};