// ***************************************************************************************
//                              FUND TEST
// ***************************************************************************************
use starknet::{ContractAddress, contract_address_const};
use starknet::syscalls::call_contract_syscall;

use snforge_std::{
    declare, ContractClassTrait, start_cheat_caller_address_global, start_cheat_caller_address,
    stop_cheat_caller_address, cheat_caller_address, CheatSpan, spy_events, EventSpyAssertionsTrait
};

use openzeppelin::utils::serde::SerializedAppend;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};


use gostarkme::fund::Fund;
use gostarkme::fund::IFundDispatcher;
use gostarkme::fund::IFundDispatcherTrait;
use gostarkme::constants::{fund_manager::{fund_manager_constants::FundManagerConstants},};
use gostarkme::constants::{funds::{fund_constants::FundStates},};
use gostarkme::constants::{funds::{fund_constants::FundTypeConstants},};
use gostarkme::constants::{starknet::{starknet_constants::StarknetConstants},};

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
fn test_constructor() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let id = dispatcher.get_id();
    let owner = dispatcher.get_owner();
    let name = dispatcher.get_name();
    let reason = dispatcher.get_reason();
    let up_votes = dispatcher.get_up_votes();
    let goal = dispatcher.get_goal();
    let current_goal_state = dispatcher.get_current_goal_state();
    let state = dispatcher.get_state();
    assert(id == ID(), 'Invalid id');
    assert(owner == OWNER(), 'Invalid owner');
    assert(name == NAME(), 'Invalid name');
    assert(reason == REASON_1(), 'Invalid reason');
    assert(up_votes == 0, 'Invalid up votes');
    assert(goal == GOAL(), 'Invalid goal');
    assert(current_goal_state == 0, 'Invalid current goal state');
    assert(state == 1, 'Invalid state');
}

#[test]
fn test_set_name_admin() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let name = dispatcher.get_name();
    assert(name == NAME(), 'Invalid name');

    start_cheat_caller_address_global(VALID_ADDRESS_1());
    dispatcher.set_name("NEW_NAME_ADMIN_1");
    assert(dispatcher.get_name() == "NEW_NAME_ADMIN_1", 'Set name method not working');

    start_cheat_caller_address_global(VALID_ADDRESS_2());
    dispatcher.set_name("NEW_NAME_ADMIN_2");
    assert(dispatcher.get_name() == "NEW_NAME_ADMIN_2", 'Set name method not working');
}

#[test]
fn test_set_name_owner() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let name = dispatcher.get_name();
    assert(name == NAME(), 'Invalid name');

    start_cheat_caller_address_global(OWNER());
    dispatcher.set_name("NEW_NAME");
    let new_name = dispatcher.get_name();
    assert(new_name == "NEW_NAME", 'Set name method not working');
}

#[test]
#[should_panic(expected: ("You must be an owner or admin to perform this action",))]
fn test_set_name_unauthorized_access() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let name = dispatcher.get_name();
    assert(name == NAME(), 'Invalid name');

    start_cheat_caller_address_global(OTHER_USER());
    dispatcher.set_name("UNAUTHORIZED_NAME");
}

#[test]
#[should_panic(expected: ("You must be an owner or admin to perform this action",))]
fn test_set_name_not_admin_or_owner() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let name = dispatcher.get_name();
    assert(name == NAME(), 'Invalid name');

    start_cheat_caller_address_global(FUND_MANAGER());
    dispatcher.set_name("NEW_NAME");
    let new_name = dispatcher.get_name();
    assert(new_name == "NEW_NAME", 'Set name method not working');
}

#[test]
fn test_set_reason_owner() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let reason = dispatcher.get_reason();
    assert(reason == REASON_1(), 'Invalid reason');

    start_cheat_caller_address_global(OWNER());
    dispatcher.set_reason(REASON_2());
    let new_reason = dispatcher.get_reason();
    assert(new_reason == REASON_2(), 'Not allowed to change reason');
}

