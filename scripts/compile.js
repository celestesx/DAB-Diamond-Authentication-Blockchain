const solc = require('solc');
const path = require('path');
const fs = require('fs');

const contractName = 'EntityContract';
const fileName = `./contracts/${contractName}.sol`;
const sourceCode = fs.readFileSync(fileName, 'utf8');

const input = {
  language: 'Solidity',
  sources: {
    [`${contractName}.sol`]: {
      content: sourceCode,
    },
  },
  settings: {
    outputSelection: {
      '*': {
        '*': ['*'],
      },
    },
  },
};

const compiled = JSON.parse(solc.compile(JSON.stringify(input)));
const contract = compiled.contracts[`${contractName}.sol`][contractName];

fs.writeFileSync('EntityContract.abi.json', JSON.stringify(contract.abi, null, 2));
fs.writeFileSync('EntityContract.bytecode.txt', contract.evm.bytecode.object);

console.log('ABI and bytecode generated!');
