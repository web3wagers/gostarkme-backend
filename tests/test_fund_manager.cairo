// ***************************************************************************************
//                              FUND MANAGER TEST
// ***************************************************************************************
use starknet::{ContractAddress, contract_address_const};
use starknet::class_hash::{ClassHash};
use starknet::syscalls::deploy_syscall;

use snforge_std::{
    ContractClass, declare, ContractClassTrait, start_cheat_caller_address_global, get_class_hash,
    spy_events, EventSpyAssertionsTrait,
};

use openzeppelin::utils::serde::SerializedAppend;

use gostarkme::fund_manager::IFundManagerDispatcher;
use gostarkme::fund_manager::IFundManagerDispatcherTrait;
use gostarkme::fund_manager::FundManager;
use gostarkme::constants::{funds::{fund_constants::FundTypeConstants}};

fn ID() -> u128 {
    1
}
fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}
fn OTHER_USER() -> ContractAddress {
    contract_address_const::<'USER'>()
}
fn NAME() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn REASON() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn GOAL() -> u256 {
    1000
}
fn BAD_GOAL() -> u256 {
    4
}
fn EVIDENCE_LINK() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn CONTACT_HANDLE() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn _setup_() -> (ContractAddress, ClassHash) {
    // Fund
    let fund = declare("Fund").unwrap();
    let mut fund_calldata: Array<felt252> = array![];
    fund_calldata.append_serde(ID());
    fund_calldata.append_serde(OWNER());
    fund_calldata.append_serde(NAME());
    fund_calldata.append_serde(GOAL());
    fund_calldata.append_serde(EVIDENCE_LINK());
    fund_calldata.append_serde(CONTACT_HANDLE());
    fund_calldata.append_serde(REASON());
    fund_calldata.append_serde(FundTypeConstants::PROJECT);

    let (fund_contract_address, _) = fund.deploy(@fund_calldata).unwrap();
    let fund_class_hash = get_class_hash(fund_contract_address);

    // Fund Manager
    let fund_manager = declare("FundManager").unwrap();
    let mut fund_manager_calldata: Array<felt252> = array![];
    fund_manager_calldata.append_serde(fund_class_hash);
    let (contract_address, _) = fund_manager.deploy(@fund_manager_calldata).unwrap();

    return (contract_address, fund_class_hash);
}

// ******************************************************************************
//                              TEST
// ******************************************************************************

#[test]
fn test_constructor() {
    start_cheat_caller_address_global(OWNER());
    let (contract_address, fund_class_hash) = _setup_();
    let fund_manager_contract = IFundManagerDispatcher { contract_address };
    let expected_fund_address = fund_manager_contract.get_fund_class_hash();
    let owner = fund_manager_contract.get_owner();
    assert(owner == OWNER(), 'Invalid owner');
    assert(fund_class_hash == expected_fund_address, 'Invalid fund class hash');
}

#[test]
fn test_new_fund() {
    start_cheat_caller_address_global(OWNER());
    let (contract_address, fund_class_hash) = _setup_();
    let fund_manager_contract = IFundManagerDispatcher { contract_address };
    fund_manager_contract
        .new_fund(
            NAME(), GOAL(), EVIDENCE_LINK(), CONTACT_HANDLE(), REASON(), FundTypeConstants::PROJECT,
        );
    let expected_fund_class_hash = get_class_hash(fund_manager_contract.get_fund(1));
    let current_id = fund_manager_contract.get_current_id();
    assert(expected_fund_class_hash == fund_class_hash, 'Invalid fund address');
    assert(current_id == 2, 'Invalid current ID');
}

#[test]
#[should_panic(expected: 'Goal must be at least 500')]
fn test_new_fund_bad_goal() {
    start_cheat_caller_address_global(OWNER());
    let (contract_address, _) = _setup_();
    let fund_manager_contract = IFundManagerDispatcher { contract_address };
    fund_manager_contract
        .new_fund(
            NAME(),
            BAD_GOAL(),
            EVIDENCE_LINK(),
            CONTACT_HANDLE(),
            REASON(),
            FundTypeConstants::PROJECT,
        );
}

#[test]
fn test_fund_deployed_event() {
    let (contract_address, _) = _setup_();
    let fund_manager_contract = IFundManagerDispatcher { contract_address };

    start_cheat_caller_address_global(OWNER());

    let mut spy = spy_events();

    let current_id = fund_manager_contract.get_current_id();
    fund_manager_contract
        .new_fund(
            NAME(), GOAL(), EVIDENCE_LINK(), CONTACT_HANDLE(), REASON(), FundTypeConstants::PROJECT,
        );

    let expected_fund_class_hash = fund_manager_contract.get_fund(1);

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    FundManager::Event::FundDeployed(
                        FundManager::FundDeployed {
                            fund_address: expected_fund_class_hash,
                            fund_id: current_id,
                            owner: OWNER(),
                        },
                    ),
                ),
            ],
        );
}

