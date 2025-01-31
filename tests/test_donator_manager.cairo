// *************************************************************************
//                              DONATOR MANAGER TEST
// *************************************************************************
use starknet::{ContractAddress, contract_address_const};
use starknet::class_hash::{ClassHash};
use starknet::syscalls::deploy_syscall;

use snforge_std::{
    ContractClass, declare, ContractClassTrait, start_cheat_caller_address_global, get_class_hash,
    spy_events, EventSpyAssertionsTrait,
};

use openzeppelin::utils::serde::SerializedAppend;

use gostarkme::donator_manager::{
    DonatorManager, IDonatorManagerDispatcher, IDonatorManagerDispatcherTrait,
};

fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

fn __setup__() -> (ContractAddress, ClassHash) {
    // Donator
    let donator = declare("Donator").unwrap();
    let mut donator_calldata: Array<felt252> = array![];
    donator_calldata.append_serde(OWNER());
    let (donator_contract_address, _) = donator.deploy(@donator_calldata).unwrap();
    let donator_class_hash = get_class_hash(donator_contract_address);

    // Donator Manager
    let donator_manager = declare("DonatorManager").unwrap();
    let mut donator_manager_calldata: Array<felt252> = array![];
    donator_manager_calldata.append_serde(donator_class_hash);
    let (contract_address, _) = donator_manager.deploy(@donator_manager_calldata).unwrap();

    return (contract_address, donator_class_hash);
}

// *************************************************************************
//                              TEST
// *************************************************************************
#[test]
fn test_constructor() {
    // Put owner address like caller
    start_cheat_caller_address_global(OWNER());
    let (contract_address, donator_class_hash) = __setup__();
    let donator_manager_contract = IDonatorManagerDispatcher { contract_address };
    let expected_donator_address = donator_manager_contract.get_donator_class_hash();
    let owner = donator_manager_contract.get_owner();
    assert(owner == OWNER(), 'Invalid owner');
    assert(donator_class_hash == expected_donator_address, 'Invalid donator class hash');
}

#[test]
fn test_new_donator() {
    start_cheat_caller_address_global(OWNER());
    let (contract_address, donator_class_hash) = __setup__();
    let donator_manager_contract = IDonatorManagerDispatcher { contract_address };
    donator_manager_contract.new_donator();
    let expected_donator_class_hash = get_class_hash(
        donator_manager_contract.get_donator_by_address(OWNER()),
    );
    assert(expected_donator_class_hash == donator_class_hash, 'Invalid donator address');
}

#[test]
fn test_emit_event_donator_contract_deployed() {
    start_cheat_caller_address_global(OWNER());
    let (contract_address, _) = __setup__();
    let donator_manager_contract = IDonatorManagerDispatcher { contract_address };
    let mut spy = spy_events();
    donator_manager_contract.new_donator();

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    DonatorManager::Event::DonatorContractDeployed(
                        DonatorManager::DonatorContractDeployed {
                            new_donator: donator_manager_contract.get_donator_by_address(OWNER()),
                            owner: OWNER(),
                        },
                    ),
                ),
            ],
        );
}
