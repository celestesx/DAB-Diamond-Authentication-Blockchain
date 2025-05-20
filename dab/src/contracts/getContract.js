import Web3 from 'web3';
import abi from './EntityContract.abi.json';
import contractAddress from './EntityContract.address.txt?raw';

const web3 = new Web3('http://127.0.0.1:8545/');
const contract = new web3.eth.Contract(JSON.parse(abi), contractAddress.trim());

export { web3, contract };
