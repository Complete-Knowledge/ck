// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface ICKRegistry {
    function isCK(address owner) external returns (bool);
}

/**
 * @dev An "Atomic" NFT contract that requires a proof of complete knowledge from each token recipient.
 */
contract AtomicNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    ICKRegistry public immutable ckRegistry;
    
    uint256 mintFee;
    
    constructor(ICKRegistry _ckRegistry, uint256 _mintFee) ERC721("Atoms", "ATM") {
        ckRegistry = _ckRegistry;
        mintFee = _mintFee;
    }

    /**
     * @dev Returns the base URI of the NFT
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://nftato.ms/atom/";
    }
    
    /**
     * @dev Sets the mint fee
     */
    function setMintFee(uint256 newMintFee) public onlyOwner {
    	mintFee = newMintFee;
    }

    /**
     * @dev An owner-only mint function
     */
    function safeMint(address to, uint256 tokenId) public payable {
    	require(msg.value >= mintFee, "Minimum mint fee not met");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < 10000, "All atomic NFTs have been minted");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    
    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * This function verifies that the recipient of any transfer has proven to
     * have complete knowledge of its private key. The sender is not checked.
     */
    function _beforeTokenTransfer(
        address,
        address to,
        uint256
    ) internal override {
        require(ckRegistry.isCK(to), "Recipient needs a CK proof");
    }
}
