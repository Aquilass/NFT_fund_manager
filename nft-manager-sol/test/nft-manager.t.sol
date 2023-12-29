//spdx-license-identifier: MIT
pragma solidity ^0.8.19;
import "../src/nft-manager/gangManager.sol";
import "../src/nft-crowdfund/gangCrowdFund.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";


contract gangManagerTest is Test {
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
        // need to import GangManagerOpts to use it
        GangManager.GangManagerOpts memory opts;
        // GangManagerOpts memory opts;
        opts = GangManager.GangManagerOpts(
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
        
        nftManager = new GangManager(opts);
    }
    function test_init() public {
        (address guarantor, address manager, address owner) = nftManager.getRole();
        console2.log("guarantor", guarantor);
        console2.log("manager", manager);
        console2.log("owner", owner);
        console2.log("name", nftManager.name());
        console2.log("symbol", nftManager.symbol());
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
    function testMintandtransfer() public {
        vm.startPrank(user1);
        // nftManager._mint(user1, 1);
        // assertEq(nftManager.ownerOf(1), user1);
        // nftManager.transferFrom(user1, user2, 1);
        // assertEq(nftManager.ownerOf(1), user2);
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