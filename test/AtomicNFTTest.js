const {
  loadFixture,
} = require('@nomicfoundation/hardhat-network-helpers');
const { ethers } = require('hardhat');

const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
const fs = require('fs');

chai.use(chaiAsPromised);
const { expect } = chai;

describe('AtomicNFT', () => {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployNFTFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, verifiedAccount, otherAccount] = await ethers.getSigners();

    const Registry = await ethers.getContractFactory('CKRegistry');
    const registry = await Registry.deploy();

    const Verifier = await ethers.getContractFactory('TestCKVerifier');
    const verifier = await Verifier.deploy();

    await verifier.setCKVerified(verifiedAccount.address, true);
    // Assign bit (1 << 0x0) = 0x1
    await registry.assignVerifierAddress(verifier.address, 0);
    await registry.trustVerificationBit(0, true);
    await registry.registerCK(verifiedAccount.address, verifier.address);

    const NFTFactory = await ethers.getContractFactory('AtomicNFT');
    // We will set the collection size to 19 for testing
    const atomicNFT = await NFTFactory.deploy(registry.address, 19, 0);

    return {
      atomicNFT, registry, verifier, owner, verifiedAccount, otherAccount,
    };
  }

  describe('Access', () => {
    it('Should not allow open minting when it is not enabled', async () => {
      const { atomicNFT, verifiedAccount } = await loadFixture(deployNFTFixture);
      await expect(atomicNFT.connect(verifiedAccount).mint())
        .to.be.revertedWith('Open minting not enabled');
    });
  });

  describe('Minting', () => {
    it('Should not allow minting to a non-CK address', async () => {
      const { atomicNFT, otherAccount } = await loadFixture(deployNFTFixture);
      await atomicNFT.setOpenMintingEnabled(true);
      await expect(atomicNFT.connect(otherAccount).mint())
        .to.be.revertedWith('Minter needs a CK proof');
    });
    it('Should not allow minting to a non-CK address by the owner', async () => {
      const { atomicNFT, otherAccount } = await loadFixture(deployNFTFixture);
      await atomicNFT.setOpenMintingEnabled(true);
      await expect(atomicNFT.ownerMint(otherAccount.address))
        .to.be.revertedWith('Recipient needs a CK proof');
    });
    it('Should not allow minting that does not pay the required fee, if applicable', async () => {
      const { atomicNFT, verifiedAccount } = await loadFixture(deployNFTFixture);
      await atomicNFT.setMintFee(ethers.utils.parseEther('0.1'));
      await atomicNFT.setOpenMintingEnabled(true);
      await expect(atomicNFT.connect(verifiedAccount).mint({ value: ethers.utils.parseEther('0.1').sub(1) }))
        .to.be.revertedWith('Minimum mint fee not met');
    });
    it('Should allow minting that pays the required fee, if applicable', async () => {
      const { atomicNFT, verifiedAccount } = await loadFixture(deployNFTFixture);
      await atomicNFT.setMintFee(ethers.utils.parseEther('0.1'));
      await atomicNFT.setOpenMintingEnabled(true);
      await expect(atomicNFT.connect(verifiedAccount).mint({ value: ethers.utils.parseEther('0.1') }))
        .to.not.be.reverted;
      await expect(atomicNFT.ownerOf(0)).to.eventually.equal(verifiedAccount.address);
    });
    it('Should allow minting fees to be withdrawn', async () => {
      const { atomicNFT, verifiedAccount, otherAccount } = await loadFixture(deployNFTFixture);
      await atomicNFT.setMintFee(ethers.utils.parseEther('0.1'));
      await atomicNFT.setOpenMintingEnabled(true);
      await atomicNFT.connect(verifiedAccount).mint({ value: ethers.utils.parseEther('0.1') });

      // Minting fee can be taken out
      const prevBalance = await ethers.provider.getBalance(otherAccount.address);
      await atomicNFT.transferMintingFees(otherAccount.address);
      await expect(ethers.provider.getBalance(otherAccount.address)).to.eventually.equal(
        prevBalance.add(ethers.utils.parseEther('0.1')),
      );
      await expect(ethers.provider.getBalance(atomicNFT.address))
        .to.eventually.equal(ethers.BigNumber.from(0));
    });
    it('Should enforce a maximum collection size', async () => {
      const { atomicNFT, verifiedAccount } = await loadFixture(deployNFTFixture);
      const collectionSize = (await atomicNFT.collectionSize()).toNumber();
      for (let i = 0; i < collectionSize; i += 1) {
        // eslint-disable-next-line
        await atomicNFT.ownerMint(verifiedAccount.address);
      }
      await expect(atomicNFT.ownerMint(verifiedAccount.address))
        .to.be.revertedWith('All atomic NFTs have been minted');
    });
  });

  describe('CK verification', () => {
    it('Should not allow a transfer to a non-CK address', async () => {
      const { atomicNFT, verifiedAccount, otherAccount } = await loadFixture(deployNFTFixture);
      const res = await atomicNFT.ownerMint(verifiedAccount.address);
      const { tokenId } = (await res.wait()).events[0].args;
      await expect(atomicNFT.connect(verifiedAccount)['safeTransferFrom(address,address,uint256)'](verifiedAccount.address, otherAccount.address, tokenId))
        .to.be.revertedWith('Recipient needs a CK proof');
      await expect(atomicNFT.connect(verifiedAccount)['safeTransferFrom(address,address,uint256,bytes)'](verifiedAccount.address, otherAccount.address, tokenId, '0x'))
        .to.be.revertedWith('Recipient needs a CK proof');
      await expect(atomicNFT.connect(verifiedAccount)['transferFrom(address,address,uint256)'](verifiedAccount.address, otherAccount.address, tokenId))
        .to.be.revertedWith('Recipient needs a CK proof');
    });
    it('Should allow a transfer to a CK address', async () => {
      const {
        atomicNFT, registry, verifier, verifiedAccount, otherAccount,
      } = await loadFixture(deployNFTFixture);
      const res = await atomicNFT.ownerMint(verifiedAccount.address);
      const { tokenId } = (await res.wait()).events[0].args;
      await verifier.setCKVerified(otherAccount.address, true);
      await registry.registerCK(otherAccount.address, verifier.address);
      await expect(atomicNFT.connect(verifiedAccount)['safeTransferFrom(address,address,uint256)'](verifiedAccount.address, otherAccount.address, tokenId))
        .to.not.be.reverted;
      await expect(atomicNFT.ownerOf(tokenId)).to.eventually.equal(otherAccount.address);
      await expect(atomicNFT.connect(otherAccount)['safeTransferFrom(address,address,uint256,bytes)'](otherAccount.address, verifiedAccount.address, tokenId, '0x'))
        .to.not.be.reverted;
      await expect(atomicNFT.ownerOf(tokenId)).to.eventually.equal(verifiedAccount.address);
      await expect(atomicNFT.connect(verifiedAccount)['transferFrom(address,address,uint256)'](verifiedAccount.address, otherAccount.address, tokenId))
        .to.not.be.reverted;
      await expect(atomicNFT.ownerOf(tokenId)).to.eventually.equal(otherAccount.address);
    });
  });

  describe('Source code', () => {
    it('Should produce source code', async () => {
      const { atomicNFT } = await loadFixture(deployNFTFixture);
      const cmapUtilsPy = await atomicNFT.sourceCodeCmapUtilsPy();
      fs.writeFile('./artifacts/cmap_utils.py', cmapUtilsPy, () => {});
      const atomicNFTPy = await atomicNFT.sourceCodeAtomicNftPy();
      fs.writeFile('./artifacts/atomic_nft.py', atomicNFTPy, () => {});
    });
  });
});
