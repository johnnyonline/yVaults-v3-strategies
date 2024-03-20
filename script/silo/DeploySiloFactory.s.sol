// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {ISiloRepository} from "@silo/interfaces/ISiloRepository.sol";

import {SiloStrategyFactory} from "../../src/strategies/silo/SiloStrategyFactory.sol";

import "forge-std/Script.sol";

// ---- Usage ----
// forge script script/silo/DeploySiloFactory.s.sol:DeploySiloFactory --verify --legacy --rpc-url $RPC_URL --broadcast

contract DeploySiloFactory is Script {

    ISiloRepository private constant REPO = ISiloRepository(0x8658047e48CC09161f4152c79155Dac1d710Ff0a); // https://devdocs.silo.finance/security/smart-contracts#silo-arbitrum

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        SiloStrategyFactory _factory = new SiloStrategyFactory(REPO);

        console.log("-----------------------------");
        console.log("factory deployed at: ", address(_factory));
        console.log("-----------------------------");

        vm.stopBroadcast();
    }
}