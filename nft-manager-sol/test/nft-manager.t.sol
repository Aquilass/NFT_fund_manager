//spdx-license-identifier: MIT
pragma solidity ^0.8.19;
import "../src/nft-manager/gangManager.sol";
import "../src/nft-guarantor/gangGuarantor.sol";
import "../src/nft-crowdfund/gangCrowdFund.sol";
import "../src/nft-crowdfund/IGangCrowdFund.sol";


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
        deal(user1, 1000 ether);
        deal(user2, 1000 ether);
        deal(user3, 1000 ether);
        // GangCrowdFund setup
        vm.startPrank(guarantor);
        // Gang Gaurantor setup
        nftGuarantor = new GangGaurantor(address(0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9));
        vm.stopPrank();

        vm.startPrank(gangCrowdFundOwner);
        // GangCrowdFund setup
        GangCrowdFund.GangCrowdFundOpts memory crowdFundOpts;
        crowdFundOpts = GangCrowdFund.GangCrowdFundOpts(
            "chickenGangGang",
            "CGG",
            guarantor,
            15,
            20,
            200,
            200,
            800,
            800,
            0.01 ether,
            0.001 ether
        );
        nftCrowdFund = new GangCrowdFund(crowdFundOpts);
        nftCrowdFund.setTokenURI(1,"https://ipfs.test.com");
        vm.stopPrank();
        // GangGaurantor approve
        vm.prank(guarantor);
        nftGuarantor.addVerifiedGangCrowdFund(address(nftCrowdFund), 100 ether);
        // GangManager setup
        // need to import GangManagerOpts to use it
        vm.startPrank(gangManagerOwner);
        GangManager.GangManagerOpts memory gangManagerOpts;
        gangManagerOpts = GangManager.GangManagerOpts(
            "NFTManager",
            "NFTM",
            address(nftGuarantor),
            gangManager,
            100,
            100,
            100,
            700,
            200,
            2,
            10,
            0,
            0,
            200,
            true,
            true,
            0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9
        );
        nftManager = new GangManager(gangManagerOpts);
        vm.stopPrank();
        console2.log("setup block number", block.number);
    }
    function test_init() public {
        // gangCrowdFund
        console2.log("crowdFund name", nftCrowdFund.name());
        console2.log("crowdFund symbol", nftCrowdFund.symbol());
        (address guarantor, address manager, address owner) = nftManager.getRole();
        console2.log("guarantor", guarantor);
        console2.log("manager", manager);
        console2.log("owner", owner);
        console2.log("name", nftManager.name());
        console2.log("symbol", nftManager.symbol());
        // (uint256 
        // console2.log("getContractPhase", );
        // console2.log(nftManager.getNameAndSymbol());
        // nftManager.init(opts);
        // assertEq(nftManager.guarantor(), address(this));
        // assertEq(nftManager.manager(), address(this));
        // assertEq(nftManager.waitWithdrawTimeBlock(), 0);
        // assertEq(nftManager.waitInvestTimeBlock(), 0);
        // assertEq(nftManager.goal(), 0);
        // assertEq(nftManager.investPhase(), 0);
        // assertEq(nftManager.managerInvestPhase(), 0);
        // assertEq(nftManager.redeemPhase(), 0);
        // assertEq(nftManager.managerOnlyInvestVerified(), true);
        // assertEq(nftManager.targetMustVerified(), false);
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
        console2.log("user1 invest", nftCrowdFund.getInvestment(user1));
        console2.log("block number", block.number);
        vm.roll(block.number + 16);
        vm.expectRevert();
        nftCrowdFund.invest{value: 1 ether}();
        uint256 investment = nftCrowdFund.getInvestment(user1);
        vm.roll(block.number + 21);
        nftCrowdFund.investorWithdrawInvest(investment);
        console2.log("block number", block.number);
        console2.log("user1 invest", nftCrowdFund.getInvestment(user1));
    }
    function testMint() public {
        vm.startPrank(user1);
        nftCrowdFund.invest{value: 1 ether}();
        console2.log("user1 invest", nftCrowdFund.getInvestment(user1));
        console2.log("block number", block.number);
        vm.stopPrank();
        vm.startPrank(user2);
        nftCrowdFund.invest{value: 1 ether}();
        console2.log("user1 invest", nftCrowdFund.getInvestment(user1));
        console2.log("block number", block.number);
        vm.roll(block.number + 16);
        nftCrowdFund.mint{value: 0.01 ether}(user2, 1);
        console2.log("user2 balance", nftCrowdFund.balanceOf(user2));
        console2.log("block number", block.number);
        console2.log("user1 invest", nftCrowdFund.getInvestment(user1));
        vm.stopPrank();
        // vm.roll(3);
        vm.startPrank(user1);
        uint256 investment = nftCrowdFund.getInvestment(user1);
        nftCrowdFund.investorWithdrawRevenue();
        // nftCrowdFund.investorWithdrawRevenue();
        console2.log("already withdraw revenue", nftCrowdFund.alreadyWithdrawRevenue(user1));
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
        console2.log("already withdraw revenue", nftCrowdFund.alreadyWithdrawRevenue(user1));
        // assertEq(nftCrowdFund.alreadyWithdrawRevenue(user1), 0.9 ether);
        vm.stopPrank();
        vm.startPrank(user2);
        nftCrowdFund.investorWithdrawRevenue();
        console2.log("already withdraw revenue", nftCrowdFund.alreadyWithdrawRevenue(user2));
        // assertEq(nftCrowdFund.alreadyWithdrawRevenue(user2), 0.9 ether);
        vm.stopPrank();
        vm.roll(block.number + 21);
        vm.startPrank(gangCrowdFundOwner);
        nftCrowdFund.projectOwnerWithdrawRevenue();
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
        vm.roll(block.number +2);
        vm.startPrank(user1);
        nftManager.investorInvest{value: 1 ether}(address(user1));
        vm.stopPrank();
        vm.roll(block.number +10);
        vm.startPrank(gangManager);
        bytes memory data = abi.encodeWithSelector(IGangCrowdFund.invest.selector);
        address payable callTarget = payable(address(nftCrowdFund));
        nftManager.managerOperations(address(nftCrowdFund), callTarget, 0.1 ether, data);
        bytes memory withdrawData = abi.encodeWithSignature("managerWithdrawInvest(uint256)", 0.1 ether);
        nftManager.managerOperations(address(nftCrowdFund), callTarget, 0 ether, withdrawData);
        // invest again
        nftManager.managerOperations(address(nftCrowdFund), callTarget, 0.1 ether, data);
        vm.roll(block.number + 10);
        //managerWithdrawRevenue
        bytes memory withdrawRevenueData = abi.encodeWithSignature("managerWithdrawRevenue()");
        nftManager.managerOperations(address(nftCrowdFund), callTarget, 0 ether, withdrawRevenueData);
        vm.stopPrank();
    }
    // function test_manager_invest
    // 測試整個流程
    
    // function setUp() public {
    //     nftProject = new NFTProject(0, 0, 0, 0, 0);
    //     deal(user1, 10 ether);
    //     deal(user2, 10 ether);
    // }

    // function test_Mint() public {
    //     nftProject.mint(address(this), 1);
    //     assertEq(nftProject.ownerOf(1), address(this));
    // }

    // function test_RoyaltyInfo() public {
    //     (address receiver, uint256 royaltyAmount) = nftProject.royaltyInfo(1, 100);
    //     console2.log("receiver", receiver);
    //     console2.log("royaltyAmount", royaltyAmount);
    // }
    // function test_Mint_and_withdraw() public {
    //     vm.startPrank(user1);
    //     nftProject.invest{value: 1 ether}();
    //     vm.stopPrank();
    //     vm.startPrank(user2);
    //     nftProject.invest{value: 1 ether}();
    //     vm.stopPrank();
    //     vm.startPrank(user1);
    //     nftProject.mint{value: 1 ether}(user1, 1);
    //     console2.log("user1 balance before withdraw", user1.balance);
    //     nftProject.withdrawRevenue();   
    //     vm.stopPrank();
    //     console2.log("user1 balance after withdraw", user1.balance);
    // }
}