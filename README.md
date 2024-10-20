## Power Agents Smart Contracts Overview

This repository contains a suite of smart contracts designed to facilitate seamless cross-chain communication and interactions with DeFi protocols using LayerZero infrastructure and ENS off-chain resolution capabilities. Below is an overview of the core contracts included:

### **1. AgentCreate3Factory**
The `AgentCreate3Factory` contract is a factory leveraging the `create3` opcode for deterministic contract deployments. It allows for the deployment of `PowerAgentsOApp` contracts with a known address across different chains, ensuring that contracts can be deployed at the same address, enhancing predictability and reducing deployment costs. This contract is crucial for the creation of new `PowerAgentsOApp` instances in a decentralized and efficient manner.

### **2. PowerAgentsOApp**
The `PowerAgentsOApp` contract is a cross-chain Oracle Application (OApp) built on LayerZero, enabling decentralized and trustless communication between different blockchain networks. The contract implements all necessary methods for sending and receiving messages across chains. Upon receiving a message, it triggers specific function calls to interact with DeFi protocols such as depositing or withdrawing funds, enabling seamless cross-chain DeFi operations.

### **3. EnsOffchainResolver**
The `EnsOffchainResolver` is a smart contract serving as a gateway for off-chain resolution of ENS (Ethereum Name Service) subdomains. It facilitates off-chain data lookups for ENS names, allowing users to resolve subdomains with the aid of external off-chain infrastructure. This contract plays a pivotal role in enabling decentralized naming systems to operate with off-chain data, extending the capabilities of ENS for broader use cases.

These contracts work together to create a robust and scalable environment for cross-chain DeFi interactions, ensuring efficiency, security, and flexibility across different blockchain ecosystems.


#### Installing dependencies

We recommend using `pnpm` as a package manager (but you can of course use a package manager of your choice):

```bash
pnpm install
```

#### Compiling contracts

This project supports both `hardhat` and `forge` compilation. By default, the `compile` command will execute both:

```bash
pnpm compile
```

#### Running tests

Similarly to the contract compilation, we support both `hardhat` and `forge` tests. By default, the `test` command will execute both:

```bash
pnpm test
```

