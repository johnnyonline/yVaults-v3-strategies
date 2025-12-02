import json
from web3 import Web3
# from web3.middleware import geth_poa_middleware

# Replace with your Infura project ID or your local node URL
infura_url = "$RPC_URL"
web3 = Web3(Web3.HTTPProvider(infura_url))

# If you're using a testnet like Ropsten, Rinkeby, or Goerli, you may need to add the Geth POA middleware
# web3.middleware_onion.inject(geth_poa_middleware, layer=0)

# Check if connected to Ethereum node
if web3.is_connected():
    print("Connected to Ethereum node")
else:
    print("Failed to connect to Ethereum node")
    exit()

# Replace with your contract address and ABI
contract_address = "0x9FA306b1F4a6a83FEC98d8eBbaBEDfF78C407f6B"

# Load the contract ABI from a JSON file
with open('script/utils/contract_abi.json', 'r') as abi_file:
    contract_abi = json.load(abi_file)

# Create contract instance
contract = web3.eth.contract(address=contract_address, abi=contract_abi)

# Event name to filter
event_name = "RoleSet"

# Get the event object
event = getattr(contract.events, event_name)

# Filter parameters (optional)
from_block = 0
to_block = 'latest'

# Fetch events
events = event.create_filter(fromBlock=from_block, toBlock=to_block).get_all_entries()

# Process and display events
for e in events:
    print(f"Event: {e['event']}")
    print(f"Args: {e['args']}")
    print(f"Transaction Hash: {e['transactionHash'].hex()}")
    print(f"Block Number: {e['blockNumber']}\n")
