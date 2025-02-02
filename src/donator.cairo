use starknet::ContractAddress;

#[starknet::interface]
pub trait IDonator<TContractState> {
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn get_level(self: @TContractState) -> u32;
    fn get_total_stark_donations(self: @TContractState) -> u256;
    fn get_max_stark_donations_to_next_level(self: @TContractState) -> u256;
    fn update_donator_values(ref self: TContractState, donated_starks: u256);
}

#[starknet::contract]
mod Donator {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use starknet::ContractAddress;
    use gostarkme::constants::{donator::{donator_constants::DonatorConstants}};

    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        owner: ContractAddress,
        level: u32,
        total_stark_donations: u256,
        max_stark_donations_to_next_level: u256
    }

    // *************************************************************************
    //                            CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
        self.level.write(DonatorConstants::INITIAL_LEVEL);
        self.total_stark_donations.write(0);
        self
            .max_stark_donations_to_next_level
            .write(DonatorConstants::INITIAL_MAX_STARKS_DONATION_TO_NEXT_LEVEL);
    }

    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************
    #[abi(embed_v0)]
    impl DonatorImpl of super::IDonator<ContractState> {
        fn get_owner(self: @ContractState) -> ContractAddress {
            return self.owner.read();
        }
        fn get_level(self: @ContractState) -> u32 {
            return self.level.read();
        }
        fn get_total_stark_donations(self: @ContractState) -> u256 {
            return self.total_stark_donations.read();
        }
        fn get_max_stark_donations_to_next_level(self: @ContractState) -> u256 {
            return self.max_stark_donations_to_next_level.read();
        }
        fn update_donator_values(ref self: ContractState, donated_starks: u256) {
            let total_donator_pod = self.total_stark_donations.read() + donated_starks;
            self.total_stark_donations.write(total_donator_pod);
            if (total_donator_pod > self.max_stark_donations_to_next_level.read()) {
                self.level.write(self.level.read() + 1);
                self
                    .max_stark_donations_to_next_level
                    .write(self.max_stark_donations_to_next_level.read() * 2);
            }
        }
    }
}