#[test]
fn test_set_reason_admins() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let reason = dispatcher.get_reason();
    assert(reason == REASON_1(), 'Invalid reason');

    // test with ADMIN_1
    start_cheat_caller_address_global(VALID_ADDRESS_1());
    dispatcher.set_reason(REASON_1());
    let new_reason = dispatcher.get_reason();
    assert(new_reason == REASON_1(), 'Not allowed to change reason');

    // test with ADMIN_2
    start_cheat_caller_address_global(VALID_ADDRESS_2());
    dispatcher.set_reason(REASON_2());
    let new_reason = dispatcher.get_reason();
    assert(new_reason == REASON_2(), 'Not allowed to change reason')
}

#[test]
fn test_set_goal_by_admins() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };

    let initial_goal = dispatcher.get_goal();
    assert(initial_goal == GOAL(), 'Initial goal is incorrect');

    start_cheat_caller_address_global(VALID_ADDRESS_1());
    dispatcher.set_goal(123);
    let updated_goal_1 = dispatcher.get_goal();
    assert(updated_goal_1 == 123, 'Failed to update goal');

    start_cheat_caller_address_global(VALID_ADDRESS_2());
    dispatcher.set_goal(456);
    let updated_goal_2 = dispatcher.get_goal();
    assert(updated_goal_2 == 456, 'Failed to update goal');
}

#[test]
#[should_panic(expected: ("Only Admins can set goal",))]
fn test_set_goal_unauthorized() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    // Change the goal as the fund manager, which shouldnt be authorized anymore
    start_cheat_caller_address_global(FUND_MANAGER());
    dispatcher.set_goal(22);
}

#[test]
fn test_receive_vote_successful() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    start_cheat_caller_address_global(OTHER_USER());
    dispatcher.receive_vote();
    let other_user_votes = dispatcher.get_voter(OTHER_USER());
    assert(other_user_votes == 1, 'Other user is not in the voters');
    let fund_votes = dispatcher.get_up_votes();
    assert(fund_votes == 1, 'Vote unuseccessful');
}

#[test]
#[should_panic(expected: ('User already voted!',))]
fn test_receive_vote_unsuccessful_double_vote() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    start_cheat_caller_address_global(OTHER_USER());
    dispatcher.receive_vote();
    let other_user_votes = dispatcher.get_voter(OTHER_USER());
    // User vote, fund have one vote
    assert(other_user_votes == 1, 'Owner is not in the voters');
    let votes = dispatcher.get_up_votes();
    assert(votes == 1, 'Vote unuseccessful');
    // User vote, second time
    dispatcher.receive_vote();
}

#[test]
fn test_new_vote_received_event_emitted_successful() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };

    let mut spy = spy_events();

    start_cheat_caller_address(contract_address, OTHER_USER());
    dispatcher.receive_vote();

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Fund::Event::NewVoteReceived(
                        Fund::NewVoteReceived {
                            voter: OTHER_USER(), fund: contract_address, votes: 1
                        }
                    )
                )
            ]
        );
}

#[test]
#[should_panic(expected: ("You must be an owner or admin to perform this action",))]
fn test_set_reason_unauthorized() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    // Change the reason without being authrorized
    dispatcher.set_reason("not stored reason");
}

#[test]
#[should_panic(expected: ("You are not the owner",))]
fn test_withdraw_with_wrong_owner() {
    let contract_address = _setup_();

    // call withdraw fn with wrong owner 
    start_cheat_caller_address_global(OTHER_USER());
    IFundDispatcher { contract_address }.withdraw();
}

#[test]
#[should_panic(expected: ('Fund not close goal yet.',))]
fn test_withdraw_with_non_closed_state() {
    let contract_address = _setup_();
    let fund_dispatcher = IFundDispatcher { contract_address };

    start_cheat_caller_address_global(VALID_ADDRESS_1());
    // set goal
    fund_dispatcher.set_goal(500_u256);

    start_cheat_caller_address_global(OWNER());
    // withdraw funds
    fund_dispatcher.withdraw();
}

