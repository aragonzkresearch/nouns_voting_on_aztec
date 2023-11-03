use dep::aztec::context::Context;
use dep::aztec::types::address::AztecAddress;
use dep::aztec::state_vars::set::Set;

use crate::types::vote_note::{VoteAndNullifierNote,VOTE_AND_NULLIFIER_NOTE_LEN,VoteNoteMethods};
use crate::types::vote_utils::VoteAndNullifier;

struct BalanceSet {
  context: Context,
  owner: AztecAddress,
  set: Set<VoteAndNullifierNote, VOTE_AND_NULLIFIER_NOTE_LEN>
}

impl BalanceSet {
    pub fn new(context: Context, owner: AztecAddress, storage_slot: Field) -> Self {
        let set = Set{
            context,
            storage_slot,
            note_interface: VoteNoteMethods,
        };
        Self{
            context,
            owner,
            set,
        }
    }
    pub fn add(self, vote: VoteAndNullifier) {
        let mut vote_note = VoteAndNullifierNote::new(vote, self.owner);
        self.set.insert(&mut vote_note);
    }
}