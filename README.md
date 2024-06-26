# Propy-NFT-Lending

Propy NFT lending contracts as requested by this [bounty](https://www.bountycaster.xyz/bounty/0x64484c7258b37a7736e030fc693bf89f720d7743). 

Built using [Foundry](https://book.getfoundry.sh/).

### Design

The loan factory can be used to create mutliple loans, each with their own NFT collateral and loan conditions, as detailed below:

![Overview](./assets/overviewV0.jpg)

The user flow for a loan:

![Flow](./assets/flowV0.jpg)


### Installation

- Clone the repo.
- Create a `.env` file modelled after the `.envSample`.
- Run `forge build`.

### Resources

- [Propy](https://propy.com/home/)
- Propy Base NFTs: [0xa239b9b3e00637f29f6c7c416ac95127290b950e](https://basescan.org/address/0xa239b9b3e00637f29f6c7c416ac95127290b950e#code)
- Propy [Constants](https://github.com/Propy/Propy.Web3Portal/blob/dev/src/utils/constants.ts)
- Propy [Payment PRO](https://github.com/Propy/Propy.PaymentPRO)