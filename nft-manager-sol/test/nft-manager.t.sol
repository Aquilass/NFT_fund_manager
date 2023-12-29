//spdx-license-identifier: MIT
pragma solidity ^0.8.19;
import "../src/nft-manager/gangManager.sol";
import "../src/nft-crowdfund/gangCrowdFund.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";


contract gangManagerTest is Test {
    // gangCrowdFund config
    GangCrowdFund public nftCrowdFund;
    // gangManager config
    GangManager public nftManager;

    address public owner = makeAddr("owner");
    address public manager = makeAddr("manager");
    address public guarantor = makeAddr("guarantor");
    // GangManagerOpts public opts;
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");
    function setUp() public {
        // role setUp
        deal(user1, 10 ether);
        deal(user2, 10 ether);
        deal(user3, 10 ether);
        // GangCrowdFund setup
        vm.startPrank(owner);
        GangCrowdFund.GangCrowdFundOpts memory crowdFundOpts;
        crowdFundOpts = GangCrowdFund.GangCrowdFundOpts(
            "chickenGangGang",
            "CGG",
            guarantor,
            2,
            2,
            200,
            200
        );
        nftCrowdFund = new GangCrowdFund(crowdFundOpts);
        // GangManager setup
        // need to import GangManagerOpts to use it
        GangManager.GangManagerOpts memory gangManagerOpts;
        // GangManagerOpts memory opts;
        gangManagerOpts = GangManager.GangManagerOpts(
            "NFTManager",
            "NFTM",
            guarantor,
            manager,
            0,
            0,
            0,
            0,
            0,
            true,
            false
        );
        nftManager = new GangManager(gangManagerOpts);
        vm.stopPrank();
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
    function test_CrowdFund_invest_withdraw() public {
        vm.startPrank(user1);
        vm.expectRevert();
        nftCrowdFund.invest();
        nftCrowdFund.invest{value: 1 ether}();
        console2.log("user1 invest", nftCrowdFund.getInvestment(user1));
        console2.log("block number", block.number);
        vm.roll(6);
        vm.expectRevert();
        nftCrowdFund.invest{value: 1 ether}();
        nftCrowdFund.investorWithdrawInvest();
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
        vm.roll(4);
        nftCrowdFund.mint{value: 0.001 ether}(user2, 1);
        console2.log("user2 balance", nftCrowdFund.balanceOf(user2));
        console2.log("block number", block.number);
        console2.log("user1 invest", nftCrowdFund.getInvestment(user1));
        vm.stopPrank();
        // vm.roll(3);
        vm.startPrank(user1);
        nftCrowdFund.investorWithdrawRevenue();
        nftCrowdFund.investorWithdrawRevenue();
        console2.log("already withdraw revenue", nftCrowdFund.alreadyWithdrawRevenue(user1));
        assertEq(nftCrowdFund.alreadyWithdrawRevenue(user1), 1e14);
    }
    function testTransfer() public {
        vm.startPrank(user1);
        nftCrowdFund.invest{value: 1 ether}();
        vm.stopPrank();
        vm.startPrank(user2);
        nftCrowdFund.invest{value: 1 ether}();
        vm.roll(4);
        nftCrowdFund.mint{value: 0.001 ether}(user2, 1);
        nftCrowdFund.transferFrom{value: 0.001 ether}(user2, user1, 1);
        vm.stopPrank();
        // vm.roll(3);
        vm.startPrank(user1);
        nftCrowdFund.investorWithdrawRevenue();
        nftCrowdFund.investorWithdrawRevenue();
        console2.log("already withdraw revenue", nftCrowdFund.alreadyWithdrawRevenue(user1));
        assertEq(nftCrowdFund.alreadyWithdrawRevenue(user1), 2e14);
    }

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