const Web3 = require('web3');
const path = require('path');
const fs = require('fs');

// Connect to Hardhat's local blockchain
const web3 = new Web3('http://127.0.0.1:8545/');

// Read deployed contract address
const deployedAddressPath = path.join(__dirname, 'EntityContract.address.txt');
const deployedAddress = fs.readFileSync(deployedAddressPath, 'utf8');

// Read ABI
const abi = require('./EntityContract.abi.json');

// Create contract instance
const entityContract = new web3.eth.Contract(abi, deployedAddress);
entityContract.handleRevert = true;

async function interact() {
	const accounts = await web3.eth.getAccounts();
	const defaultAccount = accounts[0];

	try {
		// Register a new entity
		const receipt = await entityContract.methods
			.registerEntity('Acme Diamonds', 'Botswana', 'Manufacturer', 'b-12345')

			.send({
				from: defaultAccount,
				gas: 3000000,
				gasPrice: '10000000000',
			});
		console.log('Transaction Hash:', receipt.transactionHash);

		// Fetch entity info
		const entityInfo = await entityContract.methods.getEntityInfo(defaultAccount).call();
		console.log('Entity Info:', entityInfo);

	} catch (error) {
		console.error('Error interacting with contract:', error.message);
	}
}

interact();
