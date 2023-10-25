use dep::aztec::context::Context;
use dep::aztec::types::address::AztecAddress;
use dep::aztec::state_vars::set::Set;

use crate::types::vote_note::{VoteNote,VOTE_NOTE_LEN,VoteNoteMethods};
use crate::types::vote_utils::VoteProverInput;

struct BalanceSet {
  context: Context,
  owner: AztecAddress,
  set: Set<VoteNote, VOTE_NOTE_LEN>
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
    pub fn add(self, vote: VoteProverInput) {
        let mut vote_note = VoteNote::new(vote, self.owner);
        self.set.insert(&mut vote_note);
    }
}