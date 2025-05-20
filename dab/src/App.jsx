import { useEffect, useState } from 'react';
import { web3, contract } from './contracts/getContract';

function App() {
  const [account, setAccount] = useState('');
  const [entityInfo, setEntityInfo] = useState(null);

  useEffect(() => {
    async function init() {
      const accounts = await web3.eth.getAccounts();
      setAccount(accounts[0]);

      const info = await contract.methods.getEntityInfo(accounts[0]).call();
      setEntityInfo(info);
    }
    init();
  }, []);

  const registerEntity = async () => {
    await contract.methods
      .registerEntity('Acme Diamonds', 'Botswana', 'Manufacturer', 'b-12345')
      .send({ from: account });

    const info = await contract.methods.getEntityInfo(account).call();
    setEntityInfo(info);
  };

  return (
    <div>
      <h1>Entity Info</h1>
      <button onClick={registerEntity}>Register Entity</button>
      {entityInfo && (
        <pre>{JSON.stringify(entityInfo, null, 2)}</pre>
      )}
    </div>
  );
}

export default App;
