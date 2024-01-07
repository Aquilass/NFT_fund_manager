//spdx-license-identifier: MIT
pragma solidity ^0.8 .19;

import "../src/nft-manager/gangManager.sol";
import "../src/nft-guarantor/gangGuarantor.sol";
import "../src/nft-crowdfund/gangCrowdFund.sol";
import "../src/nft-crowdfund/IGangCrowdFund.sol";
import "../src/weth/IWETH.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

contract gangManagerTest is Test {
    // gangCrowdFund config
    GangCrowdFund public nftCrowdFund;
    // gangManager config
    GangManager public nftManager;
    // gangGuarantor config
    GangGaurantor public nftGuarantor;

    address public gangCrowdFundOwner = makeAddr("gangCrowdFundOwner");
    address public gangManager = makeAddr("gangManager");
    address public gangManagerOwner = makeAddr("gangManagerOwner");
    address public guarantor = makeAddr("guarantor");
    // GangManagerOpts public opts;
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");

    function setUp() public {
        // vm config
        uint256 forkId = vm.createFork(vm.envString("SEPOLIA_RPC_URL"));
        // vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        vm.selectFork(forkId);
        // role setUp
        deal(guarantor, 1000 ether);
        deal(user1, 1000 ether);
        deal(user2, 10000 ether);
        deal(user3, 1000 ether);
        // GangCrowdFund setup
        vm.startPrank(guarantor);
        // Gang Gaurantor setup
        nftGuarantor = new GangGaurantor(
            address(0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9)
        );
        vm.stopPrank();

        vm.startPrank(gangCrowdFundOwner);
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
        nftCrowdFund.setTokenURI(1, "https://ipfs.test.com");
        vm.stopPrank();

        // GangManager setup need to import GangManagerOpts to use it
        vm.startPrank(gangManagerOwner);
        GangManager.GangManagerOpts memory gangManagerOpts;
        gangManagerOpts = GangManager.GangManagerOpts(
            "NFTManager", // name
            "NFTM", // symbol
            address(nftGuarantor), // guarantor
            gangManager, // manager
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
        vm.stopPrank();
        // GangGaurantor approve
        vm.startPrank(guarantor);
        IWETH(address(0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9)).deposit{value: 1000 ether}();
        IWETH(address(0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9)).transfer(address(nftGuarantor), 1000 ether);
        nftGuarantor.addVerifiedGangCrowdFund(address(nftCrowdFund), 100 ether);
        nftGuarantor.addVerifiedGangManager(address(nftManager), 100 ether);
        vm.stopPrank();
    }

    function test_init() public {
        // gangCrowdFund

        // gangManager
        (address guarantor, address manager, address owner) = nftManager.getRole();
    }

    function test_guarantor_functions() public {
        vm.startPrank(guarantor);
        nftGuarantor.addVerifiedGangCrowdFund(address(nftCrowdFund), 100 ether);
        nftGuarantor.addVerifiedGangManager(address(nftManager), 100 ether);
        vm.stopPrank();
        vm.startPrank(guarantor);
        nftGuarantor.removeVerifiedGangCrowdFund(address(nftCrowdFund));
        nftGuarantor.removeVerifiedGangManager(address(nftManager));
        vm.stopPrank();
    }

    function test_CrowdFund_invest_withdraw() public {
        vm.startPrank(user1);
        vm.expectRevert();
        nftCrowdFund.invest();
        nftCrowdFund.invest{value: 1 ether}();

        vm.roll(block.number + 16);
        vm.expectRevert();
        nftCrowdFund.invest{value: 1 ether}();
        uint256 investment = nftCrowdFund.getInvestment(user1);
        vm.roll(block.number + 23);
        nftCrowdFund.getCrowdfundPhase();
        nftCrowdFund.investorWithdrawInvest(investment);
        assertEq(nftCrowdFund.getInvestment(user1), 0 ether);
        assertEq(address(user1).balance, 1000 ether);
    }

    function testMint() public {
        vm.startPrank(user1);
        nftCrowdFund.invest{value: 1 ether}();

        vm.stopPrank();
        vm.startPrank(user2);
        nftCrowdFund.invest{value: 1 ether}();

        vm.roll(block.number + 16);
        nftCrowdFund.mint{value: 0.01 ether}(user2, 1);

        vm.stopPrank();
        // vm.roll(3);
        vm.startPrank(user1);
        uint256 investment = nftCrowdFund.getInvestment(user1);
        nftCrowdFund.investorWithdrawRevenue();
        // nftCrowdFund.investorWithdrawRevenue();
        assertEq(nftCrowdFund.alreadyWithdrawRevenue(user1), 1e15);
    }

    function test_crowdfund_mint_transfer_withdraw() public {
        vm.startPrank(gangCrowdFundOwner);
        nftCrowdFund.setFee(1 ether);
        nftCrowdFund.setFloorPrice(1 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        nftCrowdFund.invest{value: 1 ether}();
        vm.stopPrank();

        vm.startPrank(user2);
        nftCrowdFund.invest{value: 1 ether}();
        vm.stopPrank();

        vm.startPrank(gangCrowdFundOwner);
        nftCrowdFund.projectOwnerWithdrawInvest();
        vm.stopPrank();

        assertEq(address(nftCrowdFund).balance, 0 ether);
        vm.roll(block.number + 16);

        vm.startPrank(user2);
        nftCrowdFund.mint{value: 1 ether}(user2, 1);
        nftCrowdFund.transferFrom{value: 1 ether}(user2, user1, 1);
        nftCrowdFund.mint{value: 1 ether}(user2, 2);
        nftCrowdFund.safeTransferFrom{value: 1 ether}(user2, user1, 2);
        nftCrowdFund.mint{value: 1 ether}(user2, 3);
        nftCrowdFund.safeTransferFrom{value: 1 ether}(user2, user1, 3, "");
        vm.stopPrank();

        vm.startPrank(user1);
        nftCrowdFund.investorWithdrawRevenue();

        // assertEq(nftCrowdFund.alreadyWithdrawRevenue(user1), 0.9 ether);
        vm.stopPrank();
        vm.startPrank(user2);
        nftCrowdFund.investorWithdrawRevenue();

        // assertEq(nftCrowdFund.alreadyWithdrawRevenue(user2), 0.9 ether);
        vm.stopPrank();
        vm.roll(block.number + 21);
        vm.startPrank(gangCrowdFundOwner);
        nftCrowdFund.projectOwnerAndGuarantorWithdrawRevenue();
        assertEq(address(nftCrowdFund).balance, 0 ether);
        vm.stopPrank();
    }

    function test_manager_invest_withdraw_crowdfund() public {
        vm.startPrank(user2);
        nftCrowdFund.invest{value: 1 ether}();
        vm.stopPrank();
        vm.startPrank(user3);
        nftCrowdFund.invest{value: 1 ether}();
        vm.stopPrank();
        vm.roll(block.number + 2);
        vm.startPrank(user1);
        nftManager.investorInvest{value: 1 ether}(address(user1));
        vm.stopPrank();
        vm.roll(block.number + 10);
        vm.startPrank(gangManager);
        bytes memory data = abi.encodeWithSelector(IGangCrowdFund.invest.selector);
        address payable callTarget = payable(address(nftCrowdFund));
        nftManager.managerOperations(callTarget, 0.1 ether, data);
        bytes memory withdrawData = abi.encodeWithSignature("investManagerWithdrawInvest(uint256)", 0.1 ether);
        nftManager.managerOperations(callTarget, 0 ether, withdrawData);
        // invest again
        nftManager.managerOperations(callTarget, 0.1 ether, data);
        vm.roll(block.number + 10);
        //managerWithdrawRevenue
        bytes memory withdrawRevenueData = abi.encodeWithSignature("investManagerWithdrawRevenue()");
        nftManager.managerOperations(callTarget, 0 ether, withdrawRevenueData);
        vm.stopPrank();
    }

    function test_manager_whole_process_with_profit() public {
        // crowdFund invest
        vm.startPrank(user2);
        nftCrowdFund.invest{value: 1 ether}();
        vm.stopPrank();
        vm.startPrank(user1);
        nftCrowdFund.invest{value: 1 ether}();
        vm.stopPrank();

        // investor invest manager
        vm.startPrank(user3);
        require(nftManager.checkVerified() == true, "nftManager is not verified");
        nftManager.investorInvest{value: 10 ether}(address(user3));
        assertEq(nftManager.getInvestment(user3), 10 ether);
        assertEq(nftManager.balanceOf(user3), 10 ether);
        nftManager.investorWithdrawInvest(10 ether);
        assertEq(nftManager.getInvestment(user3), 0 ether);
        assertEq(nftManager.balanceOf(user3), 0 ether);
        assertEq(nftManager.getTotalInvestment(), 0 ether);
        nftManager.investorInvest{value: 10 ether}(address(user3));
        assertEq(nftManager.getTotalInvestment(), 10 ether);
        vm.stopPrank();

        // manager invest
        vm.roll(block.number + 11);
        vm.startPrank(gangManager);

        bytes memory data = abi.encodeWithSelector(IGangCrowdFund.invest.selector);
        address payable callTarget = payable(address(nftCrowdFund));
        // invest 2 ether
        nftManager.managerOperations(callTarget, 2 ether, data);
        assertEq(nftManager.getTargetInvestment(address(nftCrowdFund)), 2 ether);
        // withdraw 2 ether
        bytes memory withdrawData = abi.encodeWithSignature("investManagerWithdrawInvest(uint256)", 2 ether);
        nftManager.managerOperations(callTarget, 2 ether, withdrawData);
        // invest again
        nftManager.managerOperations(callTarget, 2 ether, data);
        assertEq(nftManager.getTargetInvestment(address(nftCrowdFund)), 2 ether);
        vm.stopPrank();

        // buyer mint
        vm.roll(block.number + 10);
        vm.startPrank(user2);
        nftCrowdFund.mint{value: 500 ether}(user2, 1);
        nftCrowdFund.transferFrom{value: 1 ether}(user2, user1, 1);
        nftCrowdFund.mint{value: 500 ether}(user2, 2);
        nftCrowdFund.safeTransferFrom{value: 1 ether}(user2, user1, 2);
        nftCrowdFund.mint{value: 500 ether}(user2, 3);
        nftCrowdFund.safeTransferFrom{value: 1 ether}(user2, user1, 3, "");
        vm.stopPrank();

        //managerWithdrawRevenue
        vm.roll(block.number + 8);
        vm.startPrank(gangManager);
        bytes memory withdrawRevenueData = abi.encodeWithSignature("investManagerWithdrawRevenue()");
        nftManager.managerOperations(callTarget, 0 ether, withdrawRevenueData);
        vm.stopPrank();

        // investor redeem phase
        vm.roll(block.number + 9);
        vm.startPrank(user3);
        nftManager.investorWithdrawRevenue();
        vm.stopPrank();

        vm.roll(block.number + 10);
        // manager withdraw
        vm.startPrank(gangManager);
        nftManager.managerWithdrawRevenue();
        vm.stopPrank();

        // owner withdraw
        vm.startPrank(gangManagerOwner);
        nftManager.ownerWithdrawRevenue();
        vm.stopPrank();
    }

    function test_manager_whole_process_with_deficit() public {
        // crowdFund invest
        vm.startPrank(user2);
        nftCrowdFund.invest{value: 1 ether}();
        vm.stopPrank();
        vm.startPrank(user1);
        nftCrowdFund.invest{value: 1 ether}();
        vm.stopPrank();

        // investor invest manager
        vm.startPrank(user3);
        require(nftManager.checkVerified() == true, "nftManager is not verified");
        nftManager.investorInvest{value: 10 ether}(address(user3));
        assertEq(nftManager.getInvestment(user3), 10 ether);
        assertEq(nftManager.balanceOf(user3), 10 ether);
        nftManager.investorWithdrawInvest(10 ether);
        assertEq(nftManager.getInvestment(user3), 0 ether);
        assertEq(nftManager.balanceOf(user3), 0 ether);
        assertEq(nftManager.getTotalInvestment(), 0 ether);
        nftManager.investorInvest{value: 10 ether}(address(user3));
        assertEq(nftManager.getTotalInvestment(), 10 ether);
        vm.stopPrank();

        // manager invest
        vm.roll(block.number + 11);
        vm.startPrank(gangManager);

        bytes memory data = abi.encodeWithSelector(IGangCrowdFund.invest.selector);
        address payable callTarget = payable(address(nftCrowdFund));
        // invest 2 ether
        nftManager.managerOperations(callTarget, 2 ether, data);
        assertEq(nftManager.getTargetInvestment(address(nftCrowdFund)), 2 ether);
        // withdraw 2 ether
        bytes memory withdrawData = abi.encodeWithSignature("investManagerWithdrawInvest(uint256)", 2 ether);
        nftManager.managerOperations(callTarget, 2 ether, withdrawData);
        // invest again
        nftManager.managerOperations(callTarget, 2 ether, data);
        vm.stopPrank();

        // buyer mint
        vm.roll(block.number + 10);

        //managerWithdrawRevenue
        vm.roll(block.number + 8);
        vm.startPrank(gangManager);
        bytes memory withdrawRevenueData = abi.encodeWithSignature("investManagerWithdrawRevenue()");
        nftManager.managerOperations(callTarget, 0 ether, withdrawRevenueData);
        vm.stopPrank();

        // investor redeem phase should be able to withdraw insurance
        vm.roll(block.number + 9);
        vm.startPrank(user3);
        nftManager.investorWithdrawRevenue();
        vm.stopPrank();

        vm.roll(block.number + 10);
        // manager withdraw
        vm.startPrank(gangManager);
        nftManager.managerWithdrawRevenue();
        vm.stopPrank();

        // owner withdraw
        vm.startPrank(gangManagerOwner);
        nftManager.ownerWithdrawRevenue();
        vm.stopPrank();
    }
}
