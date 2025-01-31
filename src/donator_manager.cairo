use starknet::ContractAddress;
use starknet::class_hash::ClassHash;

#[starknet::interface]
pub trait IDonatorManager<TContractState> {
    fn new_donator(ref self: TContractState);
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn get_donator_class_hash(self: @TContractState) -> ClassHash;
    fn get_donator_by_address(self: @TContractState, owner: ContractAddress) -> ContractAddress;
}

#[starknet::contract]
pub mod DonatorManager {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::array::ArrayTrait;
    use core::traits::TryInto;
    use starknet::ContractAddress;
    use starknet::syscalls::deploy_syscall;
    use starknet::class_hash::ClassHash;
    use starknet::get_caller_address;

    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        owner: ContractAddress,
        donators: LegacyMap::<ContractAddress, ContractAddress>,
        donator_class_hash: ClassHash,
    }

    // *************************************************************************
    //                            CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, donator_class_hash: felt252) {
        self.owner.write(get_caller_address());
        self.donator_class_hash.write(donator_class_hash.try_into().unwrap());
    }

    // *************************************************************************
    //                            EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        DonatorContractDeployed: DonatorContractDeployed,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DonatorContractDeployed {
        pub new_donator: ContractAddress,
        pub owner: ContractAddress,
    }

    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************
    #[abi(embed_v0)]
    impl DonatorManagerImpl of super::IDonatorManager<ContractState> {
        fn new_donator(ref self: ContractState) {
            let mut call_data = ArrayTrait::<felt252>::new();
            call_data.append(get_caller_address().try_into().unwrap());

            let (new_donator_address, _) = deploy_syscall(
                self.donator_class_hash.read(), 12345, call_data.span(), false,
            )
                .unwrap();
            self.donators.write(get_caller_address().try_into().unwrap(), new_donator_address);
            self
                .emit(
                    DonatorContractDeployed {
                        owner: get_caller_address(), new_donator: new_donator_address,
                    },
                )
        }
        fn get_owner(self: @ContractState) -> ContractAddress {
            return self.owner.read();
        }
        fn get_donator_class_hash(self: @ContractState) -> ClassHash {
            return self.donator_class_hash.read();
        }
        fn get_donator_by_address(self: @ContractState, owner: ContractAddress) -> ContractAddress {
            return self.donators.read(owner);
        }
    }
}
