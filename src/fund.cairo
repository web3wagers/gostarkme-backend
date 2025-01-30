use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct DonatorInfo {
    pub donator_index: u256,
    pub donator_address: ContractAddress,
    pub donator_amount: u256
}

#[starknet::interface]
pub trait IFund<TContractState> {
    fn get_id(self: @TContractState) -> u128;
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn is_owner(self: @TContractState, caller: ContractAddress) -> bool;
    fn set_name(ref self: TContractState, name: ByteArray);
    fn get_name(self: @TContractState) -> ByteArray;
    fn set_reason(ref self: TContractState, reason: ByteArray);
    fn get_reason(self: @TContractState) -> ByteArray;
    fn get_donators(self: @TContractState) -> Array<DonatorInfo>;
    fn receive_vote(ref self: TContractState);
    fn get_up_votes(self: @TContractState) -> u32;
    fn set_goal(ref self: TContractState, goal: u256);
    fn get_goal(self: @TContractState) -> u256;
    fn update_receive_donation(ref self: TContractState, strks: u256);
    fn get_current_goal_state(self: @TContractState) -> u256;
    fn set_state(ref self: TContractState, state: u8);
    fn get_state(self: @TContractState) -> u8;
    fn get_voter(self: @TContractState, user: ContractAddress) -> u32;
    fn withdraw(ref self: TContractState);
    fn set_evidence_link(ref self: TContractState, evidence: ByteArray);
    fn get_evidence_link(self: @TContractState) -> ByteArray;
    fn set_contact_handle(ref self: TContractState, contact_handle: ByteArray);
    fn get_contact_handle(self: @TContractState) -> ByteArray;
    fn set_type(ref self: TContractState, fund_type: u8);
    fn get_type(self: @TContractState) -> u8;
    fn get_donation_amount(self: @TContractState, donator: ContractAddress) -> u256;
    fn get_single_donator_by_address(
        self: @TContractState, donator: ContractAddress
    ) -> DonatorInfo;
}

#[starknet::contract]
pub mod Fund {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use super::DonatorInfo;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::get_contract_address;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use gostarkme::constants::{funds::{fund_constants::FundStates},};
    use gostarkme::constants::{funds::{fund_constants::FundConstants},};
    use gostarkme::constants::{fund_manager::{fund_manager_constants::FundManagerConstants},};
    use gostarkme::constants::{starknet::{starknet_constants::StarknetConstants},};

    // *************************************************************************
    //                            EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        DonationWithdraw: DonationWithdraw,
        NewVoteReceived: NewVoteReceived,
        DonationReceived: DonationReceived,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DonationWithdraw {
        #[key]
        pub owner_address: ContractAddress,
        pub fund_contract_address: ContractAddress,
        pub withdrawn_amount: u256
    }

    #[derive(Drop, starknet::Event)]
    pub struct NewVoteReceived {
        #[key]
        pub voter: ContractAddress,
        pub fund: ContractAddress,
        pub votes: u32
    }

