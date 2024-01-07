pragma solidity ^0.8.20;
//SPDX-License-Identifier: MIT

import "../../src/nft-manager/gangManager.sol";
import "../../src/nft-guarantor/gangGuarantor.sol";
import "../../src/nft-crowdfund/gangCrowdFund.sol";
import "../../src/nft-crowdfund/IGangCrowdFund.sol";
import "../../src/weth/IWETH.sol";

import "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

contract deployGangCrowdfund is Script {
    // gangCrowdFund config
    GangCrowdFund public nftCrowdFund;
    // gangManager config
    GangManager public nftManager;
    // gangGuarantor config
    GangGaurantor public nftGuarantor;

    function run() external {
        //create a new fork from sepolia
        uint256 forkId = vm.createFork(vm.envString("SEPOLIA_RPC_URL"));
        vm.selectFork(forkId);
        //start the broadcast
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // sepolia admin account
        string memory _admin = vm.envString("ADMIN_ACCOUNT");
        address payable admin = payable(vm.parseAddress(_admin));

        //deploy the contract

        // vm.startPrank(admin);
        // Gang Gaurantor setup
        nftGuarantor = new GangGaurantor(
            address(0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9)
        );

        // GangCrowdFund setup
        GangCrowdFund.GangCrowdFundOpts memory crowdFundOpts;
        crowdFundOpts = GangCrowdFund.GangCrowdFundOpts(
            "chickenGangGang",
            "CGG",
            address(nftGuarantor),
            15, // investPhase
            20, // investorsWithdrawPhase
            20, // investorsExitPhase
            200, // investorRevenueShare
            200, // investorRoyaltyShare
            750, // projectOwnerRevenueShare
            750, // projectOwnerRoyaltyShare
            50, // guarantorRevenueShare
            50, // guarantorRoyaltyShare
            0.01 ether, // floorPrice
            0.001 ether, // fee
            200, // insuranceThreshold
            0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9 // weth address
        );
        nftCrowdFund = new GangCrowdFund(crowdFundOpts);
        GangManager.GangManagerOpts memory gangManagerOpts;
        gangManagerOpts = GangManager.GangManagerOpts(
            "NFTManager", // name
            "NFTM", // symbol
            address(nftGuarantor), // guarantor
            admin, // manager
            100, // ownerRevenueShare
            100, // guarantorRevenueShare
            100, // managerRevenueShare
            700, // investorRevenueShare
            200, // insuranceThreshold
            10, // investPhase
            20, // managerInvestPhase
            10, //investorRedeemPhase
            0, //goal
            200, // maximuInvestPercentage
            true, // managerOnlyInvestVerified
            true, // managerOnlyInvestGangCrowdFund
            0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9 // weth address
        );
        nftManager = new GangManager(gangManagerOpts);
        // vm.stopPrank();
        vm.stopBroadcast();
    }
}
