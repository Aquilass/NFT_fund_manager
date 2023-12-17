//spdx-license-identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {console2} from "forge-std/console2.sol";
contract NFTProject is ERC721URIStorage {
    address public owner;
    uint256 public initialBlockTime = 0;
    uint256 public waitWithdrawTimeBlock = 0;
    uint256 public waitInvestTimeBlock = 0;
    address[] public investors;
    uint256 public investorRevenueShare = 20;
    uint256 public investorRoyaltyShare = 20;
    uint256 public investorTotalRevenue = 0;
    uint256 public totalInvestment = 0;
    uint256 public totalRevenue = 0;
    uint256 public totalRoyalty = 0;
    uint256 public projectOwnerRoyaltyShare = 0;
    uint256 public projectOwnerRevenueShare = 0;
    uint256 public decimal = 18;

    mapping(address => uint256) public investment;
    mapping(address => uint256) public investRevenue;



    constructor(uint256 _waitTimeBlock, uint256 _waitInvestTimeBlock, uint256 _waitWithdrawTimeBlock, uint256 _projectOwnerRoyaltyShare, uint256 _projectOwnerRevenueShare
    ) ERC721("NFTManager", "NFTM") {
        owner = msg.sender;
        initialBlockTime = block.timestamp;
        waitWithdrawTimeBlock = _waitWithdrawTimeBlock;
        waitInvestTimeBlock = _waitInvestTimeBlock;
        projectOwnerRoyaltyShare = _projectOwnerRoyaltyShare;
        projectOwnerRevenueShare = _projectOwnerRevenueShare;
        // _setDefaultRoyalty(msg.sender, 100);
    }
    function mint(address to, uint256 tokenId) external payable {
        require(msg.value > 0.001 ether);
        _mint(to, tokenId);
        console2.log("msg.value", msg.value);
        uint256 investorRevenueShareAmount = msg.value * investorRevenueShare / 100;
        uint256 investorRoyaltyShareAmount = msg.value * investorRoyaltyShare / 100;
        investorTotalRevenue += (investorRevenueShareAmount + investorRoyaltyShareAmount);
        uint256 totalShareAmount = investorRevenueShareAmount + investorRoyaltyShareAmount;
        console2.log("totalShareAmount", totalShareAmount);
        _distributeFee(totalShareAmount);
        totalRevenue += (msg.value - investorRoyaltyShareAmount);
        totalRoyalty += (msg.value - investorRoyaltyShareAmount);
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function _distributeFee (uint256 mintAmount ) internal {
        for (uint256 i = 0; i < investors.length; i++) {
            uint256 investorShare = mintAmount * investment[investors[i]] / totalInvestment;
            investRevenue[investors[i]] += investorShare;
            console2.log("investRevenue[investors[i]]", investRevenue[investors[i]]);
            console2.log("investors", investors[i]);
            console2.log("investorShare", investorShare);
            console2.log("mintAmount", mintAmount);
        }
    }
    function invest() external payable {
        require(msg.value > 0);
        investors.push(msg.sender);
        totalInvestment += msg.value;
        investment[msg.sender] += msg.value;
    }
    function withdrawRevenue() external payable {
        address payable receiver = payable(msg.sender);
        console2.log("receiver", receiver);
        console2.log("investRevenue[msg.sender]", investRevenue[msg.sender]);
        // require(block.timestamp > initialBlockTime + waitTimeBlock);
        require(investment[msg.sender] > 0);
        receiver.transfer(investRevenue[msg.sender]);

        // require(investment[msg.sender] > 0 && 
        // for (uint256 i = 0; i < investors.length; i++) {
        //     uint256 investorShare = investment[investors[i]] / totalInvestment;
        //     investors[i].transfer(totalRevenue * investorShare);
        // }
    }
    // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    //     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
    // }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return "https";
    }

    
}