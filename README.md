# DEF Uniswap Proposal

## Proposal Details

### Snapshot

https://snapshot.org/#/uniswapgovernance.eth/proposal/0xf17f3ca6b3d1aa6d8061a733fc0d627558159e0057f76ddfe056ea492cf56163

### Forum Post

https://gov.uniswap.org/t/temperature-check-supporting-the-defi-education-fund/23631

### Uniswap Proposal Actions

1. Transfer 500k UNI from [`UNISWAP_GOV_TIMELOCK`](https://etherscan.io/address/0x1a9C8182C09F50C8318d769245beA52c32BE35BC) to DEF Coinbase Custody wallet: [`0xb39cb7Eb25CE07470Fb59F7548979Fae0Bb85824`](https://etherscan.io/address/0xb39cb7Eb25CE07470Fb59F7548979Fae0Bb85824)
2. Approve 500k UNI for `DEFLinearStreamCreator` from [`UNISWAP_GOV_TIMELOCK`](https://etherscan.io/address/0x1a9C8182C09F50C8318d769245beA52c32BE35BC)
3. Call `DEFLinearStreamCreator.createStream` for 500k UNI.

## Prerequisites

[Foundry](https://github.com/foundry-rs/foundry) must be installed.
You can find installation instructions in the [Foundry docs](https://book.getfoundry.sh/getting-started/installation).

We use [just](https://github.com/casey/just) to save and run a few larger, more complex commands.
You can find installation instructions in the [just docs](https://just.systems/man/en/).
All commands can be listed by running `just -l` from the repo root, or by viewing the [`justfile`](https://github.com/llamaxyz/def-uniswap-proposal/blob/main/justfile).

### VS Code

You can get Solidity support for Visual Studio Code by installing the [Hardhat Solidity extension](https://github.com/NomicFoundation/hardhat-vscode).

## Installation

```sh
$ git clone https://github.com/llamaxyz/def-uniswap-proposal.git
$ cd def-uniswap-proposal
$ forge install
```

## Setup

Copy `.env.example` and rename it to `.env`.
The comments in that file explain what each variable is for and when they're needed:

- The `MAINNET_RPC_URL` variable is the only one that is required for running tests.
- You may also want a mainnet `ETHERSCAN_API_KEY` for better traces when running fork tests.
- The rest are only needed for deployment verification with forge scripts. An anvil default private key is provided in the `.env.example` file to facilitate testing.

### Commands

- `forge build` - build the project
- `forge test` - run tests

### Deploy and Verify

- `just deploy` - deploy and verify payload on mainnet
- Run `just -l` or see the [`justfile`](https://github.com/llamaxyz/def-uniswap-proposal/blob/main/justfile) for other commands such as dry runs.
