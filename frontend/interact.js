const Web3 = require('web3');

const fs = require('fs');

const web3 = new Web3('http://localhost:7545');  //Ganache RPC SERVER




const abi = JSON.parse(fs.readFileSync(__dirname + '/abi/EntityContract.abi.json', 'utf8'));
const contractAddress = '0x358AA13c52544ECCEF6B0ADD0f801012ADAD5eE3';
const entityContract = new web3.eth.Contract(abi, contractAddress);

async function registerEntity() {
  const accounts = await web3.eth.getAccounts();
  const from = accounts[0];

  try {
    const receipt = await entityContract.methods
      .registerEntity("Acme Diamonds", "Botswana", "Manufacturer", "b-12345")
      .send({ from, gas: 3000000 });

    console.log("Registered entity:", receipt.events.EntityRegistered.returnValues);
  } catch (err) {
    console.error("Registration failed:", err.message);
  }
}

registerEntity();
