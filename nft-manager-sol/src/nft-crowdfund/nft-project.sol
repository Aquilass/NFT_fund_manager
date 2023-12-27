//spdx-license-identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {console2} from "forge-std/console2.sol";
contract NFTProject is ERC721URIStorage {
    // role
    address public owner;
    address[] public investors;
    // waitTimeBlock is the time to wait before the project owner can withdraw the revenue
    uint256 public initialBlockTime = 0;
    uint256 public waitWithdrawTimeBlock = 0;
    uint256 public waitInvestTimeBlock = 0;
    // original revenue share
    uint256 public investorRevenueShare = 20;
    uint256 public investorRoyaltyShare = 20;
    // total revenue
    uint256 public investorTotalRevenue = 0;
    uint256 public totalInvestment = 0;
    uint256 public totalRevenue = 0;
    uint256 public totalRoyalty = 0;
    // project owner revenue share
    uint256 public projectOwnerRoyaltyShare = 0;
    uint256 public projectOwnerRevenueShare = 0;
    uint256 public decimal = 18;
    // price & fee
    uint256 public initialPrice = 0.001 ether;
    uint256 public fee = 0.001 ether;

    // invest factor
    bool public investable = true;

    mapping(address => uint256) public investment;
    mapping(address => uint256) public alreadyWithdrawRevenue;

    struct initData{
        uint256 waitWithdrawTimeBlock;
        uint256 waitInvestTimeBlock;
        uint256 investorRevenueShare;
        uint256 investorRoyaltyShare;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    constructor(initData memory _initData) ERC721("NFTManager", "NFTM") {
        owner = msg.sender;
        initialBlockTime = block.timestamp;
        waitWithdrawTimeBlock = _initData.waitWithdrawTimeBlock;
        waitInvestTimeBlock = _initData.waitInvestTimeBlock;
        investorRevenueShare = _initData.investorRevenueShare;
        investorRoyaltyShare = _initData.investorRoyaltyShare;
        // _setDefaultRoyalty(msg.sender, 100);
    }
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(msg.value >= fee, "sent ether is lower than fee");
        require(block.timestamp > initialBlockTime + waitWithdrawTimeBlock);
        uint256 investorRoyaltyShareAmount = msg.value * investorRoyaltyShare / 100;
        investorTotalRevenue += investorRoyaltyShareAmount;
        totalRoyalty += fee;
        super.transferFrom(from, to, tokenId);
    }
    function mint(address to, uint256 tokenId) external payable {
        require(msg.value > fee, "sent ether is lower than fee");
        _mint(to, tokenId);
        console2.log("msg.value", msg.value);
        uint256 investorRevenueShareAmount = msg.value * investorRevenueShare / 100;
        investorTotalRevenue += (investorRevenueShareAmount + investorRoyaltyShareAmount);
        totalRevenue += msg.value;
    }
    function invest() external payable {
        require(investable == true);
        require(msg.value > 0);
        investors.push(msg.sender);
        totalInvestment += msg.value;
        investment[msg.sender] += msg.value;
    }
    function investorWithdrawInvest() external payable{
        require(investment[msg.sender] > 0);
        require(block.timestamp > initialBlockTime + waitInvestTimeBlock + waitWithdrawTimeBlock);
        address payable receiver = payable(msg.sender);
        investment[msg.sender] = 0;
        receiver.transfer(investment[msg.sender]);
    }
    function withdrawRevenue() external payable {
        address payable receiver = payable(msg.sender);
        console2.log("receiver", receiver);
        console2.log("investRevenue[msg.sender]", investRevenue[msg.sender]);
        // require(block.timestamp > initialBlockTime + waitTimeBlock);
        require(investment[msg.sender] > 0);
        require(block.timestamp > initialBlockTime + waitInvestTimeBlock);
        uint256 investorToralShare = investorTotalRevenue * investment[msg.sender] / totalInvestment;
        console2.log("investorToralShare", investorToralShare);
        uint256 investorWithdrawRevenue = investorToralShare - alreadyWithdrawRevenue[msg.sender];
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