use dep::aztec::note::note_header::NoteHeader;
use dep::aztec::note::note_interface::NoteInterface;
use dep::aztec::types::address::AztecAddress;
use dep::std::ec::tecurve::affine::Point;

use crate::types::vote_utils::{Signature,VoteAndNullifier};


global VOTE_AND_NULLIFIER_NOTE_LEN: Field = 6;

struct VoteAndNullifierNote {
    vote_and_nullifier: VoteAndNullifier,
    owner: AztecAddress,
    header: NoteHeader,
}

impl VoteAndNullifierNote {
    pub fn new(vote: VoteAndNullifier, owner: AztecAddress) -> Self {
        Self{
            vote_and_nullifier: vote,
            owner: owner,
            header: NoteHeader::empty(),
        }
    }

    fn serialize(self) -> [Field; VOTE_AND_NULLIFIER_NOTE_LEN] {
        [self.vote_and_nullifier.a.x, self.vote_and_nullifier.a.y, self.vote_and_nullifier.b,
        self.vote_and_nullifier.n, self.vote_and_nullifier.h_id, 
        self.owner.address]
    }

    fn deserialize(preimage: [Field; VOTE_AND_NULLIFIER_NOTE_LEN]) -> Self {
        Self{
            vote_and_nullifier: VoteAndNullifier{
                    a: Point::new(preimage[0], preimage[1]),
                    b: preimage[2],
                    n: preimage[3],
                    h_id: preimage[4],
                    },
            owner: AztecAddress::new(preimage[5]),
            header: NoteHeader::empty(),
        }
    }

    fn set_header(&mut self, header: NoteHeader) {
        self.header = header;
    }
}

fn deserialize(preimage: [Field; VOTE_AND_NULLIFIER_NOTE_LEN]) -> VoteAndNullifierNote {
    VoteAndNullifierNote::deserialize(preimage)
}

fn serialize(note: VoteAndNullifierNote) -> [Field; VOTE_AND_NULLIFIER_NOTE_LEN] {
    note.serialize()
}

fn compute_note_hash(note: VoteAndNullifierNote) -> Field {
    0
}

fn compute_nullifier(note: VoteAndNullifierNote) -> Field {
    0
}

fn get_header(note: VoteAndNullifierNote) -> NoteHeader {
    note.header
}

fn set_header(note: &mut VoteAndNullifierNote, header: NoteHeader) {
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