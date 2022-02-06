import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { MultiSigWallet } from "../typechain-types";

describe("MultiSigWallet", () => {
  let signers: SignerWithAddress[];
  let addresses: string[];

  beforeEach(async () => {
    signers = await ethers.getSigners();
    addresses = signers.map((s) => s.address);
  });

  describe("when deploying the contract", () => {
    let contract: MultiSigWallet;

    beforeEach(async () => {
      const factory = await ethers.getContractFactory("MultiSigWallet");

      const owners = [addresses[0], addresses[1], addresses[2]];
      const confirmationsRequired = 3;

      contract = await factory.deploy(owners, confirmationsRequired);

      await contract.deployed();
    });

    it("should intitalize state owners with the provided owners", async () => {
      expect(await contract.owners(0)).to.be.equal(addresses[0]);
      expect(await contract.owners(1)).to.be.equal(addresses[1]);
      expect(await contract.owners(2)).to.be.equal(addresses[2]);
    });

    it("should initialize state isOwner mapping according to the provided owners", async () => {
      expect(await contract.isOwner(addresses[0])).to.be.true;
      expect(await contract.isOwner(addresses[1])).to.be.true;
      expect(await contract.isOwner(addresses[2])).to.be.true;
    });

    it("should initialize state confirmationsRequired with provided confirmationsRequired", async () => {
      expect(await contract.confirmationsRequired()).to.be.equal(3);
    });
  });
});
