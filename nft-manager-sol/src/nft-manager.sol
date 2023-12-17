//spdx-license-identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract NFTManager is ERC721Royalty {
    constructor() ERC721("NFTManager", "NFTM") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

}