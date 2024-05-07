// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {ud60x18} from "@prb/math/src/UD60x18.sol";
import {ISablierV2LockupLinear} from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import {Lockup, LockupLinear} from "@sablier/v2-core/src/types/DataTypes.sol";

import {DeployDEFLinearStreamCreator} from "script/DeployDEFLinearStreamCreator.s.sol";
import {DEFLinearStreamCreator} from "src/DEFLinearStreamCreator.sol";
import {IUniswapGoverrnor} from "test/interfaces/IUniswapGovernor.sol";

contract UniswapDEFProposalTest is Test,  DeployDEFLinearStreamCreator {
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL"); // can't use constant here

    IUniswapGoverrnor public constant UNISWAP_GOVERNOR = IUniswapGoverrnor(0x408ED6354d4973f66138C91495F2f2FCbd8724C3);
    address public constant UNISWAP_TIMELOCK = 0x1a9C8182C09F50C8318d769245beA52c32BE35BC;
    IERC20 public constant UNISWAP_TOKEN = IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

    ISablierV2LockupLinear public constant SABLIER_V2_LOCKUP_LINEAR =
        ISablierV2LockupLinear(0xAFb979d9afAd1aD27C5eFf4E27226E3AB9e5dCC9);

    uint256 public constant INITIAL_UNI_AMOUNT = 500_000e18;
    uint256 public constant VESTING_UNI_AMOUNT = 500_000e18;
    address public constant DEF_COINBASE_CUSTODY_WALLET = 0xb39cb7Eb25CE07470Fb59F7548979Fae0Bb85824;
    // TODO: Update this value once the instance has been deployed.
    address public constant DEF_LLAMA_EXECUTOR = address(0xCAFE);
    address public constant DEF_LLAMA_ACCOUNT = address(0xdeadbeef);

    string public constant DESCRIPTION = "Defi Eduction Fund Proposal";

    address public constant MOCK_UNISWAP_PROPOSER = 0x8E4ED221fa034245F14205f781E0b13C5bd6a42E;

    address[] private uniWhales = [
        0x8E4ED221fa034245F14205f781E0b13C5bd6a42E,
        0x76f54Eeb0D33a2A2c5CCb72FE12542A56f35d67C,
        0xe7925D190aea9279400cD9a005E33CEB9389Cc2b,
        0x1d8F369F05343F5A642a78BD65fF0da136016452,
        0xe02457a1459b6C49469Bf658d4Fe345C636326bF,
        0x88E15721936c6eBA757A27E54e7aE84b1EA34c05,
        0x8962285fAac45a7CBc75380c484523Bb7c32d429,
        0xcb70D1b61919daE81f5Ca620F1e5d37B2241e638,
        0x88FB3D509fC49B515BFEb04e23f53ba339563981,
        0x683a4F9915D6216f73d6Df50151725036bD26C02
    ];

    // Proposal ID of the Uniswap Proposal
    uint256 proposalID;
    // Stream ID of the Sablier Linear Stream
    uint256 streamID;

    function setUp() public {
        vm.createSelectFork(MAINNET_RPC_URL, 19_820_072);

        // Deploy the DEF Linear Stream Creator contract
        DeployDEFLinearStreamCreator.run();

        // Run the Uniswap Proposal
        _runUniswapProposal();

        // Get the next stream ID of the Sablier Linear Stream
        streamID = SABLIER_V2_LOCKUP_LINEAR.nextStreamId();
    }

    // =========================
    // ======== Helpers ========
    // =========================

    function _runUniswapProposal() internal {
        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        string[] memory signatures = new string[](3);
        bytes[] memory calldatas = new bytes[](3);

        // Transfer 500k UNI upfront to DEF Coinbase Custody Wallet
        targets[0] = address(UNISWAP_TOKEN);
        values[0] = uint256(0);
        signatures[0] = "transfer(address,uint256)";
        calldatas[0] = abi.encode(DEF_COINBASE_CUSTODY_WALLET, INITIAL_UNI_AMOUNT);

        // Approve the DEFLinearStreamCreator contract to create a Sablier Linear Stream of 500k UNI over 1 year.
        targets[1] = address(UNISWAP_TOKEN);
        values[1] = uint256(0);
        signatures[1] = "approve(address,uint256)";
        calldatas[1] = abi.encode(address(defLinearStreamCreator), VESTING_UNI_AMOUNT);

        // Call `DEFLinearStreamCreator.createStream` to create a Sablier Linear Stream of 500k UNI over 1 year.
        targets[2] = address(defLinearStreamCreator);
        values[2] = uint256(0);
        signatures[2] = "createStream(uint128)";
        calldatas[2] = abi.encode(VESTING_UNI_AMOUNT);

        // Create Uniswap Proposal and run governance.
        _uniswapCreateProposal(targets, values, signatures, calldatas, DESCRIPTION);
        _uniswapVoteOnProposal();
        _uniswapSkipVotingPeriod();
        _uniswapQueueProposal();
        _uniswapSkipQueuePeriod();
    }

    function _uniswapCreateProposal(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) internal {
        // Proposer that has > 1M UNI votes
        vm.prank(MOCK_UNISWAP_PROPOSER);
        proposalID = UNISWAP_GOVERNOR.propose(targets, values, signatures, calldatas, description);
    }

    function _uniswapVoteOnProposal() internal {
        (, , , uint256 startBlock, , , , , ,) = UNISWAP_GOVERNOR.proposals(proposalID);
        // Skipping Proposal delay of 2 days worth of blocks
        vm.roll(startBlock + 1);
        // Hitting quorum of > 40M UNI votes
        for (uint256 i; i < uniWhales.length; i++) {
            vm.prank(uniWhales[i]);
            UNISWAP_GOVERNOR.castVote(proposalID, uint8(1));
        }
    }

    function _uniswapSkipVotingPeriod() internal {
        (, , , , uint256 endBlock, , , , ,) = UNISWAP_GOVERNOR.proposals(proposalID);
        // Skipping Voting period of 6 days worth of blocks
        vm.roll(endBlock + 1);
    }

    function _uniswapQueueProposal() internal {
        UNISWAP_GOVERNOR.queue(proposalID);
    }

    function _uniswapSkipQueuePeriod() internal {
        (, , uint256 eta, , , , , , ,) = UNISWAP_GOVERNOR.proposals(proposalID);
        // Skipping Queue period
        vm.warp(eta);
    }

    function _uniswapExecuteProposal() internal {
        UNISWAP_GOVERNOR.execute(proposalID);
    }

    // =======================
    // ======== Tests ========
    // =======================

    function test_UniswapDEFProposal() public {
        uint256 initialUniswapTimelockUNIBalance = UNISWAP_TOKEN.balanceOf(UNISWAP_TIMELOCK);
        uint256 initialDEFCoinbaseCustodyWalletUNIBalance = UNISWAP_TOKEN.balanceOf(DEF_COINBASE_CUSTODY_WALLET);

        _uniswapExecuteProposal();

        assertEq(UNISWAP_TOKEN.balanceOf(UNISWAP_TIMELOCK), initialUniswapTimelockUNIBalance - (INITIAL_UNI_AMOUNT + VESTING_UNI_AMOUNT));
        assertEq(UNISWAP_TOKEN.balanceOf(DEF_COINBASE_CUSTODY_WALLET), initialDEFCoinbaseCustodyWalletUNIBalance + INITIAL_UNI_AMOUNT);

        assertEq(uint8(SABLIER_V2_LOCKUP_LINEAR.statusOf(streamID)), uint8(Lockup.Status.STREAMING));
        assertEq(SABLIER_V2_LOCKUP_LINEAR.getSender(streamID), UNISWAP_TIMELOCK);
        assertEq(SABLIER_V2_LOCKUP_LINEAR.getRecipient(streamID), DEF_LLAMA_EXECUTOR);
        assertEq(SABLIER_V2_LOCKUP_LINEAR.getDepositedAmount(streamID), VESTING_UNI_AMOUNT);
        assertEq(address(SABLIER_V2_LOCKUP_LINEAR.getAsset(streamID)), address(UNISWAP_TOKEN));
        assertTrue(SABLIER_V2_LOCKUP_LINEAR.isCancelable(streamID));
        assertFalse(SABLIER_V2_LOCKUP_LINEAR.isTransferable(streamID));
        assertEq(SABLIER_V2_LOCKUP_LINEAR.getRange(streamID).start, block.timestamp);
        assertEq(SABLIER_V2_LOCKUP_LINEAR.getRange(streamID).cliff, block.timestamp);
        assertEq(SABLIER_V2_LOCKUP_LINEAR.getRange(streamID).end, block.timestamp + 365 days);
    }

    function test_RevertIf_NotUniswapTimelock() public {
        vm.expectRevert(DEFLinearStreamCreator.OnlyUniswapTimelock.selector);
        defLinearStreamCreator.createStream(uint128(VESTING_UNI_AMOUNT));
    }
}