    #[derive(Drop, starknet::Event)]
    pub struct DonationReceived {
        #[key]
        pub donator_address: ContractAddress,
        pub current_balance: u256,
        pub donated_strks: u256,
        pub fund_contract_address: ContractAddress,
    }
    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        id: u128,
        owner: ContractAddress,
        name: ByteArray,
        reason: ByteArray,
        up_votes: u32,
        voters: LegacyMap::<ContractAddress, u32>,
        donators: LegacyMap::<ContractAddress, DonatorInfo>,
        total_donators: u256,
        donation_list: LegacyMap::<u256, DonatorInfo>,
        goal: u256,
        state: u8,
        evidence_link: ByteArray,
        contact_handle: ByteArray,
        fund_type: u8,
    }

    // *************************************************************************
    //                            CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(
        ref self: ContractState,
        id: u128,
        owner: ContractAddress,
        name: ByteArray,
        goal: u256,
        evidence_link: ByteArray,
        contact_handle: ByteArray,
        reason: ByteArray,
        fund_type: u8,
    ) {
        self.id.write(id);
        self.owner.write(owner);
        self.name.write(name);
        self.reason.write(reason);
        self.up_votes.write(FundConstants::INITIAL_UP_VOTES);
        self.goal.write(goal);
        self.state.write(FundStates::RECOLLECTING_VOTES);
        self.evidence_link.write(evidence_link);
        self.contact_handle.write(contact_handle);
        self.fund_type.write(fund_type);
    }

    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************
    #[abi(embed_v0)]
    impl FundImpl of super::IFund<ContractState> {
        fn get_id(self: @ContractState) -> u128 {
            return self.id.read();
        }
        fn get_owner(self: @ContractState) -> ContractAddress {
            return self.owner.read();
        }
        fn is_owner(self: @ContractState, caller: ContractAddress) -> bool {
            return (self.owner.read() == caller);
        }
        fn set_name(ref self: ContractState, name: ByteArray) {
            let caller = get_caller_address();
            let valid_address_1 = contract_address_const::<FundManagerConstants::VALID_ADDRESS_1>();
            let valid_address_2 = contract_address_const::<FundManagerConstants::VALID_ADDRESS_2>();
            assert!(
                self.owner.read() == caller
                    || valid_address_1 == caller
                    || valid_address_2 == caller,
                "You must be an owner or admin to perform this action"
            );
            self.name.write(name);
        }
        fn get_name(self: @ContractState) -> ByteArray {
            return self.name.read();
        }
        fn set_reason(ref self: ContractState, reason: ByteArray) {
            let caller = get_caller_address();
            let valid_address_1 = contract_address_const::<FundManagerConstants::VALID_ADDRESS_1>();
            let valid_address_2 = contract_address_const::<FundManagerConstants::VALID_ADDRESS_2>();

            assert!(
                self.owner.read() == caller
                    || valid_address_1 == caller
                    || valid_address_2 == caller,
                "You must be an owner or admin to perform this action"
            );

            self.reason.write(reason);
        }
        fn get_reason(self: @ContractState) -> ByteArray {
            return self.reason.read();
        }
        fn get_donators(self: @ContractState) -> Array<DonatorInfo> {
            let mut donators = array![];
            let mut i: u256 = 1;
            while i < self
                .total_donators
                .read() {
                    let donator = self.donation_list.read(i);
                    donators.append(donator);
                    i += 1;
                };
            donators
        }
        fn receive_vote(ref self: ContractState) {
            assert(self.voters.read(get_caller_address()) == 0, 'User already voted!');
            assert(
                self.state.read() == FundStates::RECOLLECTING_VOTES, 'Fund not recollecting votes!'
            );
            self.up_votes.write(self.up_votes.read() + 1);
            self.voters.write(get_caller_address(), self.up_votes.read());
            if self.up_votes.read() >= FundConstants::UP_VOTES_NEEDED {
                self.state.write(FundStates::RECOLLECTING_DONATIONS);
            }

            self
                .emit(
                    NewVoteReceived {
                        voter: get_caller_address(),
                        fund: get_contract_address(),
                        votes: self.up_votes.read()
                    }
                );
        }
        fn get_up_votes(self: @ContractState) -> u32 {
            return self.up_votes.read();
        }
        fn set_goal(ref self: ContractState, goal: u256) {
            let caller = get_caller_address();
            let valid_address_1 = contract_address_const::<FundManagerConstants::VALID_ADDRESS_1>();
            let valid_address_2 = contract_address_const::<FundManagerConstants::VALID_ADDRESS_2>();
            assert!(
                valid_address_1 == caller || valid_address_2 == caller, "Only Admins can set goal"
            );
            self.goal.write(goal);
        }
        fn get_goal(self: @ContractState) -> u256 {
            return self.goal.read();
        }
        fn update_receive_donation(ref self: ContractState, strks: u256) {
            let current_balance = self.get_current_goal_state();
            let caller: ContractAddress = get_caller_address();
            let mut donator = self.donators.read(caller);
            let prev_donator_count = self.total_donators.read();

            if donator.donator_amount == 0 {
                let new_index = prev_donator_count + 1;
                donator =
                    DonatorInfo {
                        donator_address: caller, donator_index: new_index, donator_amount: strks,
                    };

                self.total_donators.write(new_index);
            } else {
                donator.donator_amount += strks;
            }
            self.donators.write(caller, donator.clone());
            self.donation_list.write(donator.donator_index, donator);
            if current_balance >= self.goal.read() {
                self.state.write(FundStates::CLOSED);
            }
            self
                .emit(
                    DonationReceived {
                        current_balance,
                        donated_strks: strks,
                        donator_address: caller,
                        fund_contract_address: get_contract_address(),
                    }
                );
        }

        fn get_current_goal_state(self: @ContractState) -> u256 {
            self.token_dispatcher().balance_of(get_contract_address())
        }
        fn set_state(ref self: ContractState, state: u8) {
            let caller = get_caller_address();
            let valid_address_1 = contract_address_const::<FundManagerConstants::VALID_ADDRESS_1>();
            let valid_address_2 = contract_address_const::<FundManagerConstants::VALID_ADDRESS_2>();
            assert!(
                valid_address_1 == caller || valid_address_2 == caller,
                "Only Admins can change the fund state."
            );
            self.state.write(state);
        }
        fn get_state(self: @ContractState) -> u8 {
            return self.state.read();
        }
        fn get_voter(self: @ContractState, user: ContractAddress) -> u32 {
            let voter = self.voters.read(user);
            return voter;
        }
        fn withdraw(ref self: ContractState) {
            let caller = get_caller_address();
            assert!(self.owner.read() == caller, "You are not the owner");
            assert(self.state.read() == FundStates::CLOSED, 'Fund not close goal yet.');

            let valid_address = contract_address_const::<FundManagerConstants::VALID_ADDRESS_1>();
            let withdrawn_amount = (self.get_current_goal_state() * 95) / 100;
            let fund_manager_amount = (self.get_current_goal_state() * 5) / 100;

            self.token_dispatcher().approve(self.get_owner(), withdrawn_amount);
            self.token_dispatcher().transfer(self.get_owner(), withdrawn_amount);

            self.token_dispatcher().approve(valid_address, fund_manager_amount);
            self.token_dispatcher().transfer(valid_address, fund_manager_amount);

            assert(self.get_current_goal_state() == 0, 'Pending stks to withdraw');
            self.state.write(FundStates::WITHDRAW);

            self
                .emit(
                    DonationWithdraw {
                        owner_address: self.get_owner(),
                        fund_contract_address: get_contract_address(),
                        withdrawn_amount
                    }
                );
        }
        fn set_evidence_link(ref self: ContractState, evidence: ByteArray) {
            let caller = get_caller_address();
            assert!(self.owner.read() == caller, "You are not the owner");
            self.evidence_link.write(evidence);
        }
        fn get_evidence_link(self: @ContractState) -> ByteArray {
            return self.evidence_link.read();
        }
        fn set_contact_handle(ref self: ContractState, contact_handle: ByteArray) {
            let caller = get_caller_address();
            let valid_address_1 = contract_address_const::<FundManagerConstants::VALID_ADDRESS_1>();
            let valid_address_2 = contract_address_const::<FundManagerConstants::VALID_ADDRESS_2>();
            assert!(
                self.owner.read() == caller
                    || valid_address_1 == caller
                    || valid_address_2 == caller,
                "You must be an owner or admin to perform this action"
            );
            self.contact_handle.write(contact_handle);
        }
        fn get_contact_handle(self: @ContractState) -> ByteArray {
            return self.contact_handle.read();
        }
        fn set_type(ref self: ContractState, fund_type: u8) {
            let caller = get_caller_address();
            let valid_address_1 = contract_address_const::<FundManagerConstants::VALID_ADDRESS_1>();
            let valid_address_2 = contract_address_const::<FundManagerConstants::VALID_ADDRESS_2>();
            assert!(
                valid_address_1 == caller || valid_address_2 == caller,
                "Only Admins can change the fund type."
            );
            self.fund_type.write(fund_type);
        }
        fn get_type(self: @ContractState) -> u8 {
            return self.fund_type.read();
        }
        fn get_donation_amount(self: @ContractState, donator: ContractAddress) -> u256 {
            return self.donators.read(donator);
        fn get_single_donator_by_address(
            self: @ContractState, donator: ContractAddress
        ) -> DonatorInfo {
            self.donators.read(donator)
        }
    }
    // *************************************************************************
    //                            INTERNALS
    // *************************************************************************
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn token_dispatcher(self: @ContractState) -> IERC20Dispatcher {
            IERC20Dispatcher {
                contract_address: contract_address_const::<StarknetConstants::STRK_TOKEN_ADDRESS>()
            }
        }
    }
}
