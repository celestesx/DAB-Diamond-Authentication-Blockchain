import os
import time
import json
import random
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

# Entity credentials
MINER_PRIVATE_KEY = os.getenv("MINER_PRIVATE_KEY")
MANUFACTURER_PRIVATE_KEY = os.getenv("MANUFACTURER_PRIVATE_KEY")
CERTIFIER_PRIVATE_KEY = os.getenv("CERTIFIER_PRIVATE_KEY")

# Diamond randomization options
ORIGINS = [
    "Kimberley, Australia", 
    "Jwaneng, Botswana", 
    "Argyle, Australia", 
    "Orapa, Botswana", 
    "Udachnaya, Russia", 
    "Venetia, South Africa",
    "Mir Mine, Russia",
    "Diavik, Canada",
    "Catoca, Angola"
]

COLORS = ["colorless", "nearly colorless", "faint yellow", "very light yellow", "light yellow", "yellow", "light blue", "pink"]
CLARITY = ["FL", "IF", "VVS1", "VVS2", "VS1", "VS2", "SI1", "SI2", "I1", "I2"]
CRYSTAL_FORMS = ["octahedral", "dodecahedral", "cubic", "macle", "aggregate", "rhombic dodecahedron"]

CUT_TYPES = ["round brilliant", "princess", "emerald", "cushion", "asscher", "radiant", "oval", "pear", "marquise", "heart"]
POLISH_GRADES = ["excellent", "very good", "good", "fair", "poor"]
SYMMETRY_GRADES = ["excellent", "very good", "good", "fair", "poor"]

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

def get_account_address(w3, private_key):
    """Gets the account address from a private key."""
    account = Account.from_key(private_key)
    return account.address

def load_contract(w3, address, abi):
    """Loads a contract instance."""
    return w3.eth.contract(address=Web3.to_checksum_address(address), abi=abi)

def sign_and_send_tx(w3, contract_function, private_key):
    """Signs and sends a transaction, waits for receipt."""
    account = Account.from_key(private_key)
    address = account.address
    
    # Build transaction
    tx_params = {
        'from': address,
        'nonce': w3.eth.get_transaction_count(address),
        'gas': 2000000,
        'gasPrice': w3.eth.gas_price,
        'chainId': SEPOLIA_CHAIN_ID
    }
    
    transaction = contract_function.build_transaction(tx_params)
    signed_tx = Account.sign_transaction(transaction, private_key)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
    print(f"Transaction sent. Hash: {tx_hash.hex()}")
    
    print("Waiting for transaction receipt...")
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=180)
    
    if tx_receipt.status == 1:
        print("Transaction successful!")
        return tx_receipt
    else:
        print(f"Transaction failed. Status: {tx_receipt.status}")
        return None

def get_current_highest_diamond_id(w3, contract):
    """Retrieves the current highest diamond ID from the contract."""
    try:
        total_supply = contract.functions.totalSupply().call()
        print(f"Retrieved total diamond supply: {total_supply}")
        return total_supply
    except Exception as e:
        print(f"Couldn't get total supply: {e}")
        return 0  # Start from 1 for the first diamond

def get_random_raw_weight():
    """Generate a random weight for a raw diamond in points (1 carat = 100 points)"""
    return random.randint(90, 300)  # 0.9 to 3.0 carats

def get_random_processed_weight(raw_weight):
    """Generate a random processed weight based on raw weight (typically 40-60% yield)"""
    yield_factor = random.uniform(0.4, 0.6)
    return int(raw_weight * yield_factor)

def get_random_raw_characteristics(diamond_id):
    """Generate random characteristics for a raw diamond"""
    color = random.choice(COLORS)
    crystal = random.choice(CRYSTAL_FORMS)
    return f"Rough diamond #{diamond_id}, {color}, {crystal} crystal form"

def get_random_processed_characteristics(diamond_id):
    """Generate random characteristics for a processed diamond"""
    color = random.choice(COLORS)
    clarity = random.choice(CLARITY)
    cut = random.choice(CUT_TYPES)
    polish = random.choice(POLISH_GRADES)
    symmetry = random.choice(SYMMETRY_GRADES)
    return f"{cut} cut #{diamond_id}, {clarity} clarity, {color}, {polish} polish, {symmetry} symmetry"

