// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {DEFLinearStreamCreator} from "src/DEFLinearStreamCreator.sol";

contract DeployDEFLinearStreamCreator is Script {
    // Sablier linear stream creator
    DEFLinearStreamCreator defLinearStreamCreator;

    function run() public {
        vm.broadcast();
        defLinearStreamCreator = new DEFLinearStreamCreator();
        console2.log(string.concat("  DEFLinearStreamCreator: ", vm.toString(address(defLinearStreamCreator))));
    }
}
