import os
import time
import json
from web3 import Web3
from web3.middleware import ExtraDataToPOAMiddleware
from eth_account import Account
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configuration
SEPOLIA_RPC_URL = os.getenv("SEPOLIA_RPC_URL")
PROVENANCE_CONTRACT_ADDRESS = os.getenv("PROVENANCE_CONTRACT_ADDRESS")
SEPOLIA_CHAIN_ID = 11155111

# Entity credentials from .env
MINER_PRIVATE_KEY = os.getenv("MINER_PRIVATE_KEY")
MANUFACTURER_PRIVATE_KEY = os.getenv("MANUFACTURER_PRIVATE_KEY")
CERTIFIER_PRIVATE_KEY = os.getenv("CERTIFIER_PRIVATE_KEY")

# Load contract ABIs from JSON file
try:
    with open('contract_abis.json', 'r') as f:
        contract_abis = json.load(f)
    PROVENANCE_CONTRACT_ABI = contract_abis['PROVENANCE_CONTRACT_ABI']
except (FileNotFoundError, json.JSONDecodeError, KeyError) as e:
    print(f"Error loading ABI from JSON file: {e}")
    exit(1)

def connect_to_web3():
    """Creates a Web3 connection to Sepolia."""
    if not SEPOLIA_RPC_URL:
        raise ValueError("SEPOLIA_RPC_URL not found in environment variables.")
        
    w3 = Web3(Web3.HTTPProvider(SEPOLIA_RPC_URL))
    w3.middleware_onion.inject(ExtraDataToPOAMiddleware(), layer=0)
    
    if not w3.is_connected():
        raise ConnectionError(f"Failed to connect to Sepolia RPC: {SEPOLIA_RPC_URL}")
    print(f"Successfully connected to Sepolia. Chain ID: {w3.eth.chain_id}")
    
    return w3

def get_account_address(private_key):
    """Gets the account address from a private key."""
    account = Account.from_key(private_key)
    return account.address

def load_contract(w3, address, abi):
    """Loads a contract instance."""
    return w3.eth.contract(address=Web3.to_checksum_address(address), abi=abi)

def display_diamond_info(contract, diamond_id):
    """Displays comprehensive information about a diamond."""
    try:
        # Get basic info
        basic_info = contract.functions.getDiamondBasicInfo(diamond_id).call()
        origin, extraction_date, weight, characteristics = basic_info
        
        # Get certification info
        cert_info = contract.functions.getDiamondCertInfo(diamond_id).call()
        is_certified, certification_id, raw_diamond_id = cert_info
        
        # Get ownership info
        current_owner = contract.functions.getDiamondOwnershipInfo(diamond_id).call()
        
        # Display information
        print(f"\n=== DIAMOND ID {diamond_id} INFORMATION ===")
        print(f"Origin: {origin}")
        print(f"Extraction Date: {time.strftime('%Y-%m-%d', time.localtime(extraction_date))}")
        print(f"Weight: {weight/100} carats")
        print(f"Characteristics: {characteristics}")
        print(f"Current Owner: {current_owner}")
        print(f"Is Certified: {'Yes' if is_certified else 'No'}")
        if is_certified:
            print(f"Certification ID: {certification_id}")
        if raw_diamond_id > 0:
            print(f"Processed from Raw Diamond ID: {raw_diamond_id}")
            
        return True
    except Exception as e:
        print(f"Error or diamond doesn't exist: {e}")
        return False

def main():
    """Main function to check diamond ownership."""
    try:
        # Connect to Web3
        w3 = connect_to_web3()
        
        # Load contract instance
        contract = load_contract(w3, PROVENANCE_CONTRACT_ADDRESS, PROVENANCE_CONTRACT_ABI)
        
        # Get account addresses from private keys
        miner_address = get_account_address(MINER_PRIVATE_KEY)
        manufacturer_address = get_account_address(MANUFACTURER_PRIVATE_KEY)
        certifier_address = get_account_address(CERTIFIER_PRIVATE_KEY)
        
        print(f"Miner Address: {miner_address}")
        print(f"Manufacturer Address: {manufacturer_address}")
        print(f"Certifier Address: {certifier_address}")
        
        # Get total supply to know how many diamonds exist
        try:
            total_supply = contract.functions.totalSupply().call()
            print(f"\nTotal diamonds in system: {total_supply}")
        except Exception as e:
            print(f"Error getting total supply: {e}")
            total_supply = 10
        
        # Check all diamonds
        print("\nChecking all diamonds:")
        for i in range(1, total_supply + 1):
            success = display_diamond_info(contract, i)
            if not success:
                print(f"Diamond ID {i} does not exist or error occurred")
            
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main() 