#[test]
#[fork("Mainnet")]
fn test_withdraw() {
    let contract_address = _setup_();
    let goal: u256 = 500 * ONE_E18;

    let dispatcher = IFundDispatcher { contract_address };
    let minter_address = contract_address_const::<StarknetConstants::STRK_TOKEN_MINTER_ADDRESS>();
    let token_address = contract_address_const::<StarknetConstants::STRK_TOKEN_ADDRESS>();
    let token_dispatcher = IERC20Dispatcher { contract_address: token_address };

    //Set donation state
    start_cheat_caller_address(contract_address, VALID_ADDRESS_1());
    dispatcher.set_state(2);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, VALID_ADDRESS_1());
    dispatcher.set_goal(goal);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(token_address, minter_address);
    let mut calldata = array![];
    calldata.append_serde(FUND_MANAGER());
    calldata.append_serde(goal);
    call_contract_syscall(token_address, selector!("permissioned_mint"), calldata.span()).unwrap();
    stop_cheat_caller_address(token_address);

    assert(token_dispatcher.balance_of(FUND_MANAGER()) == goal, 'invalid balance');

    start_cheat_caller_address(token_address, FUND_MANAGER());
    token_dispatcher.transfer(contract_address, goal);
    stop_cheat_caller_address(token_address);

    assert(token_dispatcher.balance_of(contract_address) == goal, 'transfer failed');

    start_cheat_caller_address(contract_address, FUND_MANAGER());
    dispatcher.update_receive_donation(goal);
    stop_cheat_caller_address(contract_address);

    assert(dispatcher.get_state() == FundStates::CLOSED, 'state is not closed');
    assert(dispatcher.get_current_goal_state() == goal, 'goal not reached');

    start_cheat_caller_address(contract_address, OWNER());

    let withdrawn_amount = (goal * 95) / 100;
    let fund_manager_amount = (goal * 5) / 100;

    let owner_balance_before = token_dispatcher.balance_of(OWNER());
    let fund_balance_before = token_dispatcher.balance_of(contract_address);

    // withdraw
    dispatcher.withdraw();

    let owner_balance_after = token_dispatcher.balance_of(OWNER());
    let fund_balance_after = token_dispatcher.balance_of(contract_address);

    assert(
        owner_balance_after == (owner_balance_before + withdrawn_amount),
        'wrong owner balance after'
    );
    assert(
        (fund_balance_before - (withdrawn_amount + fund_manager_amount)) == fund_balance_after,
        'wrong fund balance'
    );
    assert(token_dispatcher.balance_of(VALID_ADDRESS_1()) == fund_manager_amount, 'wrong balance');
}

#[test]
fn test_set_evidence_link() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let evidence_link = dispatcher.get_evidence_link();
    assert(evidence_link == EVIDENCE_LINK_1(), 'Invalid evidence_link');
    start_cheat_caller_address_global(OWNER());
    dispatcher.set_evidence_link(EVIDENCE_LINK_2());
    let new_evidence_link = dispatcher.get_evidence_link();
    assert(new_evidence_link == EVIDENCE_LINK_2(), 'Set evidence method not working')
}

#[test]
#[should_panic(expected: ("You are not the owner",))]
fn test_set_evidence_link_wrong_owner() {
    let contract_address = _setup_();
    start_cheat_caller_address_global(OTHER_USER());
    IFundDispatcher { contract_address }.set_evidence_link(EVIDENCE_LINK_2());
}

#[test]
fn test_set_contact_handle_owner() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let contact_handle = dispatcher.get_contact_handle();
    assert(contact_handle == CONTACT_HANDLE_1(), 'Invalid contact handle');
    start_cheat_caller_address_global(OWNER());
    dispatcher.set_contact_handle(CONTACT_HANDLE_2());
    let new_contact_handle = dispatcher.get_contact_handle();
    assert(new_contact_handle == CONTACT_HANDLE_2(), 'Set contact method not working')
}

#[test]
fn test_set_contact_handle_admin_1() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let contact_handle = dispatcher.get_contact_handle();
    assert(contact_handle == CONTACT_HANDLE_1(), 'Invalid contact handle');
    start_cheat_caller_address_global(VALID_ADDRESS_1());
    dispatcher.set_contact_handle(CONTACT_HANDLE_2());
    let new_contact_handle = dispatcher.get_contact_handle();
    assert(new_contact_handle == CONTACT_HANDLE_2(), 'Set contact method not working')
}

#[test]
fn test_set_contact_handle_admin_2() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let contact_handle = dispatcher.get_contact_handle();
    assert(contact_handle == CONTACT_HANDLE_1(), 'Invalid contact handle');
    start_cheat_caller_address_global(VALID_ADDRESS_2());
    dispatcher.set_contact_handle(CONTACT_HANDLE_2());
    let new_contact_handle = dispatcher.get_contact_handle();
    assert(new_contact_handle == CONTACT_HANDLE_2(), 'Set contact method not working')
}

