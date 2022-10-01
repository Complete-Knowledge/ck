// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.17;

interface ICKRegistry {
    function isCK(address owner) external returns (bool);
}

/**
 * @dev An "Atomic" NFT contract that requires a proof of complete knowledge from each token recipient.
 */
contract AtomicNFT is ERC721, Ownable {
    ICKRegistry public immutable ckRegistry;
    
    constructor(ICKRegistry _ckRegistry) ERC721("Atoms", "ATM") {
        ckRegistry = _ckRegistry;
    }

    /**
     * @dev Returns the base URI of the NFT
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://nftato.ms/atom/";
    }

    /**
     * @dev An owner-only mint function
     */
    function safeMint(address to, uint256 tokenId) public onlyOwner {
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
        require(ckRegistry.isCK(to), "Recipient's address needs to be verified with a CK proof");
    }
}
