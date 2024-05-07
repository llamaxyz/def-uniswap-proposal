// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";

import {DeployDEFLinearStreamCreator} from "script/DeployDEFLinearStreamCreator.s.sol";

import {DEFLinearStreamCreator} from "src/DEFLinearStreamCreator.sol";

contract UniswapDEFProposalTest is Test,  DeployDEFLinearStreamCreator {
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL"); // can't use constant here
    address DEF_LLAMA_EXECUTOR = address(0xCAFE);
    address DEF_LLAMA_ACCOUNT = address(0xdeadbeef);

    function setUp() public {
        vm.createSelectFork(MAINNET_RPC_URL, 19_820_072);

        // Deploy the DEF Linear Stream Creator contract
        DeployDEFLinearStreamCreator.run();
    }
}
