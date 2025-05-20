const Web3 = require('web3');

const fs = require('fs');
const path = require('path');

const web3 = new Web3('http://127.0.0.1:8545/');

const abi = require('./EntityContract.abi.json');
const bytecode = fs.readFileSync('./EntityContract.bytecode.txt', 'utf8');

const contract = new web3.eth.Contract(abi);

async function deploy() {
  const accounts = await web3.eth.getAccounts();
  const result = await contract.deploy({ data: '0x' + bytecode }).send({
    from: accounts[0],
    gas: 3000000,
  });

  console.log('Deployed at:', result.options.address);
  fs.writeFileSync('EntityContract.address.txt', result.options.address);
}

deploy();
