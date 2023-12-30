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
// import "../nft-manager/gangManagerBase.sol";
import "../nft-crowdfund/gangCrowdFund.sol";
import "../nft-crowdfund/IGangCrowdFund.sol";

contract GangGaurantor is  ReentrancyGuard {
    address public weth;
    address public owner;
    address public manager;
    
    mapping (address => bool) public verifiedGangCrowdFunds;
    mapping (address => bool) public verifiedGangManagers;
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    constructor(address _weth) {
        weth = _weth;
        owner = msg.sender;
    }
    function addVerifiedGangCrowdFund(address gangCrowdFund, uint256 insurance) external onlyOwner nonReentrant returns (bool) {
        ERC20(weth).approve(gangCrowdFund, insurance);
        verifiedGangCrowdFunds[gangCrowdFund] = true;
        return true;
    }
    function addVerifiedGangManager(address gangManager, uint256 insurance) external onlyOwner nonReentrant returns (bool) {
        ERC20(weth).approve(gangManager, insurance);
        verifiedGangManagers[gangManager] = true;
        return true;
    }
    function removeVerifiedGangCrowdFund(address gangCrowdFund) external onlyOwner nonReentrant returns (bool) {
        ERC20(weth).approve(gangCrowdFund, 0);
        verifiedGangCrowdFunds[gangCrowdFund] = false;
        return true;
    }
    function removeVerifiedGangManager(address gangManager) external onlyOwner nonReentrant returns (bool) {
        ERC20(weth).approve(gangManager, 0);
        verifiedGangManagers[gangManager] = false;
        return true;
    }
    // view function
    function getWeth() external view returns (address) {
        return weth;
    }
}