def register_raw_diamond(w3, contract, miner_private_key):
    """Registers a raw diamond as the miner."""
    print("\n=== STEP 1: MINER REGISTERING RAW DIAMOND ===")
    miner_address = get_account_address(w3, miner_private_key)
    print(f"Miner address: {miner_address}")
    
    current_highest_id = get_current_highest_diamond_id(w3, contract)
    expected_new_id = current_highest_id + 1
    
    # Random diamond details
    origin = f"{random.choice(ORIGINS)} #{expected_new_id}"
    extraction_date = int(time.time()) - random.randint(86400 * 7, 86400 * 90)  # 7-90 days ago
    weight = get_random_raw_weight()
    characteristics = get_random_raw_characteristics(expected_new_id)
    
    print(f"Registering raw diamond from {origin} with weight {weight/100} carats...")
    print(f"Characteristics: {characteristics}")
    
    # Call registerRawDiamond function
    register_function = contract.functions.registerRawDiamond(
        origin, extraction_date, weight, characteristics
    )
    
    receipt = sign_and_send_tx(w3, register_function, miner_private_key)
    
    if receipt:
        try:
            # Check if expected_new_id exists and is owned by miner
            owner = contract.functions.getDiamondOwnershipInfo(expected_new_id).call()
            if owner.lower() == miner_address.lower():
                print(f"Successfully verified new diamond ID: {expected_new_id}")
                diamond_id = expected_new_id
            else:
                # If verification failed, get updated total supply
                new_total_supply = contract.functions.totalSupply().call()
                diamond_id = new_total_supply
                print(f"Diamond registered with ID: {diamond_id}")
        except Exception:
            print("Could not determine exact diamond ID. Using expected ID as fallback.")
            diamond_id = expected_new_id
        
        print(f"Raw diamond registered! ID: {diamond_id}")
        return diamond_id
    
    raise Exception("Failed to register raw diamond")

def transfer_diamond(w3, contract, diamond_id, from_private_key, to_address):
    """Transfers a diamond from one entity to another."""
    from_address = get_account_address(w3, from_private_key)
    print(f"\nTransferring diamond ID {diamond_id} from {from_address} to {to_address}...")
    
    # Call transferDiamond function
    transfer_function = contract.functions.transferDiamond(diamond_id, to_address)
    
    receipt = sign_and_send_tx(w3, transfer_function, from_private_key)
    
    if receipt:
        print(f"Diamond ID {diamond_id} transferred successfully!")
        return True
    
    raise Exception(f"Failed to transfer diamond ID {diamond_id}")

def process_diamond(w3, contract, raw_diamond_id, manufacturer_private_key):
    """Processes a raw diamond as the manufacturer."""
    print("\n=== STEP 2: MANUFACTURER PROCESSING RAW DIAMOND ===")
    manufacturer_address = get_account_address(w3, manufacturer_private_key)
    print(f"Manufacturer address: {manufacturer_address}")
    
    current_highest_id = get_current_highest_diamond_id(w3, contract)
    expected_new_id = current_highest_id + 1
    
    # Get original raw diamond weight
    try:
        basic_info = contract.functions.getDiamondBasicInfo(raw_diamond_id).call()
        raw_weight = basic_info[2]  # weight is at index 2
    except Exception:
        print("Could not retrieve raw diamond weight, using default")
        raw_weight = 150
    
    # Random processing details
    new_weight = get_random_processed_weight(raw_weight)
    new_characteristics = get_random_processed_characteristics(expected_new_id)
    
    print(f"Processing raw diamond ID {raw_diamond_id} to new weight {new_weight/100} carats...")
    print(f"Characteristics: {new_characteristics}")
    
    # Call processDiamond function
    process_function = contract.functions.processDiamond(
        raw_diamond_id, new_weight, new_characteristics
    )
    
    receipt = sign_and_send_tx(w3, process_function, manufacturer_private_key)
    
    if receipt:
        try:
            # Check if expected_new_id exists and is linked to raw diamond
            owner = contract.functions.getDiamondOwnershipInfo(expected_new_id).call()
            cert_info = contract.functions.getDiamondCertInfo(expected_new_id).call()
            
            if owner.lower() == manufacturer_address.lower() and cert_info[2] == raw_diamond_id:
                processed_diamond_id = expected_new_id
            else:
                # If verification failed, get updated total supply
                new_total_supply = contract.functions.totalSupply().call()
                processed_diamond_id = new_total_supply
        except Exception:
            processed_diamond_id = expected_new_id
        
        print(f"Diamond processed successfully! New processed diamond ID: {processed_diamond_id}")
        return processed_diamond_id
    
    raise Exception("Failed to process diamond")

