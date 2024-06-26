// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {ud60x18} from "@prb/math/src/UD60x18.sol";
import {ISablierV2LockupLinear} from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import {Broker, LockupLinear} from "@sablier/v2-core/src/types/DataTypes.sol";

/// @title DEFLinearStreamCreator
/// @notice This contract creates a new LockupLinear stream on Sablier for the Defi Education Fund through Uniswap Governance.
/// @dev This contract needs an approval of `totalAmount` UNI tokens before calling `createStream`.
contract DEFLinearStreamCreator {
    /// @notice Uniswap Token
    IERC20 public constant UNI = IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

    /// @notice Stream Canceler: Uniswap Governance
    address public constant UNISWAP_TIMELOCK = 0x1a9C8182C09F50C8318d769245beA52c32BE35BC;

    /// @notice Stream Recipient: Defi Education Fund
    address public constant DEF_RECIPIENT = 0x54865956Ba372DA101D6AeEeF18d602b77c871a6;

    /// @notice Sablier LockupLinear contract
    ISablierV2LockupLinear public constant SABLIER_V2_LOCKUP_LINEAR =
        ISablierV2LockupLinear(0xAFb979d9afAd1aD27C5eFf4E27226E3AB9e5dCC9);

    /// @dev Thrown when an address other than the Uniswap Timelock tries to call a function.
    error OnlyUniswapTimelock();

    /// @notice Creates a new LockupLinear stream on Sablier for the Defi Education Fund through Uniswap Governance.
    /// @param totalAmount The total amount of UNI tokens to be streamed.
    /// @return streamId The ID of the newly created stream.
    function createStream(uint128 totalAmount) external returns (uint256 streamId) {
        // Ensure that the caller is the Uniswap Timelock
        if (msg.sender != UNISWAP_TIMELOCK) {
            revert OnlyUniswapTimelock();
        }
        // Transfer the provided amount of UNI tokens to this contract
        UNI.transferFrom(msg.sender, address(this), totalAmount);

        // Approve the Sablier contract to spend UNI
        UNI.approve(address(SABLIER_V2_LOCKUP_LINEAR), totalAmount);

        // Declare the params struct
        LockupLinear.CreateWithDurations memory params;

        // Declare the function parameters
        params.sender = UNISWAP_TIMELOCK; // The sender will be able to cancel the stream
        params.recipient = DEF_RECIPIENT; // The recipient of the streamed assets
        params.totalAmount = totalAmount; // Total amount is the amount inclusive of all fees
        params.asset = UNI; // The streaming asset
        params.cancelable = true; // Whether the stream will be cancelable or not
        params.transferable = false; // Whether the stream will be transferable or not
        params.durations = LockupLinear.Durations({
            cliff: 0, // No cliff
            total: 365 days // Setting a total duration of ~1 year
         });
        params.broker = Broker(address(0), ud60x18(0)); // Optional parameter for charging a fee. No fee.

        // Create the LockupLinear stream using a function that sets the start time to `block.timestamp`
        streamId = SABLIER_V2_LOCKUP_LINEAR.createWithDurations(params);
    }
}
