pragma solidity ^0.8.24;

import { SafeDeployments } from "./Constants.sol";
import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { SafeCreditAccountFactory } from "../../src/safe/CreditAccountFactory.sol";

contract CreditAccountFactory is Script {
    function run() public {
        // string memory mnemonic = vm.envString("DEPLOYER_SEED_PHRASE");
        // (address deployer,) = deriveRememberKey(mnemonic, 0);

        // console2.log("deployer", deployer);

        // vm.startBroadcast(deployer);
        // SafeCreditAccountFactory factory = new SafeCreditAccountFactory(
        //     deployer,
        //     SafeDeployments.SAFE_PROXY_FACTORY_ADDRESS,
        //     SafeDeployments.SAFE_SINGLETON_ADDRESS,
        //     SafeDeployments.MULTI_SEND_CALL_ONLY_ADDRESS,
        //     address(0)
        // );

        // address[] memory owners = new address[](1);
        // owners[0] = deployer;
        // uint256 threshold = 1;

        // address creditAccount = factory.deployCreditAccount(owners, threshold);

        // console2.log("CreditAccount deployed at", creditAccount);

        // vm.stopBroadcast();
    }
}
