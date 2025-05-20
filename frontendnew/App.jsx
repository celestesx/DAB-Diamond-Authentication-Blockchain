import React, { useEffect, useState } from 'react';
import { getWeb3, getContract } from './web3';

function App() {
  const [account, setAccount] = useState('');
  const [contract, setContract] = useState(null);
  const [entityInfo, setEntityInfo] = useState(null);

  useEffect(() => {
    const init = async () => {
      const web3 = await getWeb3();
      const accounts = await web3.eth.getAccounts();
      setAccount(accounts[0]);

      const entityContract = await getContract(web3);
      setContract(entityContract);

      const info = await entityContract.methods.getEntityInfo(accounts[0]).call();
      setEntityInfo(info);
    };

    init();
  }, []);

  return (
    <div>
      <h1>Entity Contract Frontend</h1>
      <p><strong>Connected Account:</strong> {account}</p>
      {entityInfo && (
        <div>
          <p><strong>Name:</strong> {entityInfo.name}</p>
          <p><strong>Location:</strong> {entityInfo.location}</p>
          <p><strong>Role:</strong> {entityInfo.role}</p>
          <p><strong>License:</strong> {entityInfo.licenseNumber}</p>
          <p><strong>Registered:</strong> {entityInfo.isRegistered.toString()}</p>
        </div>
      )}
    </div>
  );
}

export default App;
