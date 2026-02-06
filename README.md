# Cicerone (CIC) Token Smart Contract

A professional **ERC-20** token implementation with a built-in **1% transaction tax** mechanism, optimized for the Ethereum ecosystem.

---

## 🛠 Tech Stack

The project utilizes a modern blockchain development stack:

| Category | Technology | Description |
| --- | --- | --- |
| **Smart Contract** | **Solidity ^0.8.0** | Features native overflow protection and structured error handling. |
| **Token Standard** | **ERC-20** | Ensures compatibility with all major wallets (MetaMask) and exchanges. |
| **Development** | **Remix IDE** | Cloud-based environment for compiling, debugging, and deploying. |
| **Libraries** | **Ethers.js / Web3.js** | Used for interacting with the Ethereum Virtual Machine (EVM). |
| **Testing** | **Mocha & Chai** | (Optional) Used for unit testing the tax logic and balances. |

---

## 💻 IDE Usage (Remix IDE)

This project is designed to be managed and deployed via **Remix IDE**. Follow these steps for a successful setup:

### 1. Workspace Initialization

* Access [remix.ethereum.org](https://remix.ethereum.org).
* Upload `CIC.sol` and `remix.config.json` to your workspace.

### 2. Compilation

* Open the **Solidity Compiler** tab.
* **Compiler Version:** Select `0.8.0` or higher.
* **Configuration:** Ensure "Enable optimization" is checked for lower gas costs.
* Click **Compile CIC.sol**.

### 3. Deployment & Interaction

* Open the **Deploy & Run Transactions** tab.
* **Environment:** * Use *Remix VM* for local testing.
* Use *Injected Provider (MetaMask)* for Sepolia or Mainnet deployment.


* **Contract Selection:** Ensure `Cicerone - CIC.sol` is selected.
* **Action:** Click **Deploy**. The total supply (1 Billion CIC) will be minted to your wallet.

---

## 🪙 Token Logic & Tax Mechanism

* **Total Supply:** 1,000,000,000 CIC (fixed).
* **Decimals:** 6.
* **1% Transfer Tax:** * Every transaction (except minting) incurs a 1% fee.
* The tax is automatically diverted to the `owner` address (the deployer).
* **Example:** Sending 1,000 CIC results in 990 CIC reaching the recipient and 10 CIC reaching the owner.



---

## ⚙️ Hardhat Configuration (Local Development)

If you prefer to move this project to a local environment using **Hardhat**, create a `hardhat.config.js` file with the following setup:

```javascript
/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: {
    version: "0.8.20", // Matches the ^0.8.0 requirement
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    // Localhost network
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    // Configuration for Sepolia Testnet
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY",
      accounts: ["0xYOUR_PRIVATE_KEY"]
    }
  }
};

```

### Deployment Script (`scripts/deploy.js`)

```javascript
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const Cicerone = await hre.ethers.getContractFactory("Cicerone");
  const cic = await Cicerone.deploy();

  console.log("Cicerone (CIC) deployed to:", cic.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

```

---

## 📄 License

This project is licensed under the **MIT License**.
