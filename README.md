# DAB - Diamond Authentication Blockchain

Diamond Authentication Blockchain built with Solidity on Ethereum. This project provides a transparent and immutable way to track the provenance of diamonds from mine to consumer.

## Project Overview

This repository contains the smart contracts, frontend interfaces, and Web3.py scripts for interacting with the Diamond Authentication Blockchain.

### Frontend (`frontend/`)

The frontend provides web interfaces for users to interact with the blockchain:

*   **`index.html`**: The entry point for the application.
*   **`entityInterface.html`**: Provides an interface for entities to register.
*   **`provenance.html`**: Interface for diamond provenance. Allows users to connect their wallets and perform actions related to diamond transfer, registration, processing, and certification (depending on their registered role).
*   **`marketplaceInterface.html`**: Interface for a marketplace where retailers and diamonds owners can list and sell diamonds. Additionally where customers (diamond owners) can mark diamonds as stolen or lost.
*   **`contracts.js`**: Export of deployed contract addresses and ABIs.
*   **`spline-loader.js`**: Loads the interactive 3D Spline component on the `index.html` page.

### Python Scripts (`web3-py/`)

These Python scripts are used for backend operations, testing, and direct blockchain interaction via the Web3.py library:

*   **`diamond_lifecycle.py`**: Simulates the complete lifecycle of a diamond as it passes through the supply chain. This includes the registration of a raw diamond, processing by manufacturer, certification by certifier, and ownership transfers through every stage from the miner to retailer.
*   **`check_diamonds.py`**: Displays information about all minted diamonds.

---
This project aims to enhance transparency and trust in the diamond industry by leveraging blockchain technology.
