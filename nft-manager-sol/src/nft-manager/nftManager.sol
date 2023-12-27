//spdx-license-identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../src/nft-manager/nftManagerBase.sol";

interface Token {

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value)  external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender  , uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Standard_Token is Token {
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string  memory _tokenSymbol) {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value, "token balance is lower than the value requested");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value, "token balance or allowance is lower than amount requested");
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


contract NFTManager is ERC20, ReentrancyGuard, nf {
    uint256 total_amount  = 0;
    uint256 public totalInvestment = 0;
    uint256 public totalRevenue = 0;
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
    //timelock for withdraw
    uint256 public initialBlockTime;
    uint256 public waitWithdrawTimeBlock;
    

    // management contract goal
    uint256 public goal = 0;

    // phase timelock
    uint256 public investPhase = 0;
    uint256 public managerInvestPhase = 0;
    uint256 public redeemPhase = 0;

    constructor() ERC20("NFTManager", "NFTM") {
        owner = msg.sender;
        initialBlockTime = block.timestamp;
        waitWithdrawTimeBlock = 100;
    }
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

    function invest(address to, uint256 amount) public payable {
        require(msg.value > 0.001 ether);
        _mint(to, amount);
        total_amount += amount;
        emit Invest(to, amount);
    }
    function transfer(address to, uint256 value) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }
    function investCrowdfundNFT(address target, uint256 amount) public payable onlyManager {
        require(msg.value > 0.001 ether);
        _mint(to, amount);
        total_amount += amount;
        emit Invest(to, amount);
    }
    function checkVerified(address _weth) public view returns (bool) {
        ERC20 weth = ERC20(_weth);
        return weth.allowance(address(this), manager) > 0;
    }

    function closeInvest () public onlyOwner {
        require(total_amount >= goal);
        verified = true;
    }

        /// @notice Execute arbitrary calldata to perform a buy, creating a party
    ///         if it successfully buys the NFT.
    /// @param callTarget The target contract to call to buy the NFT.
    /// @param callValue The amount of ETH to send with the call.
    /// @param callData The calldata to execute.
    /// @param governanceOpts The options used to initialize governance in the
    ///                       `Party` instance created if the buy was successful.
    /// @param proposalEngineOpts The options used to initialize the proposal
    ///                           engine in the `Party` instance created if the
    ///                           crowdfund wins.
    /// @param hostIndex If the caller is a host, this is the index of the caller in the
    ///                  `governanceOpts.hosts` array.
    /// @return party_ Address of the `Party` instance created after its bought.
    function buy(
        address payable callTarget,
        uint96 callValue,
        bytes memory callData,
        FixedGovernanceOpts memory governanceOpts,
        ProposalStorage.ProposalEngineOpts memory proposalEngineOpts,
        uint256 hostIndex
    ) external onlyDelegateCall returns (Party party_) {
        // This function can be optionally restricted in different ways.
        bool isValidatedGovernanceOpts;
        if (onlyHostCanBuy) {
            // Only a host can call this function.
            _assertIsHost(msg.sender, governanceOpts, proposalEngineOpts, hostIndex);
            // If _assertIsHost() succeeded, the governance opts were validated.
            isValidatedGovernanceOpts = true;
        } else if (address(gateKeeper) != address(0)) {
            // `onlyHostCanBuy` is false and we are using a gatekeeper.
            // Only a contributor can call this function.
            _assertIsContributor(msg.sender);
        }
        {
            // Ensure that the crowdfund is still active.
            CrowdfundLifecycle lc = getCrowdfundLifecycle();
            if (lc != CrowdfundLifecycle.Active) {
                revert WrongLifecycleError(lc);
            }
        }

        // Temporarily set to non-zero as a reentrancy guard.
        settledPrice = type(uint96).max;

        // Buy the NFT and check NFT is owned by the crowdfund.
        (bool success, bytes memory revertData) = _buy(
            nftContract,
            nftTokenId,
            callTarget,
            callValue,
            callData
        );

        if (!success) {
            if (revertData.length > 0) {
                revertData.rawRevert();
            } else {
                revert FailedToBuyNFTError(nftContract, nftTokenId);
            }
        }

        return
            _finalize(
                nftContract,
                nftTokenId,
                callValue,
                governanceOpts,
                proposalEngineOpts,
                isValidatedGovernanceOpts
            );
    }
}