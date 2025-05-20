const { Web3 } = require('web3');
const path = require('path');
const fs = require('fs');

// Connect to local Hardhat node
const web3 = new Web3('http://127.0.0.1:8545/');

// Load contract ABI and address
const abiPath = path.join(__dirname, 'EntityContract.abi.json');
const contractAddressPath = path.join(__dirname, 'MyContractAddress.txt');

const abi = JSON.parse(fs.readFileSync(abiPath, 'utf8'));
const contractAddress = fs.readFileSync(contractAddressPath, 'utf8');

// Create contract instance
const contract = new web3.eth.Contract(abi, contractAddress);
contract.handleRevert = true;

async function interact() {
  const accounts = await web3.eth.getAccounts();
  const sender = accounts[0]; // use first account

  try {
    // Read current value
    const currentValue = await contract.methods.myNumber().call();
    console.log('Current myNumber:', currentValue);

    // Send transaction to update value
    const tx = await contract.methods.setMyNumber(Number(currentValue) + 1).send({
      from: sender,
      gas: 3000000,
    });

    console.log('Transaction Hash:', tx.transactionHash);

    // Read updated value
    const updatedValue = await contract.methods.myNumber().call();
    console.log('Updated myNumber:', updatedValue);
  } catch (err) {
    console.error('Error interacting with contract:', err);
  }
}

interact();
