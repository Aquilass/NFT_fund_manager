//spdx-license-identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {console2} from "forge-std/console2.sol";

contract NFTCrowdFund is ERC721URIStorage, ReentrancyGuard {
    // role
    address public guarantor;
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
    uint256 public investLimit = 0;
    // verified
    bool public verified = false;
    // investment mapping
    mapping(address => uint256) public investment;
    mapping(address => uint256) public alreadyWithdrawRevenue;
    // NFT factor
    

    struct initData{
        address guarantor;
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
        guarantor = _initData.guarantor;
        initialBlockTime = block.timestamp;
        waitWithdrawTimeBlock = _initData.waitWithdrawTimeBlock;
        waitInvestTimeBlock = _initData.waitInvestTimeBlock;
        investorRevenueShare = _initData.investorRevenueShare;
        investorRoyaltyShare = _initData.investorRoyaltyShare;
        // _setDefaultRoyalty(msg.sender, 100);
    }
    function verifiedProject(address _weth) external onlyOwner {
        if( ERC20(_weth).allowance(guarantor, address(this)) > 0) {
            verified = true;
        }
    }
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }
    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721,IERC721) {
        require(msg.value >= fee, "sent ether is lower than fee");
        require(block.timestamp > initialBlockTime + waitWithdrawTimeBlock);
        totalRoyalty += fee;
        super.transferFrom(from, to, tokenId);
    }
    function mint(address to, uint256 tokenId) external payable {
        require(msg.value > fee, "sent ether is lower than fee");
        // wait for investor to get invest revenue
        require(block.timestamp > initialBlockTime + waitInvestTimeBlock);
        _mint(to, tokenId);
        console2.log("msg.value", msg.value);
        uint256 investorRevenueShareAmount = msg.value * investorRevenueShare / 100;
        investorTotalRevenue += investorRevenueShareAmount;
        totalRevenue += msg.value;
    }
    function invest() external payable {
        require(investable == true);
        require(msg.value > 0);
        investors.push(msg.sender);
        totalInvestment += msg.value;
        investment[msg.sender] += msg.value;
    }
    function projectOwnerWithdrawInvest() external payable onlyOwner {
        require(block.timestamp > initialBlockTime + waitWithdrawTimeBlock);
        address payable receiver = payable(msg.sender);
        receiver.transfer(address(this).balance);
    }
    function investorWithdrawInvest() external payable{
        require(investment[msg.sender] > 0);
        require(block.timestamp > initialBlockTime + waitInvestTimeBlock + waitWithdrawTimeBlock);
        address payable receiver = payable(msg.sender);
        investment[msg.sender] = 0;
        receiver.transfer(investment[msg.sender]);
    }
    function investorWithdrawRevenue() external payable {
        address payable receiver = payable(msg.sender);
        console2.log("receiver", receiver);
        // console2.log("investRevenue[msg.sender]", investRevenue[msg.sender]);
        // require(block.timestamp > initialBlockTime + waitTimeBlock);
        require(investment[msg.sender] > 0);
        require(block.timestamp > initialBlockTime + waitInvestTimeBlock);
        uint256 investorToralShare = investorTotalRevenue * investment[msg.sender] / totalInvestment;
        console2.log("investorToralShare", investorToralShare);
        uint256 investorWithdrawRevenue = investorToralShare - alreadyWithdrawRevenue[msg.sender];
        receiver.transfer(investorWithdrawRevenue);
    }


    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }
    function checkVerified() external view returns (bool) {
        return verified;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return "https";
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return "https";
    }    

    // override
}