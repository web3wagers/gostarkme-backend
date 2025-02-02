// ***************************************************************************************
//                              DONATOR MAP RETRIEVAL TEST
// ***************************************************************************************
use starknet::{ContractAddress, contract_address_const};
use starknet::syscalls::call_contract_syscall;

use snforge_std::{
    declare, ContractClassTrait, start_cheat_caller_address_global, start_cheat_caller_address,
    stop_cheat_caller_address, cheat_caller_address, CheatSpan, spy_events, EventSpyAssertionsTrait,
};

use openzeppelin::utils::serde::SerializedAppend;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};


use gostarkme::fund::Fund;
use gostarkme::fund::IFundDispatcher;
use gostarkme::fund::IFundDispatcherTrait;
use gostarkme::constants::{fund_manager::{fund_manager_constants::FundManagerConstants}};
use gostarkme::constants::{funds::{fund_constants::FundStates}};
use gostarkme::constants::{funds::{fund_constants::FundTypeConstants}};
use gostarkme::constants::{starknet::{starknet_constants::StarknetConstants}};

const ONE_E18: u256 = 1000000000000000000_u256;

fn ID() -> u128 {
    1
}
fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}
fn OTHER_USER() -> ContractAddress {
    contract_address_const::<'USER'>()
}
fn FUND_MANAGER() -> ContractAddress {
    contract_address_const::<FundManagerConstants::FUND_MANAGER_ADDRESS>()
}
fn NAME() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn REASON_1() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum 1"
}
fn REASON_2() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum 2"
}
fn GOAL() -> u256 {
    1000
}
fn INITIAL_DONATION() -> u256 {
    0
}
fn EVIDENCE_LINK_1() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn EVIDENCE_LINK_2() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn CONTACT_HANDLE_1() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn CONTACT_HANDLE_2() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn VALID_ADDRESS_1() -> ContractAddress {
    contract_address_const::<FundManagerConstants::VALID_ADDRESS_1>()
}
fn VALID_ADDRESS_2() -> ContractAddress {
    contract_address_const::<FundManagerConstants::VALID_ADDRESS_2>()
}
fn _setup_() -> ContractAddress {
    let contract = declare("Fund").unwrap();
    let mut calldata: Array<felt252> = array![];
    calldata.append_serde(ID());
    calldata.append_serde(OWNER());
    calldata.append_serde(NAME());
    calldata.append_serde(GOAL());
    calldata.append_serde(EVIDENCE_LINK_1());
    calldata.append_serde(CONTACT_HANDLE_1());
    calldata.append_serde(REASON_1());
    calldata.append_serde(FundTypeConstants::PROJECT);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}
// ***************************************************************************************
//                              TEST
// ***************************************************************************************

#[test]
#[fork("Mainnet")]
fn test_get_donators_empty() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };

    // Retrieve the donators map
    let donators = dispatcher.get_donators();

    // Assert the map is empty
    assert(donators.len() == 0, 'Donators map should be empty');
}

#[test]
#[fork("Mainnet")]
fn test_get_single_donator() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let token_address = contract_address_const::<StarknetConstants::STRK_TOKEN_ADDRESS>();
    let token_dispatcher = IERC20Dispatcher { contract_address: token_address };
    let minter_address = contract_address_const::<StarknetConstants::STRK_TOKEN_MINTER_ADDRESS>();

    let donator1 = VALID_ADDRESS_1();
    let donation_amount: u256 = 100_u256 * ONE_E18;

    // Mint tokens and transfer to donator
    start_cheat_caller_address(token_address, minter_address);
    let mut calldata = array![];
    calldata.append_serde(donator1);
    calldata.append_serde(donation_amount);
    call_contract_syscall(token_address, selector!("permissioned_mint"), calldata.span()).unwrap();

    // Donate from donator
    start_cheat_caller_address(token_address, donator1);
    token_dispatcher.transfer(contract_address, donation_amount);
    dispatcher.update_receive_donation(donation_amount);

    // Retrieve the donators map
    // let donators = dispatcher.get_donators();
    let donatorinfo_1 = dispatcher.get_single_donator_by_address(donator1);

    // Assert the map contains the correct donator and amount
    assert(dispatcher.get_donators().len() == 1, 'Should have 1 entry');
    assert(donatorinfo_1.donator_amount == donation_amount, 'Donator 1 amount mismatch');
}

