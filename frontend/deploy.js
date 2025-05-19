const Web3 = require('web3');
const fs = require('fs');
const web3 = new Web3('http://localhost:7545');

const abi = JSON.parse(fs.readFileSync('./frontend/abi/EntityContract.abi.json', 'utf8'));
const bytecode = '0x' + fs.readFileSync('./frontend/abi/EntityContract.bytecode.txt', 'utf8');

async function deploy() {
  const accounts = await web3.eth.getAccounts();
  const contract = new web3.eth.Contract(abi);

  const deployed = await contract.deploy({ data: bytecode }).send({
    from: accounts[0],
    gas: 3000000
  });

  console.log('Contract deployed at:', deployed.options.address);
}

deploy().catch(console.error);