#[test]
#[should_panic(expected: ("You must be an owner or admin to perform this action",))]
fn test_set_contact_handle_wrong_owner_or_admin() {
    let contract_address = _setup_();
    start_cheat_caller_address_global(OTHER_USER());
    IFundDispatcher { contract_address }.set_contact_handle(CONTACT_HANDLE_2());
}

#[test]
#[fork("Mainnet")]
fn test_update_received_donation() {
    let contract_address = _setup_();

    let mut spy = spy_events();

    let strks: u256 = 500 * ONE_E18;

    let dispatcher = IFundDispatcher { contract_address };
    let minter_address = contract_address_const::<StarknetConstants::STRK_TOKEN_MINTER_ADDRESS>();
    let token_address = contract_address_const::<StarknetConstants::STRK_TOKEN_ADDRESS>();
    let token_dispatcher = IERC20Dispatcher { contract_address: token_address };

    start_cheat_caller_address(contract_address, VALID_ADDRESS_1());
    dispatcher.set_state(2);

    start_cheat_caller_address(contract_address, VALID_ADDRESS_1());
    dispatcher.set_goal(strks);

    start_cheat_caller_address(token_address, minter_address);
    let mut calldata = array![];
    calldata.append_serde(FUND_MANAGER());
    calldata.append_serde(strks);
    call_contract_syscall(token_address, selector!("permissioned_mint"), calldata.span()).unwrap();
    stop_cheat_caller_address(token_address);

    assert(token_dispatcher.balance_of(FUND_MANAGER()) == strks, 'invalid balance');

    start_cheat_caller_address(token_address, FUND_MANAGER());
    token_dispatcher.transfer(contract_address, strks);
    stop_cheat_caller_address(token_address);

    dispatcher.update_receive_donation(strks);

    let current_balance = dispatcher.get_current_goal_state();

    assert(dispatcher.get_state() == FundStates::CLOSED, 'state is not closed');
    assert(current_balance == strks, 'strks not reached');

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Fund::Event::DonationReceived(
                        Fund::DonationReceived {
                            current_balance,
                            donated_strks: strks,
                            donator_address: VALID_ADDRESS_1(),
                            fund_contract_address: contract_address,
                        }
                    )
                )
            ]
        );
}

#[test]
#[fork("Mainnet")]
fn test_emit_event_donation_withdraw() {
    let contract_address = _setup_();

    let mut spy = spy_events();

    let goal: u256 = 500 * ONE_E18;

    let dispatcher = IFundDispatcher { contract_address };
    let minter_address = contract_address_const::<StarknetConstants::STRK_TOKEN_MINTER_ADDRESS>();
    let token_address = contract_address_const::<StarknetConstants::STRK_TOKEN_ADDRESS>();
    let token_dispatcher = IERC20Dispatcher { contract_address: token_address };

    start_cheat_caller_address(contract_address, VALID_ADDRESS_1());
    dispatcher.set_state(2);

    start_cheat_caller_address(contract_address, VALID_ADDRESS_1());
    dispatcher.set_goal(goal);

    start_cheat_caller_address(token_address, minter_address);
    let mut calldata = array![];
    calldata.append_serde(FUND_MANAGER());
    calldata.append_serde(goal);
    call_contract_syscall(token_address, selector!("permissioned_mint"), calldata.span()).unwrap();
    stop_cheat_caller_address(token_address);

    assert(token_dispatcher.balance_of(FUND_MANAGER()) == goal, 'invalid balance');

    start_cheat_caller_address(token_address, FUND_MANAGER());
    token_dispatcher.transfer(contract_address, goal);
    stop_cheat_caller_address(token_address);

    dispatcher.update_receive_donation(goal);

    let current_balance = dispatcher.get_current_goal_state();

    assert(dispatcher.get_state() == FundStates::CLOSED, 'state is not closed');
    assert(current_balance == goal, 'goal not reached');

    start_cheat_caller_address(contract_address, OWNER());

    let withdrawn_amount = (goal * 95) / 100;

    dispatcher.withdraw();

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Fund::Event::DonationWithdraw(
                        Fund::DonationWithdraw {
                            owner_address: OWNER(),
                            fund_contract_address: contract_address,
                            withdrawn_amount
                        }
                    )
                )
            ]
        );
}


