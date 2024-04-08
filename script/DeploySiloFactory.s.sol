// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {ISiloRepository} from "@silo/interfaces/ISiloRepository.sol";

import {SiloStrategyFactory} from "../src/strategies/silo/SiloStrategyFactory.sol";

import "forge-std/Script.sol";

// ---- Usage ----
// forge script script/DeploySiloFactory.s.sol:DeploySiloFactory --verify --legacy --etherscan-api-key $KEY --rpc-url $RPC_URL --broadcast

// verify:
// --constructor-args $(cast abi-encode "constructor(address,address,address,address,string)" 0xae1Eb69e880670Ca47C50C9CE712eC2B48FaC3b6 0x00CcE18E859aCdDe4c949852E67c20510F2768a5 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8 0xd592F705bDC8C1B439Bd4D665Ed99C4FaAd5A680 "USDC.e/SILO Silo LP")
// forge verify-contract --etherscan-api-key $KEY --watch --chain-id 42161 --compiler-version v0.8.18+commit.87f61d96 --verifier-url https://api.arbiscan.io/api 0x9a5eca1b228e47a15BD9fab07716a9FcE9Eebfb5 src/ERC404/BaseERC404.sol:BaseERC404

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