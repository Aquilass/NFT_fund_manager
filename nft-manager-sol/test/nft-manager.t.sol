//spdx-license-identifier: MIT
pragma solidity ^0.8.19;
import "../src/nft-manager.sol";
import "../src/nft-project.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";


contract NFTManagerTest is Test {
    NFTProject public nftProject;
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    function setUp() public {
        nftProject = new NFTProject(0, 0, 0, 0, 0);
        deal(user1, 10 ether);
        deal(user2, 10 ether);


    }

    // function test_Mint() public {
    //     nftProject.mint(address(this), 1);
    //     assertEq(nftProject.ownerOf(1), address(this));
    // }

    // function test_RoyaltyInfo() public {
    //     (address receiver, uint256 royaltyAmount) = nftProject.royaltyInfo(1, 100);
    //     console2.log("receiver", receiver);
    //     console2.log("royaltyAmount", royaltyAmount);
    // }
    function test_Mint_and_withdraw() public {
        vm.startPrank(user1);
        nftProject.invest{value: 1 ether}();
        vm.stopPrank();
        vm.startPrank(user2);
        nftProject.invest{value: 1 ether}();
        vm.stopPrank();
        vm.startPrank(user1);
        nftProject.mint{value: 1 ether}(user1, 1);
        console2.log("user1 balance before withdraw", user1.balance);
        nftProject.withdrawRevenue();   
        vm.stopPrank();
        console2.log("user1 balance after withdraw", user1.balance);
    }
}