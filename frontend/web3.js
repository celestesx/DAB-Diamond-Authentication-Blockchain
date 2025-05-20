import Web3 from 'web3';
import EntityContractABI from './EntityContractAbi.json';
import contractAddress from './EntityContractAddress.json';

const getWeb3 = async () => {
  if (window.ethereum) {
    const web3 = new Web3(window.ethereum);
    await window.ethereum.request({ method: 'eth_requestAccounts' });
    return web3;
  } else {
    alert("Please install MetaMask to use this app");
  }
};

const getContract = async (web3) => {
  return new web3.eth.Contract(EntityContractABI, contractAddress);
};

export { getWeb3, getContract };


