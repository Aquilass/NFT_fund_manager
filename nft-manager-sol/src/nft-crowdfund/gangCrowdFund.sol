//spdx-license-identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {console2} from "forge-std/console2.sol";

contract GangCrowdFund is ERC721URIStorage, ReentrancyGuard {
    // role
    address public guarantor;
    address public owner;
    address[] public investors;
    // waitTimeBlock is the time to wait before the project owner can withdraw the revenue
    uint256 public initialBlock = 0;
    uint256 public withdrawTimeBlock = 0;
    uint256 public investTimeBlock = 0;
    // original revenue share
    uint256 public investorRevenueShare = 200;
    uint256 public investorRoyaltyShare = 200;
    // total revenue
    uint256 public investorTotalRevenue = 0;
    uint256 public investorTotalRoyalty = 0;
    uint256 public totalInvestment = 0;
    uint256 public totalRevenue = 0;
    uint256 public totalRoyalty = 0;
    // project owner revenue share
    uint256 public projectOwnerRoyaltyShare = 0;
    uint256 public projectOwnerRevenueShare = 0;
    uint256 public decimal = 18;
    // price & fee
    uint256 public floorPrice = 0.001 ether;
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
    

    struct GangCrowdFundOpts{
        string name;
        string symbol;
        address guarantor;
        uint256 investTimeBlock;
        uint256 withdrawTimeBlock;
        uint256 investorRevenueShare;
        uint256 investorRoyaltyShare;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    constructor(GangCrowdFundOpts memory _GangCrowdFundOpts) ERC721(_GangCrowdFundOpts.name, _GangCrowdFundOpts.symbol) {
        owner = msg.sender;
        guarantor = _GangCrowdFundOpts.guarantor;
        initialBlock = block.number;
        investTimeBlock = _GangCrowdFundOpts.investTimeBlock;
        withdrawTimeBlock = _GangCrowdFundOpts.withdrawTimeBlock;
        investorRevenueShare = _GangCrowdFundOpts.investorRevenueShare;
        investorRoyaltyShare = _GangCrowdFundOpts.investorRoyaltyShare;
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
    function setFloorPrice(uint256 _floorPrice) external onlyOwner {
        floorPrice = _floorPrice;
    }
    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721,IERC721) {
        require(msg.value >= fee, "sent ether is lower than fee");
        require(block.number > initialBlock + investTimeBlock, "invest time is not over");
        investorTotalRoyalty += fee * investorRoyaltyShare / 1000;
        totalRoyalty += fee;
        super.transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721,IERC721) {
        require(msg.value >= fee, "sent ether is lower than fee");
        require(block.number > initialBlock + investTimeBlock, "invest time is not over");
        totalRoyalty += fee;
        super.safeTransferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable override(ERC721,IERC721) {
        require(msg.value >= fee, "sent ether is lower than fee");
        require(block.number > initialBlock + investTimeBlock, "invest time is not over");
        investorTotalRoyalty += fee * investorRoyaltyShare / 1000;
        totalRoyalty += fee;
        super.safeTransferFrom(from, to, tokenId, _data);
    }
    function mint(address to, uint256 tokenId) external payable {
        require(msg.value >= floorPrice, "sent ether is lower than floor price");
        // wait for investor to get invest revenue
        require(block.number > initialBlock + investTimeBlock, "invest time is not over");
        console2.log("msg.value", msg.value);
        uint256 investorRevenueShareAmount = msg.value * investorRevenueShare / 1000;
        investorTotalRevenue += investorRevenueShareAmount;
        totalRevenue += msg.value;
        _mint(to, tokenId);
    }
    function projectOwnerWithdrawInvest() external payable onlyOwner {
        // require(block.number > initialBlock + investTimeBlock + withdrawTimeBlock);
        address payable receiver = payable(msg.sender);
        receiver.transfer(address(this).balance);
    }
    function invest() external payable {
        require(block.number <= initialBlock + investTimeBlock, "invest time is over");
        require(msg.value > 0, "sent ether need to be more than 0");
        investors.push(msg.sender);
        totalInvestment += msg.value;
        investment[msg.sender] += msg.value;
    }
    function investorWithdrawInvest() external payable{
        require(investment[msg.sender] > 0);
        require(block.number >= initialBlock + investTimeBlock + withdrawTimeBlock);
        address payable receiver = payable(msg.sender);
        investment[msg.sender] = 0;
        receiver.transfer(investment[msg.sender]);
    }
    function investorWithdrawRevenue() external payable {
        address payable receiver = payable(msg.sender);
        require(investment[msg.sender] > 0);
        require(block.number > initialBlock + investTimeBlock);
        uint256 investorToralRevenue = investorTotalRevenue * investment[msg.sender] / totalInvestment;
        uint256 investorToralRoyalty = investorTotalRoyalty * investment[msg.sender] / totalInvestment;
        uint256 investorToralShare = investorToralRevenue + investorToralRoyalty;
        console2.log("investorToralShare", investorToralShare);
        console2.log("alreadyWithdrawRevenue[msg.sender]", alreadyWithdrawRevenue[msg.sender]);
        console2.log("investor withdraw revenue", investorToralShare - alreadyWithdrawRevenue[msg.sender]);
        uint256 investorWithdrawRevenue = investorToralShare - alreadyWithdrawRevenue[msg.sender];
        alreadyWithdrawRevenue[msg.sender] += investorWithdrawRevenue;
        (bool success, ) = receiver.call{value: investorWithdrawRevenue}("");
        require(success, "Transfer failed.");
    }


    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return "https";
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return "https";
    }    
    // verify functions
    function checkVerified() external view returns (bool) {
        return verified;
    }

    // view functions
    function getInvestors() external view returns (address[] memory) {
        return investors;
    }
    function getInvestorTotalRevenue() external view returns (uint256) {
        return investorTotalRevenue;
    }
    function getInvestorAlreadyWithdrawRevenue(address _investor) external view returns (uint256) {
        return alreadyWithdrawRevenue[_investor];
    }
    function getInvestment(address _investor) external view returns (uint256) {
        require(_investor != address(0));
        return investment[_investor];
    }
    
}