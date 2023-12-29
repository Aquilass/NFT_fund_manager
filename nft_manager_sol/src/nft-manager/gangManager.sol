//spdx-license-identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "../../src/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import "../contracts/token/ERC721/extensions/ERC721Royalty.sol";
// import "../contracts/token/ERC20/ERC20.sol";
// import "../contracts/utils/ReentrancyGuard.sol";
import "./gangManagerBase.sol";
import "../nft-crowdfund/gangCrowdFund.sol";

contract GangManager is ERC20, ReentrancyGuard, gangManagerBase {

    //role
    address public guarantor;
    address public manager;
    address public owner;
    address[] public investors;
    // role invest amount
    // investor => amount
    mapping(address => uint256) public investment;
    uint256 guarantorAmount = 0;
    uint256 managerAmount = 0;
    // bool verified manager contract
    bool verified = false;
    // bool can only buy verified CrowdFund NFT
    bool onlyVerifiedCrowdFundNFT = true;
    //timelock for withdraw
    uint256 public initialBlockTime;
    uint256 public waitWithdrawTimeBlock;
    
    // total amount of NFTManager
    uint256 total_amount  = 0;
    uint256 public totalInvestment = 0;
    uint256 public totalRevenue = 0;

    // management contract goal
    uint256 public goal = 0;

    // phase timelock
    uint256 public investPhase = 0;
    uint256 public managerInvestPhase = 0;
    uint256 public redeemPhase = 0;

    // Crowdfund NFT Target
    bool public managerOnlyInvestVerified = true;
    bool public targetMustVerified = false;
    mapping(address => bool) public target;
    // NFTManager Options
    struct GangManagerOpts {
        string name;
        string symbol;
        address guarantor;
        address manager;
        uint256 waitWithdrawTimeBlock;
        // uint256 waitInvestTimeBlock;
        uint256 goal;
        uint256 investPhase;
        uint256 managerInvestPhase;
        uint256 redeemPhase;
        bool managerOnlyInvestVerified;
        bool targetMustVerified;
    }
    ERC20 weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor(GangManagerOpts memory _initData) ERC20(_initData.name, _initData.symbol) {
        owner = msg.sender;
        initialBlockTime = block.timestamp;
        guarantor = _initData.guarantor;
        manager = _initData.manager;
        waitWithdrawTimeBlock = _initData.waitWithdrawTimeBlock;
        // waitInvestTimeBlock = _initData.waitInvestTimeBlock;
        goal = _initData.goal;
        investPhase = _initData.investPhase;
        managerInvestPhase = _initData.managerInvestPhase;
        redeemPhase = _initData.redeemPhase;
        managerOnlyInvestVerified = _initData.managerOnlyInvestVerified;
        targetMustVerified = _initData.targetMustVerified;
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
    // events

    event Invest(address indexed _from, uint256 _value);
    event ManagerInvest(address indexed _to, uint256 _value);
    event Withdraw(address indexed _from, uint256 _value);

    function withdrawRevenue() public payable nonReentrant {
        address payable receiver = payable(msg.sender);
        require(block.timestamp > initialBlockTime + waitWithdrawTimeBlock);
        require(investment[msg.sender] > 0);
        investment[msg.sender] = 0;
        (bool success, ) = receiver.call{value: investment[msg.sender]}("");
        require(success, "Transfer failed.");
        emit Withdraw(msg.sender, investment[msg.sender]);

    }
    // erc20 functions


    function transfer(address to, uint256 value) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    //investor functions
    function investorInvest(address to, uint256 amount) public payable {
        require(block.timestamp > initialBlockTime + investPhase);
        require(msg.value > 0.001 ether);
        _mint(to, amount);
        total_amount += amount;
        emit Invest(to, amount);
    }
    function investorWithdraw() public payable onlyInvestor {
        require(block.timestamp > initialBlockTime + investPhase + managerInvestPhase);
        require(investment[msg.sender] > 0);
        investment[msg.sender] = 0;
        _burn(msg.sender, investment[msg.sender]);
        address payable receiver = payable(msg.sender);
        (bool success, ) = receiver.call{value: investment[msg.sender]}("");
        require(success, "Transfer failed.");
        emit Withdraw(msg.sender, investment[msg.sender]);
    }
    // manager funcotions
    function investCrowdfundNFT(address target, uint256 amount) public payable onlyManager {
        require(msg.value > 0.001 ether);
        _mint(target, amount);
        total_amount += amount;
        emit Invest(target, amount);
    }

    //internal functions

    function checkVerified(address _weth) public view returns (bool) {
        ERC20 weth = ERC20(_weth);
        return weth.allowance(address(this), manager) > 0;
    }

    function closeInvest () public onlyOwner {
        require(total_amount >= goal);
        verified = true;
    }
    function checkTargetVerified(address _target) public view returns (bool) {
        ERC721 target = ERC721(_target);
        return weth.allowance(_target,guarantor) > 0;
    }

    function managerWithdrawTargetInvest() public payable onlyManager {
        require(investment[msg.sender] > 0);
        require(block.timestamp > initialBlockTime + investPhase + managerInvestPhase);
        address payable receiver = payable(address(this));

    }
    // function managerBuy(
    //     address payable callTarget,
    //     uint96 callValue,
    //     bytes memory callData
    // ) external onlyDelegateCall returns () {
    //     // This function can be optionally restricted in different ways.
    //     if (onlyHostCanBuy) {
    //         // Only a host can call this function.
    //         _assertIsHost(msg.sender, governanceOpts, proposalEngineOpts, hostIndex);
    //         // If _assertIsHost() succeeded, the governance opts were validated.
    //         isValidatedGovernanceOpts = true;
    //     } else if (address(gateKeeper) != address(0)) {
    //         // `onlyHostCanBuy` is false and we are using a gatekeeper.
    //         // Only a contributor can call this function.
    //         _assertIsContributor(msg.sender);
    //     }
    //     {
    //         // Ensure that the crowdfund is still active.
    //         CrowdfundLifecycle lc = getCrowdfundLifecycle();
    //         if (lc != CrowdfundLifecycle.Active) {
    //             revert WrongLifecycleError(lc);
    //         }
    //     }

    //     // Temporarily set to non-zero as a reentrancy guard.
    //     settledPrice = type(uint96).max;

    //     // Buy the NFT and check NFT is owned by the crowdfund.
    //     (bool success, bytes memory revertData) = _buy(
    //         nftContract,
    //         nftTokenId,
    //         callTarget,
    //         callValue,
    //         callData
    //     );

    //     if (!success) {
    //         if (revertData.length > 0) {
    //             revertData.rawRevert();
    //         } else {
    //             revert FailedToBuyNFTError(nftContract, nftTokenId);
    //         }
    //     }

    //     return
    //         _finalize(
    //             nftContract,
    //             nftTokenId,
    //             callValue,
    //             governanceOpts,
    //             proposalEngineOpts,
    //             isValidatedGovernanceOpts
    //         );
    // }
    // view functions
    function getRole() public view returns (address, address, address) {
        return (guarantor, manager, owner);
    }
    function getNameAndSymbol() public view returns (string memory, string memory) {
        return (name(), symbol());
    }
}