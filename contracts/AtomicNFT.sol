// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface ICKRegistry {
    function isCK(address owner) external returns (bool);
}

/**
 * @dev An "Atomic" NFT contract that requires a proof of complete knowledge from each token recipient.
 */
contract AtomicNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    ICKRegistry public immutable ckRegistry;
    
    uint256 public mintFee;
    bool public openMintingEnabled = false;
    uint256 public immutable collectionSize;
    
    constructor(ICKRegistry _ckRegistry, uint256 _collectionSize, uint256 _mintFee) ERC721("Atoms", "ATM") {
        ckRegistry = _ckRegistry;
        mintFee = _mintFee;
        collectionSize = _collectionSize;
    }

    /**
     * @dev Returns the base URI of the NFT
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://nftato.ms/api/atom/";
    }
    
    /**
     * @dev Returns information about the collection
     */
    function contractURI() public pure returns (string memory) {
        return "https://nftato.ms/api/collection-metadata";
    }
    
    /**
     * @dev Sets the mint fee, which would exist only to limit the number of
     * NFTs minted per address if open minting is enabled.
     */
    function setMintFee(uint256 newMintFee) public onlyOwner {
        mintFee = newMintFee;
    }
    
    /**
     * @dev Enables or disables open minting by any CK'd address
     */
    function setOpenMintingEnabled(bool enabled) public onlyOwner {
        openMintingEnabled = enabled;
    }
    
    /**
     * @dev Transfers all collected minting fees to another address
     */
    function transferMintingFees(address payable to) public onlyOwner {
        require(to.send(address(this).balance), "Failed to transfer minting fees");
    }

    /**
     * @dev Mint a limited supply NFT
     */
    function _limitedMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        require(tokenId < collectionSize, "All atomic NFTs have been minted");
        _safeMint(to, tokenId);
    }

    /**
     * @dev Mint an atomic NFT to an address that has shown a CK proof
     */
    function mint() public payable {
        require(msg.value >= mintFee, "Minimum mint fee not met");
        require(openMintingEnabled, "Open minting not enabled");
        require(ckRegistry.isCK(msg.sender), "Minter needs a CK proof");
        _limitedMint(msg.sender);
    }

    /**
     * @dev Owner can mint an atomic NFT to an address that has shown a CK proof
     */
    function ownerMint(address to) public onlyOwner {
        _limitedMint(to);
    }
    
    /**
     * @dev Get the current token count
     */
    function tokenCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * This function verifies that the recipient of any transfer has proven to
     * have complete knowledge of its private key. The sender is not checked.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        require(ckRegistry.isCK(to), "Recipient needs a CK proof");
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