def certify_diamond(w3, contract, diamond_id, certifier_private_key):
    """Certifies a diamond as the certifier."""
    print("\n=== STEP 3: CERTIFIER CERTIFYING DIAMOND ===")
    certifier_address = get_account_address(w3, certifier_private_key)
    print(f"Certifier address: {certifier_address}")
    
    # Generate random certification number with timestamp and diamond ID
    timestamp = int(time.time())
    random_suffix = ''.join(random.choices('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', k=6))
    certification_id = f"GIA-{diamond_id}-{timestamp}-{random_suffix}"
    
    print(f"Certifying diamond ID {diamond_id} with certification ID: {certification_id}...")
    
    # Call certifyDiamond function
    certify_function = contract.functions.certifyDiamond(diamond_id, certification_id)
    
    receipt = sign_and_send_tx(w3, certify_function, certifier_private_key)
    
    if receipt:
        print(f"Diamond ID {diamond_id} certified successfully with certification ID: {certification_id}")
        return True
    
    raise Exception(f"Failed to certify diamond ID {diamond_id}")

def display_diamond_info(w3, contract, diamond_id):
    """Displays comprehensive information about a diamond."""
    print(f"\n=== DIAMOND ID {diamond_id} INFORMATION ===")
    
    try:
        # Get basic info
        basic_info = contract.functions.getDiamondBasicInfo(diamond_id).call()
        origin, extraction_date, weight, characteristics = basic_info
        
        # Get certification info
        cert_info = contract.functions.getDiamondCertInfo(diamond_id).call()
        is_certified, certification_id, raw_diamond_id = cert_info
        
        # Get ownership info
        current_owner = contract.functions.getDiamondOwnershipInfo(diamond_id).call()
        
        # Get history
        try:
            history = contract.functions.getDiamondHistory(diamond_id).call()
        except Exception:
            history = []
        
        # Display information
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
        
        print("\nDiamond History:")
        for i, record in enumerate(history):
            print(f"  {i+1}. {record}")
            
    except Exception as e:
        print(f"Error retrieving diamond information: {e}")

def main():
    """Main function to execute the complete diamond lifecycle."""
    try:
        # Connect to Web3
        w3 = connect_to_web3()
        
        # Load contract instance
        contract = load_contract(w3, PROVENANCE_CONTRACT_ADDRESS, PROVENANCE_CONTRACT_ABI)
        
        # Get account addresses
        miner_address = get_account_address(w3, MINER_PRIVATE_KEY)
        manufacturer_address = get_account_address(w3, MANUFACTURER_PRIVATE_KEY)
        certifier_address = get_account_address(w3, CERTIFIER_PRIVATE_KEY)
        
        print(f"Miner Address: {miner_address}")
        print(f"Manufacturer Address: {manufacturer_address}")
        print(f"Certifier Address: {certifier_address}")
        
        # Step 1: Register a new raw diamond
        raw_diamond_id = register_raw_diamond(w3, contract, MINER_PRIVATE_KEY)
        display_diamond_info(w3, contract, raw_diamond_id)
        
        # Step 2: Miner transfers diamond to manufacturer
        print("\n=== STEP 1: MINER TRANSFERRING DIAMOND TO MANUFACTURER ===")
        transfer_diamond(w3, contract, raw_diamond_id, MINER_PRIVATE_KEY, manufacturer_address)
        display_diamond_info(w3, contract, raw_diamond_id)
        
        # Step 3: Manufacturer processes the diamond
        processed_diamond_id = process_diamond(w3, contract, raw_diamond_id, MANUFACTURER_PRIVATE_KEY)
        display_diamond_info(w3, contract, processed_diamond_id)
        
        # Step 4: Manufacturer transfers processed diamond to certifier
        print(f"\n=== STEP 3: MANUFACTURER TRANSFERRING PROCESSED DIAMOND TO CERTIFIER ===")
        transfer_diamond(w3, contract, processed_diamond_id, MANUFACTURER_PRIVATE_KEY, certifier_address)
        display_diamond_info(w3, contract, processed_diamond_id)
        
        # Step 5: Certifier certifies the diamond
        certify_diamond(w3, contract, processed_diamond_id, CERTIFIER_PRIVATE_KEY)
        display_diamond_info(w3, contract, processed_diamond_id)
        
        print("\n=== DIAMOND LIFECYCLE COMPLETED SUCCESSFULLY ===")
        print(f"Raw Diamond ID: {raw_diamond_id}")
        print(f"Processed Diamond ID: {processed_diamond_id}")
        
    except Exception as e:
        print(f"\nAn error occurred: {e}")

if __name__ == "__main__":
    main() 