#[test]
#[should_panic(expected: ("You must be an owner or admin to perform this action",))]
fn test_set_contact_handle_error() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let contact_handle = dispatcher.get_contact_handle();
    assert(contact_handle == CONTACT_HANDLE_1(), 'Invalid contact handle');

    start_cheat_caller_address_global(OTHER_USER());
    dispatcher.set_contact_handle(CONTACT_HANDLE_2())
}

#[test]
fn test_set_contact_handle_success() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let contact_handle = dispatcher.get_contact_handle();
    assert(contact_handle == CONTACT_HANDLE_1(), 'Invalid contact handle');

    start_cheat_caller_address_global(OWNER());
    dispatcher.set_contact_handle(CONTACT_HANDLE_2());
    let new_contact_handle = dispatcher.get_contact_handle();
    assert(new_contact_handle == CONTACT_HANDLE_2(), 'Set contact method not working');
    dispatcher.set_contact_handle(CONTACT_HANDLE_1());
    let reverted_contact_handle = dispatcher.get_contact_handle();
    assert(reverted_contact_handle == CONTACT_HANDLE_1(), 'revert');

    start_cheat_caller_address_global(VALID_ADDRESS_1());
    dispatcher.set_contact_handle(CONTACT_HANDLE_2());
    let new_contact_handle = dispatcher.get_contact_handle();
    assert(new_contact_handle == CONTACT_HANDLE_2(), 'Set contact method not working');
    dispatcher.set_contact_handle(CONTACT_HANDLE_1());
    let reverted_contact_handle = dispatcher.get_contact_handle();
    assert(reverted_contact_handle == CONTACT_HANDLE_1(), 'revert');

    start_cheat_caller_address_global(VALID_ADDRESS_2());
    dispatcher.set_contact_handle(CONTACT_HANDLE_2());
    let new_contact_handle = dispatcher.get_contact_handle();
    assert(new_contact_handle == CONTACT_HANDLE_2(), 'Set contact method not working');
    dispatcher.set_contact_handle(CONTACT_HANDLE_1());
    let reverted_contact_handle = dispatcher.get_contact_handle();
    assert(reverted_contact_handle == CONTACT_HANDLE_1(), ' revert ')
}

#[test]
fn test_set_type() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let current_type = dispatcher.get_type();
    assert(current_type == FundTypeConstants::PROJECT, 'Invalid type');
    start_cheat_caller_address(contract_address, VALID_ADDRESS_1());
    dispatcher.set_type(FundTypeConstants::CHARITY);
    let new_type = dispatcher.get_type();
    assert(new_type == FundTypeConstants::CHARITY, 'Set type method not working');
    start_cheat_caller_address(contract_address, VALID_ADDRESS_2());
    dispatcher.set_type(FundTypeConstants::PROJECT);
    let new_type = dispatcher.get_type();
    assert(new_type == FundTypeConstants::PROJECT, 'Set type method not working');
}

#[test]
#[fork("Mainnet")]
fn test_get_single_donator_by_address() {
    let contract_address = setup();
    let dispatcher = IFundDispatcher { contract_address };

    let donator_address = VALID_ADDRESS_1();

    let donator_info = dispatcher.get_single_donator_by_address(donator_address);
    assert(donator_info.donator_index == 0, 'Donator index should not exist');
    assert(donator_info.donator_amount == 0, 'Donator amount should not exist');

    let strks: u256 = 500 * ONE_E18;
    start_cheat_caller_address(contract_address, OWNER());
    dispatcher.update_receive_donation(strks);

    let donator_info = dispatcher.get_single_donator_by_address(OWNER());
    assert(donator_info.donator_index == 1, 'Donator index should exist');
    assert(donator_info.donator_amount == strks, 'Donator amount should exist');

    dispatcher.update_receive_donation(strks);
    let donator_info = dispatcher.get_single_donator_by_address(OWNER());
    assert(donator_info.donator_index == 1, 'Donator index should exist');
    assert(donator_info.donator_amount == (strks * 2), 'Donator amount should exist');
}