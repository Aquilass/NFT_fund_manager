//spdx-license-identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {console2} from "forge-std/console2.sol";
import "../weth/IWETH.sol";

contract GangCrowdFund is ERC721URIStorage, ReentrancyGuard {
    // role
    address public guarantor;
    address public owner;
    address[] public investors;
    // waitTimeBlock is the time to wait before the project owner can withdraw the revenue
    uint256 public initialBlock = 0;
    uint256 public investPhase = 0;
    uint256 public investorsWithdrawPhase = 0;
    uint256 public investorsExitPhase = 0;
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
    uint256 public projectOwnerRoyaltyShare = 750;
    uint256 public projectOwnerRevenueShare = 750;
    uint256 public guarantorRoyaltyShare = 50;
    uint256 public guarantorRevenueShare = 50;
    uint256 public decimal = 18;
    // price & fee
    uint256 public floorPrice = 0.001 ether;
    uint256 public fee = 0.001 ether;

    // invest factor
    bool public investable = true;
    uint256 public investLimit = 0;
    uint256 public insuranceThreshold = 200;
    bool public insuranceCompensated = false;

    // investment mapping
    mapping(address => uint256) public investment;
    mapping(address => uint256) public alreadyWithdrawRevenue;
    // weth
    address public weth;
    // NFT factor
    struct GangCrowdFundOpts{
        string name;
        string symbol;
        address guarantor;
        uint256 investPhase;
        uint256 investorsWithdrawPhase;
        uint256 investorsExitPhase;
        uint256 investorRevenueShare;
        uint256 investorRoyaltyShare;
        uint256 projectOwnerRevenueShare;
        uint256 projectOwnerRoyaltyShare;
        uint256 guarantorRevenueShare;
        uint256 guarantorRoyaltyShare;
        uint256 floorPrice;
        uint256 fee;
        uint256 insuranceThreshold;
        address weth;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    constructor(GangCrowdFundOpts memory _GangCrowdFundOpts) ERC721(_GangCrowdFundOpts.name, _GangCrowdFundOpts.symbol) {
        owner = msg.sender;
        guarantor = _GangCrowdFundOpts.guarantor;
        initialBlock = block.number;
        investPhase = _GangCrowdFundOpts.investPhase;
        investorsWithdrawPhase = _GangCrowdFundOpts.investorsWithdrawPhase;
        investorsExitPhase = _GangCrowdFundOpts.investorsExitPhase;
        investorRevenueShare = _GangCrowdFundOpts.investorRevenueShare;
        investorRoyaltyShare = _GangCrowdFundOpts.investorRoyaltyShare;
        projectOwnerRevenueShare = _GangCrowdFundOpts.projectOwnerRevenueShare;
        projectOwnerRoyaltyShare = _GangCrowdFundOpts.projectOwnerRoyaltyShare;
        guarantorRevenueShare = _GangCrowdFundOpts.guarantorRevenueShare;
        guarantorRoyaltyShare = _GangCrowdFundOpts.guarantorRoyaltyShare;
        floorPrice = _GangCrowdFundOpts.floorPrice;
        fee = _GangCrowdFundOpts.fee;
        insuranceThreshold = _GangCrowdFundOpts.insuranceThreshold;
        weth = _GangCrowdFundOpts.weth;
        // _setDefaultRoyalty(msg.sender, 100);
    }
    function setFee(uint256 _fee) external onlyOwner nonReentrant {
        fee = _fee;
    }
    function setFloorPrice(uint256 _floorPrice) external onlyOwner  nonReentrant{
        floorPrice = _floorPrice;
    }
    function _insuranceReveue() internal{
        uint256 wethInsurance = IWETH(weth).allowance(guarantor, address(this));
        IWETH(weth).transferFrom(guarantor, address(this), wethInsurance);
        IWETH(weth).withdraw(wethInsurance);
        investorTotalRevenue += wethInsurance;
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable nonReentrant override(ERC721,IERC721) {
        require(msg.value >= fee, "sent ether is lower than fee");
        require(block.number > initialBlock + investPhase, "invest time is not over");
        investorTotalRoyalty += msg.value * investorRoyaltyShare / 1000;
        totalRoyalty += msg.value;
        super.transferFrom(from, to, tokenId);
    }

    function mint(address to, uint256 tokenId) external payable nonReentrant {
        require(msg.value >= floorPrice, "sent ether is lower than floor price");
        // wait for investor to get invest revenue
        require(block.number >= initialBlock + investPhase, "invest time is not over");
        uint256 investorRevenueShareAmount = msg.value * investorRevenueShare / 1000;
        investorTotalRevenue += investorRevenueShareAmount;
        totalRevenue += msg.value;
        _mint(to, tokenId);
    }
    function projectOwnerWithdrawInvest() external payable onlyOwner nonReentrant {
        require(block.number <= initialBlock + investPhase, "can only withdraw invest before invest time is over");
        address payable receiver = payable(msg.sender);
        receiver.transfer(address(this).balance);
    }
    function projectOwnerAndGuarantorWithdrawRevenue() external payable onlyOwner nonReentrant {
        require(block.number > initialBlock + investPhase + investorsWithdrawPhase, "invest time is not over or withdraw time not yet come");
        address payable projectOwner = payable(owner);
        address payable guarantor = payable(guarantor);
        uint256 projectOwnerTotalRevenue = (totalRevenue-investorTotalRevenue) * projectOwnerRevenueShare / (projectOwnerRevenueShare + guarantorRevenueShare);
        uint256 projectOwnerTotalRoyalty = (totalRoyalty-investorTotalRoyalty) * projectOwnerRoyaltyShare / (projectOwnerRoyaltyShare + guarantorRoyaltyShare);
        uint256 projectOwnerTotalShare = projectOwnerTotalRevenue + projectOwnerTotalRoyalty;
        uint256 projectOwnerAllowedWithdrawRevenue = projectOwnerTotalShare - alreadyWithdrawRevenue[msg.sender];
        alreadyWithdrawRevenue[msg.sender] += projectOwnerAllowedWithdrawRevenue;
        uint256 guarantorTotalRevenue = (totalRevenue-investorTotalRevenue)*guarantorRevenueShare / (projectOwnerRevenueShare + guarantorRevenueShare);
        uint256 guarantorTotalRoyalty = (totalRoyalty-investorTotalRoyalty)* guarantorRoyaltyShare / (projectOwnerRoyaltyShare + guarantorRoyaltyShare);
        uint256 guarantorTotalShare = guarantorTotalRevenue + guarantorTotalRoyalty;
        uint256 guarantorAllowedWithdrawRevenue = guarantorTotalShare - alreadyWithdrawRevenue[msg.sender];
        alreadyWithdrawRevenue[msg.sender] += guarantorAllowedWithdrawRevenue;
        projectOwner.transfer(projectOwnerAllowedWithdrawRevenue);
        guarantor.transfer(guarantorAllowedWithdrawRevenue);
    }
    function invest() external payable nonReentrant returns (uint256) {
        require(block.number <= initialBlock + investPhase, "invest time is over");
        require(msg.value > 0, "sent ether need to be more than 0");
        investors.push(msg.sender);
        totalInvestment += msg.value;
        investment[msg.sender] += msg.value;
        return investment[msg.sender];
    }
    function investorWithdrawInvest(uint256 amount) external payable nonReentrant returns (uint256) {
        require(investment[msg.sender] > 0);
        require(amount <= investment[msg.sender]);
        require(block.number >= initialBlock + investPhase + investorsWithdrawPhase + investorsExitPhase  || block.number <= initialBlock + investPhase, "invest time is over or withdraw time not yet come");
        address payable receiver = payable(msg.sender);
        investment[msg.sender] -= amount;
        receiver.transfer(amount);
        return investment[msg.sender];
    }
    function investorWithdrawRevenue() external nonReentrant payable {
        address payable receiver = payable(msg.sender);
        require(investment[msg.sender] > 0);
        require(block.number > initialBlock + investPhase || block.number <= initialBlock + investPhase + investorsWithdrawPhase);
        if(totalRevenue < totalInvestment * insuranceThreshold / 1000 && insuranceCompensated == false && block.number > initialBlock + investPhase + (investorsWithdrawPhase * 950 / 1000)){
            insuranceCompensated = true;
            _insuranceReveue();
        }
        uint256 investorRecievedRevenue = investorTotalRevenue * investment[msg.sender] / totalInvestment;
        uint256 investorRecievedRoyalty = investorTotalRoyalty * investment[msg.sender] / totalInvestment;
        uint256 investorTotalRecieved = investorRecievedRevenue + investorRecievedRoyalty;
        uint256 investorAllowedWithrawRevenue = investorTotalRecieved - alreadyWithdrawRevenue[msg.sender];
        alreadyWithdrawRevenue[msg.sender] += investorAllowedWithrawRevenue;
        receiver.transfer(investorAllowedWithrawRevenue);
    }

    function investManagerWithdrawInvest(uint256 amount) external nonReentrant payable {
        require(investment[msg.sender] > 0);
        require(amount <= investment[msg.sender]);
        require(block.number >= initialBlock + investPhase + investorsWithdrawPhase || block.number <= initialBlock + investPhase, "invest time is over or withdraw time not yet come");
        address payable receiver = payable(msg.sender);
        investment[msg.sender] -= amount;
        bytes memory data = abi.encodeWithSignature("withdrawTargetInvest(address,uint256)", address(this), amount);
        (bool success, ) = receiver.call{value: amount}(data);
        require(success, "Transfer failed.");
        // return investment[msg.sender];
    }
    function investManagerWithdrawRevenue() external nonReentrant payable returns (uint256 received){
        address payable receiver = payable(msg.sender);
        require(investment[msg.sender] > 0);
        require(block.number > initialBlock + investPhase);
        uint256 investorReceivedRevenue = investorTotalRevenue * investment[msg.sender] / totalInvestment;
        uint256 investorReceivedRoyalty = investorTotalRoyalty * investment[msg.sender] / totalInvestment;
        uint256 investorTotalShare = investorReceivedRevenue + investorReceivedRoyalty;
        console2.log("investorTotalShare", investorTotalShare);
        console2.log("alreadyWithdrawRevenue[msg.sender]", alreadyWithdrawRevenue[msg.sender]);
        console2.log("investor withdraw revenue", investorTotalShare - alreadyWithdrawRevenue[msg.sender]);
        uint256 investManagerAllowedWithdraw = investorTotalShare - alreadyWithdrawRevenue[msg.sender];
        alreadyWithdrawRevenue[msg.sender] += investManagerAllowedWithdraw;
        bytes memory data = abi.encodeWithSignature("withdrawTargetRevenue(address,uint256)", address(this), investManagerAllowedWithdraw);
        (bool success, ) = receiver.call{value: investManagerAllowedWithdraw}(data);
        require(success, "Transfer failed.");
        return investManagerAllowedWithdraw;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external nonReentrant onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return "https";
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return "https";
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
    receive() external payable {
        // totalRevenue += msg.value;
    }
    fallback() external payable {
        totalRevenue += msg.value;
    }
    
}