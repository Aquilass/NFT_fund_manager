//spdx-license-identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
// import "../../src/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import "../contracts/token/ERC721/extensions/ERC721Royalty.sol";
// import "../contracts/token/ERC20/ERC20.sol";
// import "../contracts/utils/ReentrancyGuard.sol";
// import "./gangManagerBase.sol";
import "../nft-crowdfund/gangCrowdFund.sol";
import "../nft-crowdfund/IGangCrowdFund.sol";

contract GangManager is ERC20, ReentrancyGuard {
    enum CrowdFundOperation {
        invest,
        managerWithdrawInvest,
        managerWithdrawRevenue,
        undefined,
        prohibited
    }
    CrowdFundOperation public operation;

    //role
    address public guarantor;
    address public manager;
    address public owner;
    address[] public investors;
    // role invest amount
    // investor => amount
    mapping(address => uint256) public investment;
    mapping(address => uint256) public alreadyWithdrawRevenue;
    // revenue share setting, total 1000
    uint256 ownerRevenueShare = 0;
    uint256 guarantorRevenueShare = 0;
    uint256 managerRevenueShare = 0;
    uint256 investorRevenueShare = 0;
    // insurance setting
    uint256 public insuranceThreshold = 0;
    // total amount of NFTManager
    uint256 public totalInvestment = 0;
    uint256 public totalRevenue = 0;

    // management contract general setting
    uint256 public goal;
    uint256 maximuInvestPercentage;

    //timelock for withdraw
    uint256 public initialBlock;
    // phase timelock
    uint256 public investPhase = 0;
    uint256 public managerInvestPhase = 0;
    uint256 public redeemPhase = 0;

    // manager contract invest target setting
    bool public managerOnlyInvestVerified = true;
    bool public managerOnlyInvestGangCrowdFund = true;
    mapping(address => uint256 ) public targetInvestment;
    uint256 public totalTargetInvestment = 0;
    uint256 public totalTargetRevenue = 0;
    // NFTManager Options
    struct GangManagerOpts {
        // manager contract erc20 setting
        string name;
        string symbol;
        // manager contract role setting
        address guarantor;
        address manager;
        // manager revenue setting
        uint256 ownerRevenueShare;
        uint256 guarantorRevenueShare;
        uint256 managerRevenueShare;
        uint256 investorRevenueShare;
        uint256 insuranceThreshold;
        // manager phase setting
        uint256 investPhase;
        uint256 managerInvestPhase;
        uint256 redeemPhase;
        // manager contract general setting
        uint256 goal;
        uint256 maximuInvestPercentage;
        // manager contract invest target setting
        bool managerOnlyInvestVerified;
        bool managerOnlyInvestGangCrowdFund;
        // weth
        address weth;
    }
    // weth
    address public weth;

    error MaximumPriceError(uint256 callValue, uint256 maximumPrice);
    error NoContributionsError();
    error CallProhibitedError(address target, bytes data);
    error FailedToBuyNFTError(IERC721 token, uint256 tokenId);
    error FailedToInvestError(address token, uint256 amount);
    error FailedToOperateError(address token, uint256 amount);

    constructor(GangManagerOpts memory _initData) ERC20(_initData.name, _initData.symbol) {
        owner = msg.sender;
        initialBlock = block.number;
        guarantor = _initData.guarantor;
        manager = _initData.manager;
        ownerRevenueShare = _initData.ownerRevenueShare;
        guarantorRevenueShare = _initData.guarantorRevenueShare;
        managerRevenueShare = _initData.managerRevenueShare;
        investorRevenueShare = _initData.investorRevenueShare;
        insuranceThreshold = _initData.insuranceThreshold;
        investPhase = _initData.investPhase;
        managerInvestPhase = _initData.managerInvestPhase;
        redeemPhase = _initData.redeemPhase;
        goal = _initData.goal;
        maximuInvestPercentage = _initData.maximuInvestPercentage;
        managerOnlyInvestVerified = _initData.managerOnlyInvestVerified;
        managerOnlyInvestGangCrowdFund = _initData.managerOnlyInvestGangCrowdFund;
        weth = _initData.weth;
    }
    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    modifier onlyInvestor() {
        require(investment[msg.sender] > 0);
        _;
    }
    modifier onlyTarget(){
        require(targetInvestment[msg.sender] > 0);
        _;
    }
    // events

    event Invest(address indexed _from, uint256 _value);
    event ManagerInvest(address indexed _to, uint256 _value);
    event Withdraw(address indexed _from, uint256 _value);

    function _insuranceReveue() internal{
        uint256 wethInsurance = ERC20(weth).allowance(guarantor, address(this));
        ERC20(weth).transferFrom(guarantor, address(this), wethInsurance);
        bytes memory withdrawWethData = abi.encodeWithSignature("withdraw(uint256)", wethInsurance);
        (bool success, bytes memory revertData) = guarantor.call(withdrawWethData);
        if (!success) {
            revert FailedToOperateError(guarantor, wethInsurance);
        }
    }

    function ownerWithdrawRevenue() public payable onlyOwner nonReentrant{
        require(block.number> initialBlock + investPhase + managerInvestPhase + redeemPhase);
        require(address(this).balance > 0);
        if(totalRevenue < totalInvestment * insuranceThreshold / 1000){
            _insuranceReveue();
        }
        uint256 ownerRevenue = totalRevenue * ownerRevenueShare / 1000;
        address payable receiver = payable(msg.sender);
        (bool success, ) = receiver.call{value: ownerRevenue}("");
        require(success, "Transfer failed.");
        emit Withdraw(msg.sender, ownerRevenue);
    }

    function managerWithdrawRevenue() public payable onlyManager nonReentrant{
        require(block.number> initialBlock + investPhase + managerInvestPhase + redeemPhase);
        require(address(this).balance > 0);
        if(totalRevenue < totalInvestment * insuranceThreshold / 1000){
            _insuranceReveue();
        }
        address payable receiver = payable(msg.sender);
        uint256 managerRevenue = totalRevenue * managerRevenueShare / 1000;
        (bool success, ) = receiver.call{value: managerRevenue}("");
        require(success, "Transfer failed.");
        emit Withdraw(msg.sender, managerRevenue);
    }
    // erc20 functions


    function transfer(address to, uint256 value) public override nonReentrant returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    //investor functions
    function investorInvest(address to) public payable  nonReentrant{
        require(block.number>= initialBlock + investPhase, "invest phase not start");
        require(msg.value > 0.001 ether, "invest amount must greater than 0.001 ether");
        _mint(to, msg.value);
        totalInvestment += msg.value;
        investment[to] += msg.value;
        emit Invest(to, msg.value);
    }
    function investorWithdrawRevenue() public payable onlyInvestor  nonReentrant{
        require(block.number> initialBlock + investPhase + managerInvestPhase);
        require(investment[msg.sender] > 0);
        require(address(this).balance > 0);
        if(totalRevenue < totalInvestment * insuranceThreshold / 1000){
            _insuranceReveue();
        }
        uint256 investorRevenue = investment[msg.sender] * investorRevenueShare / 1000;
        alreadyWithdrawRevenue[msg.sender] += investorRevenue;
        address payable receiver = payable(msg.sender);
        (bool success, ) = receiver.call{value: investorRevenue}("");
    }
    function investorWithdrawInvest(uint256 amount) public payable onlyInvestor {
        require(block.number> initialBlock + investPhase + managerInvestPhase || block.number < initialBlock + investPhase);
        require(address(this).balance > 0);
        require(investment[msg.sender] > 0);
        investment[msg.sender] = 0;
        _burn(msg.sender, investment[msg.sender]);
        address payable receiver = payable(msg.sender);
        (bool success, ) = receiver.call{value: investment[msg.sender]}("");
        require(success, "Transfer failed.");
        emit Withdraw(msg.sender, investment[msg.sender]);
    }
    // manager funcotions


    function checkVerified(address target) public view returns (bool) {
        return ERC20(weth).allowance(address(this), manager) > 0;
    }

    function checkTargetVerified(address _target) public view returns (bool) {
        return ERC20(weth).allowance(guarantor,_target) > 0;
    }
    function withdrawTargetInvest(address _target, uint256 amount) public payable onlyTarget() {
        require(targetInvestment[msg.sender] > 0);
        targetInvestment[msg.sender] -= amount;
        totalTargetInvestment -= amount;
        totalInvestment += amount;
    }
    function withdrawTargetRevenue(address _target, uint256 amount) public payable onlyTarget() {
        require(targetInvestment[msg.sender] > 0);
        totalRevenue += amount;
    }

    function _managerOperations(
        address token,
        address payable callTarget,
        bool onlyInvestVerifiedGangCrowdFund,
        uint256 callValue,
        bytes memory callData
    ) internal returns (bool success, bytes memory revertData) {
        // Check that the call is not prohibited.
        (bool isAllowed, CrowdFundOperation operation) = _isCallAllowed(callTarget, onlyInvestVerifiedGangCrowdFund,callData, token);
        if (!isAllowed) {
            revert CallProhibitedError(callTarget, callData);
        }
        // Check that the call value is under the maximum percentange.
        {
            uint256 targetValue = targetInvestment[callTarget];
            uint256 maximumPrice_ = totalInvestment * maximuInvestPercentage / 1000;
            if (targetValue + callValue > maximumPrice_) {
                revert MaximumPriceError(callValue, maximumPrice_);
            }
        }
        //get balance
        // Execute the call to buy the NFT.

        (bool s, bytes memory r) = callTarget.call{ value: callValue }(callData);
        if (!s) {
            return (false, r);
        }
        if (operation == CrowdFundOperation.invest) {
            console2.log("invest", callValue);
            totalInvestment -= callValue;
            targetInvestment[callTarget] += callValue;
            totalTargetInvestment += callValue;
            return (true, r);
        }
        else if (operation == CrowdFundOperation.managerWithdrawInvest) {
            return (true, r);
        }
        else if (operation == CrowdFundOperation.managerWithdrawRevenue) {
            return (true, r);
        }
        else {
            return (false, r);
        }

        // Return whether the NFT was successfully bought.
        // return (token.safeOwnerOf(tokenId) == address(this), "");
    }

    function _isCallAllowed(
        address payable callTarget,
        bool onlyInvestVerifiedGangCrowdFund,
        bytes memory callData,
        address token
    ) private view returns (bool isAllowed,CrowdFundOperation operation) {
        // Ensure the call target isn't trying to reenter
        if (callTarget == address(this)) {
            return (false, CrowdFundOperation.prohibited);
        }
        if (callTarget == address(token) && callData.length >= 4) {
            // Get the function selector of the call (first 4 bytes of calldata).
            bytes4 selector;
            assembly {
                selector := and(
                    mload(add(callData, 32)),
                    0xffffffff00000000000000000000000000000000000000000000000000000000
                )
            }
            if (
                selector == IGangCrowdFund.invest.selector 
            ) {
                return (true, CrowdFundOperation.invest);
            }
            else if (
                selector == IGangCrowdFund.managerWithdrawInvest.selector
            ) {
                return (true, CrowdFundOperation.managerWithdrawInvest);
            }
            else if (
                selector == IGangCrowdFund.managerWithdrawRevenue.selector
            ) {
                return (true, CrowdFundOperation.managerWithdrawRevenue);
            }
            else {
                return (false, CrowdFundOperation.undefined);
            }
        }
        else {
            return (false, CrowdFundOperation.undefined);
        }
    }
    function managerOperations(
        address nftContract,
        address payable callTarget,
        uint256 callValue,
        bytes memory callData
    ) external payable onlyManager returns (bool success) {
        require(msg.sender == manager);
        // This function can be optionally restricted in different ways.
        if (managerOnlyInvestVerified) {
            require(this.checkTargetVerified(nftContract) == true, "nftContract is not verified");
        } 

        // Buy the NFT and check NFT is owned by the crowdfund.
        (bool success, bytes memory revertData) = _managerOperations(
            nftContract,
            callTarget,
            managerOnlyInvestGangCrowdFund,
            callValue,
            callData
        );

        if (!success) {
            if (revertData.length > 0) {
                revert(string(revertData));
            } else {
                revert FailedToOperateError(nftContract, callValue);
            }
        }

        return success;
    }

    // view functions
    function getRole() public view returns (address, address, address) {
        return (guarantor, manager, owner);
    }
    function getNameAndSymbol() public view returns (string memory, string memory) {
        return (name(), symbol());
    }
    function getInvestment(address _investor) public view returns (uint256) {
        return investment[_investor];
    }
    function getTargetInvestment(address _target) public view returns (uint256) {
        return targetInvestment[_target];
    }
    function getTotalInvestment() public view returns (uint256) {
        return totalInvestment;
    }
    function getWeth() public view returns (address) {
        return weth;
    }
    function getContractPhase() public view returns (string memory) {
        if (block.number < initialBlock + investPhase) {
            return "invest phase";
        }
        else if (block.number < initialBlock + investPhase + managerInvestPhase) {
            return "manager invest phase";
        }
        else if (block.number < initialBlock + investPhase + managerInvestPhase + redeemPhase) {
            return "redeem phase";
        }
        else {
            return "end";
        }
    }
    receive() external payable {
        totalRevenue += msg.value;
    }
    fallback() external payable {
        totalRevenue += msg.value;
    }
}