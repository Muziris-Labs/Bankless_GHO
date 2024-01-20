# Bankless Wallet

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![JavaScript](https://img.shields.io/badge/Javascript-yellow)
![Next.js](https://img.shields.io/badge/Next.js-gray)
![Tailwind](https://img.shields.io/badge/Tailwind-blue)
![Solidity](https://img.shields.io/badge/Solidity-black)
![Noir](https://img.shields.io/badge/Noir-gray)
![CCIP](https://img.shields.io/badge/CCIP-blue)

> Bankless Wallet is a smart contract wallet that leverages zero-knowledge proofs for authentication

Unlike traditional wallets with a defined owner, Bankless Wallet operates on the principle that ownership is established through possession of a valid zero-knowledge proof (zk-proof). This ensures a high level of privacy and security, as the identity of the wallet owner remains confidential.

## Implementation

- Ethereum Sepolia
  - Passkey Verifier - [0xF768fA09b378200811eE0CFe6DeD7B2E830202E5](https://sepolia.etherscan.io/address/0xF768fA09b378200811eE0CFe6DeD7B2E830202E5#code)
  - Recovery Verifier - [0x2020B832f19BCF6aC3ae8073Fe1C8e06140c2306](https://sepolia.etherscan.io/address/0x2020B832f19BCF6aC3ae8073Fe1C8e06140c2306#code)
  - Bankless Gas Tank - [0xADcCA523443cf9e9Cfda181872fB20D286C5ebBc](https://sepolia.etherscan.io/address/0xADcCA523443cf9e9Cfda181872fB20D286C5ebBc#code)
  - Bankless Forwarder - [0x3e4a6B356475BfA8fAC5AE604c3356D8c4b13D3d](https://sepolia.etherscan.io/address/0x3e4a6B356475BfA8fAC5AE604c3356D8c4b13D3d#code)
  - Bankless Factory - [0xbE4db373E362a79e096Daa80B2490EeC86EA1Cb8](https://sepolia.etherscan.io/address/0xbE4db373E362a79e096Daa80B2490EeC86EA1Cb8#code)
- Arbitrum Sepolia
  - Passkey Verifier - [0x2aa4c97688f340C8A2bDE2016b16dEFDC259834D](https://sepolia.arbiscan.io/address/0x2aa4c97688f340C8A2bDE2016b16dEFDC259834D#code)
  - Recovery Verifier - [0x8487F6630510A00bFACd9Fe701700F193F52C04F](https://sepolia.arbiscan.io/address/0x8487f6630510a00bfacd9fe701700f193f52c04f#code)
  - Bankless Gas Tank - [0x2EF41EC23021bD5aBa53C6599D763e89A897Acad](https://sepolia.arbiscan.io/address/0x2EF41EC23021bD5aBa53C6599D763e89A897Acad#code)
  - Bankless Forwarder - [0x75a7d9B87391664F816863e28df0c2e63dfb4543](https://sepolia.arbiscan.io/address/0x75a7d9B87391664F816863e28df0c2e63dfb4543#code)
  - Bankless Factory - [0x14b178b6e888044C84CE4bda3311c0D1D4d066d9](https://sepolia.arbiscan.io/address/0x14b178b6e888044C84CE4bda3311c0D1D4d066d9#code)
- Avalanche Fuji
  - Passkey Verifier - [0xcbd8EF2d15E11fC65793e693d7D11e918fAfa5D6](https://43113.testnet.snowtrace.io/address/0xcbd8EF2d15E11fC65793e693d7D11e918fAfa5D6/contract/43113/code)
  - Recovery Verifier - [0x2aa4c97688f340C8A2bDE2016b16dEFDC259834D](https://43113.testnet.snowtrace.io/address/0x2aa4c97688f340C8A2bDE2016b16dEFDC259834D/contract/43113/code)
  - Bankless Gas Tank - [0x8487F6630510A00bFACd9Fe701700F193F52C04F](https://43113.testnet.snowtrace.io/address/0x8487F6630510A00bFACd9Fe701700F193F52C04F/contract/43113/code)
  - Bankless Forwarder - [0x28327d4cDB91735e45558d2BF88024e90f417c2e](https://43113.testnet.snowtrace.io/address/0x28327d4cDB91735e45558d2BF88024e90f417c2e/contract/43113/code)
  - Bankless Factory - [0x434Fa431E2759393c7CDF01C633DC3d3775d0Fb1](https://43113.testnet.snowtrace.io/address/0x434Fa431E2759393c7CDF01C633DC3d3775d0Fb1/contract/43113/code)

## Features

- Zero-Knowledge Proofs: Bankless Wallet utilizes zero-knowledge proofs to authenticate ownership, allowing users to access their funds without revealing any identifiable information.

- Decentralized: There is no central authority or owner for Bankless Wallet. Ownership is solely determined by possession of the zk-proof.

- Privacy: Users can transact with a high level of privacy since the ownership of the wallet is not tied to any personal information.

- Cross-Chain Support: Bankless Wallet is currently supported on Ethereum Sepolia testnet, Avalanche Fuji testnet, and Arbitrum Sepolia. Cross-chain messaging is achieved through the Chainlink Cross-Chain Interoperability Protocol (CCIP).

- Smart Contract Security: The wallet's functionality is implemented through a smart contract, ensuring the security and transparency of transactions.

- GHO Integration: Bankless Wallet supports the GHO token for Gas Payments, a stablecoin made by AAVE, for stable and reliable value storage.

## License

This project is licensed under the [MIT License](LICENSE).

## Authors

- **Anoy Roy Chowdhury** - [AnoyRC](https://github.com/AnoyRC)
- **Gautam Raj** - [Gautam Raj](https://github.com/Gautam25Raj)
- **Rahul Raj Sarma** - [Rahul Raj Sarma](https://github.com/ragingrahul)
