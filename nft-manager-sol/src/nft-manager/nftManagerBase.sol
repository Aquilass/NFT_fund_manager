// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "../tokens/IERC721.sol";
import "../party/Party.sol";
import "../utils/LibSafeERC721.sol";
import "../globals/IGlobals.sol";
import "../gatekeepers/IGateKeeper.sol";

import "./Crowdfund.sol";

// Base for BuyCrowdfund and CollectionBuyCrowdfund
abstract contract nftManagerBase {


    event Won(Party party, IERC721[] tokens, uint256[] tokenIds, uint256 settledPrice);
    event Lost();

    error MaximumPriceError(uint96 callValue, uint96 maximumPrice);
    error NoContributionsError();
    error CallProhibitedError(address target, bytes data);
    error FailedToBuyNFTError(IERC721 token, uint256 tokenId);

    /// @notice When this crowdfund expires.
    uint40 public expiry;
    /// @notice Maximum amount this crowdfund will pay for the NFT.
    uint96 public maximumPrice;
    /// @notice What the NFT was actually bought for.
    uint96 public settledPrice;

    // Set the `Globals` contract.
    constructor(IGlobals globals) Crowdfund(globals) {}

    // Execute arbitrary calldata to perform a buy, creating a party
    // if it successfully buys the NFT.
    function _buy(
        IERC721 token,
        uint256 tokenId,
        address payable callTarget,
        uint96 callValue,
        bytes memory callData
    ) internal returns (bool success, bytes memory revertData) {
        // Check that the call is not prohibited.
        if (!_isCallAllowed(callTarget, callData, token)) {
            revert CallProhibitedError(callTarget, callData);
        }
        // Check that the call value is under the maximum price.
        {
            uint96 maximumPrice_ = maximumPrice;
            if (callValue > maximumPrice_) {
                revert MaximumPriceError(callValue, maximumPrice_);
            }
        }
        // Execute the call to buy the NFT.
        (bool s, bytes memory r) = callTarget.call{ value: callValue }(callData);
        if (!s) {
            return (false, r);
        }
        // Return whether the NFT was successfully bought.
        return (token.safeOwnerOf(tokenId) == address(this), "");
    }

    function _isCallAllowed(
        address payable callTarget,
        bytes memory callData,
        IERC721 token
    ) private view returns (bool isAllowed) {
        // Ensure the call target isn't trying to reenter
        if (callTarget == address(this)) {
            return false;
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
            // Prevent approving the NFT to be transferred out from the crowdfund.
            if (
                selector == IERC721.approve.selector ||
                selector == IERC721.setApprovalForAll.selector
            ) {
                return false;
            }
        }
        // All other calls are allowed.
        return true;
    }
}
