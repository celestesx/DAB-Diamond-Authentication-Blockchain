import os
import time
import json
from web3 import Web3
from web3.middleware import ExtraDataToPOAMiddleware
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configuration
SEPOLIA_RPC_URL = os.getenv("SEPOLIA_RPC_URL")
ENTITY_CONTRACT_ADDRESS = os.getenv("ENTITY_CONTRACT_ADDRESS")
SEPOLIA_CHAIN_ID = 11155111

# Load contract ABIs from JSON file
try:
    with open('contract_abis.json', 'r') as f:
        contract_abis = json.load(f)
    ENTITY_CONTRACT_ABI = contract_abis['ENTITY_CONTRACT_ABI']
except (FileNotFoundError, json.JSONDecodeError, KeyError) as e:
    print(f"Error loading ABI from JSON file: {e}")
    exit(1)

# Stakeholder details
# Ensure these private keys correspond to accounts with Sepolia ETH
STAKEHOLDERS = [
    {
        "name": "Global Mining Corp",
        "location": "Kimberley, Australia", # Non-blacklisted location
        "role": "Miner",
        "license_prefix": "a",
        "private_key": os.getenv("MINER_PRIVATE_KEY")
    },
    {
        "name": "Precision Cutters Inc.",
        "location": "Antwerp, Belgium", # Non-blacklisted location
        "role": "Manufacturer",
        "license_prefix": "b",
        "private_key": os.getenv("MANUFACTURER_PRIVATE_KEY")
    },
    {
        "name": "GemCertify International",
        "location": "Geneva, Switzerland", # Non-blacklisted location
        "role": "Certifier",
        "license_prefix": "c",
        "private_key": os.getenv("CERTIFIER_PRIVATE_KEY")
    },
    {
        "name": "Luxury Gems Boutique",
        "location": "New York, USA", # Non-blacklisted location
        "role": "Retailer",
        "license_prefix": "d",
        "private_key": os.getenv("RETAILER_PRIVATE_KEY")
    }
]

def connect_and_load_contract():
    """Connects to Web3 and loads the EntityContract."""
    if not SEPOLIA_RPC_URL or not ENTITY_CONTRACT_ADDRESS:
        raise ValueError("Missing RPC URL or contract address in environment variables.")

    w3 = Web3(Web3.HTTPProvider(SEPOLIA_RPC_URL))
    # Inject PoA middleware for Sepolia testnet (Web3.py v7+)
    w3.middleware_onion.inject(ExtraDataToPOAMiddleware(), layer=0)

    if not w3.is_connected():
        raise ConnectionError(f"Failed to connect to Sepolia RPC: {SEPOLIA_RPC_URL}")
    print(f"Successfully connected to Sepolia. Chain ID: {w3.eth.chain_id}")

    # Check if connected to the correct chain
    if w3.eth.chain_id != SEPOLIA_CHAIN_ID:
        print(f"Warning: Connected to chain ID {w3.eth.chain_id}, but expected Sepolia chain ID {SEPOLIA_CHAIN_ID}.")
        # Consider raising an error or exiting if not on the expected chain

    contract = w3.eth.contract(address=Web3.to_checksum_address(ENTITY_CONTRACT_ADDRESS), abi=ENTITY_CONTRACT_ABI)
    return w3, contract

def generate_license_number(prefix, account_address):
    """Generates a unique license number based on prefix and part of the address."""
    timestamp_fragment = str(int(time.time() * 1000))[-4:] # Last 4 digits of ms timestamp
    # Take last 8 chars of the address (without '0x' prefix if it exists)
    addr_part = account_address[-8:] if account_address.startswith('0x') else account_address[-8:]
    return f"{prefix}{addr_part}{timestamp_fragment}"

def register_stakeholder(w3, contract, stakeholder_info):
    """Registers a single stakeholder."""
    if not stakeholder_info["private_key"]:
        print(f"Skipping {stakeholder_info['name']} ({stakeholder_info['role']}): Private key not found in .env file.")
        return

    try:
        # Create account
        try:
            account = w3.eth.account.from_key(stakeholder_info["private_key"])
        except AttributeError:
            from eth_account import Account
            account = Account.from_key(stakeholder_info["private_key"])
            
        account_address = account.address
        print(f"\nAttempting to register {stakeholder_info['name']} ({stakeholder_info['role']}) with address {account_address}")

        # Check if already registered
        try:
            checksum_address = Web3.to_checksum_address(account_address)
            entity_info = contract.functions.getEntityInfo(checksum_address).call()
            if entity_info[2]:  # isRegistered
                print(f"{stakeholder_info['name']} ({account_address}) is already registered as {entity_info[4]}. Skipping.")
                return
        except Exception:
            pass  # Not registered yet, proceed

        license_number = generate_license_number(stakeholder_info["license_prefix"], account_address)
        print(f"Generated License Number: {license_number}")

        # Build transaction
        nonce = w3.eth.get_transaction_count(account_address)
        tx_params = {
            'from': account_address,
            'nonce': nonce,
            'gas': 2000000,
            'gasPrice': w3.eth.gas_price,
            'chainId': SEPOLIA_CHAIN_ID # Adding explicit chainId to avoid issues
        }
        
        transaction = contract.functions.registerEntity(
            stakeholder_info["name"],
            stakeholder_info["location"],
            stakeholder_info["role"],
            license_number
        ).build_transaction(tx_params)

        # Sign and send transaction
        from eth_account import Account
        signed_transaction = Account.sign_transaction(transaction, stakeholder_info["private_key"])
        tx_hash = w3.eth.send_raw_transaction(signed_transaction.raw_transaction)
        print(f"Transaction sent for {stakeholder_info['name']}. Tx Hash: {tx_hash.hex()}")

        print("Waiting for transaction receipt...")
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=180)
        
        if tx_receipt.status == 1:
            print(f"Successfully registered {stakeholder_info['name']} ({stakeholder_info['role']})!")
        else:
            print(f"Failed to register {stakeholder_info['name']}. Transaction status: {tx_receipt.status}")

    except ValueError as ve:
        print(f"ValueError for {stakeholder_info['name']}: {ve}. This might be an issue with the private key format or an invalid address.")
    except Exception as e:
        print(f"An error occurred while registering {stakeholder_info['name']}: {e}")
        if hasattr(e, 'args') and e.args:
            print(f"Error details: {e.args[0]}")

def main():
    """Main function to register all stakeholders."""
    try:
        w3, contract = connect_and_load_contract()
    except Exception as e:
        print(f"Failed to initialize script: {e}")
        return

    print("\n--- Starting Stakeholder Registration ---")
    for stakeholder in STAKEHOLDERS:
        register_stakeholder(w3, contract, stakeholder)
        print("-" * 30)
        time.sleep(3) # Increased delay slightly

    print("\n--- Stakeholder Registration Process Complete ---")

if __name__ == "__main__":
    main()
