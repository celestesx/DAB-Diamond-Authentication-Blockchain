// Diamond Authentication Blockchain - Smart Contract Configuration

// Contract Addresses - Sepolia Testnet
export const CONTRACT_ADDRESSES = {
  // Entity Contract
  ENTITY_CONTRACT: "0xb2b2292157a55ca85c59A302d3474A93248966c2",
  
  // Provenance Contract
  PROVENANCE_CONTRACT: "0x78E2F9805d52c97e04dFa33d0974ea304137725a",
  
  // Marketplace Contract
  MARKETPLACE_CONTRACT: "0x927348942Fdd71b328A3b21B9f172bD35F072e6d", //
};

// Contract ABIs
export const CONTRACT_ABIS = {
  // Entity Contract ABI
  ENTITY_CONTRACT: [
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "address",
          name: "entityAddress",
          type: "address",
        },
        {
          indexed: false,
          internalType: "string",
          name: "name",
          type: "string",
        },
        {
          indexed: false,
          internalType: "string",
          name: "role",
          type: "string",
        },
        {
          indexed: false,
          internalType: "string",
          name: "licenseNumber",
          type: "string",
        },
      ],
      name: "EntityRegistered",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: false,
          internalType: "string",
          name: "name",
          type: "string",
        },
        {
          indexed: false,
          internalType: "string",
          name: "location",
          type: "string",
        },
        {
          indexed: false,
          internalType: "string",
          name: "reason",
          type: "string",
        },
      ],
      name: "RegistrationRejected",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: false,
          internalType: "address",
          name: "from",
          type: "address",
        },
        {
          indexed: false,
          internalType: "address",
          name: "to",
          type: "address",
        },
        {
          indexed: false,
          internalType: "bool",
          name: "isValid",
          type: "bool",
        },
        {
          indexed: false,
          internalType: "string",
          name: "message",
          type: "string",
        },
      ],
      name: "ValidationResponse",
      type: "event",
    },
    // Add the rest of the entity contract ABI here
  ],

  // Provenance Contract ABI
  PROVENANCE_CONTRACT: [
    {
      inputs: [
        {
          internalType: "address",
          name: "entityContractAddress",
          type: "address",
        },
      ],
      stateMutability: "nonpayable",
      type: "constructor",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "uint256",
          name: "diamondId",
          type: "uint256",
        },
        {
          indexed: true,
          internalType: "address",
          name: "certifier",
          type: "address",
        },
        {
          indexed: false,
          internalType: "string",
          name: "certificationId",
          type: "string",
        },
      ],
      name: "DiamondCertified",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "uint256",
          name: "rawDiamondId",
          type: "uint256",
        },
        {
          indexed: true,
          internalType: "uint256",
          name: "newDiamondId",
          type: "uint256",
        },
        {
          indexed: true,
          internalType: "address",
          name: "manufacturer",
          type: "address",
        },
      ],
      name: "DiamondProcessed",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "uint256",
          name: "diamondId",
          type: "uint256",
        },
        {
          indexed: true,
          internalType: "address",
          name: "miner",
          type: "address",
        },
        {
          indexed: false,
          internalType: "string",
          name: "origin",
          type: "string",
        },
        {
          indexed: false,
          internalType: "uint256",
          name: "weight",
          type: "uint256",
        },
      ],
      name: "DiamondRegistered",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        {
          indexed: true,
          internalType: "uint256",
          name: "diamondId",
          type: "uint256",
        },
        {
          indexed: true,
          internalType: "address",
          name: "from",
          type: "address",
        },
        {
          indexed: true,
          internalType: "address",
          name: "to",
          type: "address",
        },
        {
          indexed: false,
          internalType: "string",
          name: "transferType",
          type: "string",
        },
      ],
      name: "DiamondTransferred",
      type: "event",
    },
    // Add the rest of the provenance contract ABI here
  ],

  // Marketplace Contract ABI
  MARKETPLACE_CONTRACT: [
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "provenanceAddress",
				"type": "address"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "owner",
				"type": "address"
			}
		],
		"name": "OwnableInvalidOwner",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "account",
				"type": "address"
			}
		],
		"name": "OwnableUnauthorizedAccount",
		"type": "error"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "listingId",
				"type": "uint256"
			},
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "diamondId",
				"type": "uint256"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "seller",
				"type": "address"
			}
		],
		"name": "DiamondListed",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "diamondId",
				"type": "uint256"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "reporter",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "string",
				"name": "details",
				"type": "string"
			}
		],
		"name": "DiamondReportedStolen",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "listingId",
				"type": "uint256"
			},
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "diamondId",
				"type": "uint256"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "buyer",
				"type": "address"
			}
		],
		"name": "DiamondSold",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "listingId",
				"type": "uint256"
			},
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "diamondId",
				"type": "uint256"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "seller",
				"type": "address"
			}
		],
		"name": "ListingCancelled",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": false,
				"internalType": "string",
				"name": "message",
				"type": "string"
			},
			{
				"indexed": false,
				"internalType": "address",
				"name": "value",
				"type": "address"
			}
		],
		"name": "LogMessage",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "previousOwner",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "newOwner",
				"type": "address"
			}
		],
		"name": "OwnershipTransferred",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "diamondId",
				"type": "uint256"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "resolver",
				"type": "address"
			}
		],
		"name": "StolenReportResolved",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "listingId",
				"type": "uint256"
			}
		],
		"name": "cancelListing",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "listingId",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "buyer",
				"type": "address"
			}
		],
		"name": "directCompleteSale",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getActiveListings",
		"outputs": [
			{
				"internalType": "uint256[]",
				"name": "",
				"type": "uint256[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "diamondId",
				"type": "uint256"
			}
		],
		"name": "getDiamondDetails",
		"outputs": [
			{
				"internalType": "address",
				"name": "currentOwner",
				"type": "address"
			},
			{
				"internalType": "bool",
				"name": "isListed",
				"type": "bool"
			},
			{
				"internalType": "bool",
				"name": "isReportedStolen",
				"type": "bool"
			},
			{
				"internalType": "string",
				"name": "origin",
				"type": "string"
			},
			{
				"internalType": "uint256",
				"name": "weight",
				"type": "uint256"
			},
			{
				"internalType": "bool",
				"name": "isCertified",
				"type": "bool"
			},
			{
				"internalType": "string",
				"name": "certificationId",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "listingId",
				"type": "uint256"
			}
		],
		"name": "getListingDetails",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "diamondId",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "seller",
				"type": "address"
			},
			{
				"internalType": "bool",
				"name": "active",
				"type": "bool"
			},
			{
				"internalType": "uint256",
				"name": "listedAt",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "diamondId",
				"type": "uint256"
			}
		],
		"name": "getStolenReports",
		"outputs": [
			{
				"internalType": "address[]",
				"name": "reporters",
				"type": "address[]"
			},
			{
				"internalType": "uint256[]",
				"name": "reportTimes",
				"type": "uint256[]"
			},
			{
				"internalType": "string[]",
				"name": "details",
				"type": "string[]"
			},
			{
				"internalType": "bool[]",
				"name": "resolved",
				"type": "bool[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "diamondId",
				"type": "uint256"
			}
		],
		"name": "isDiamondStolen",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "diamondId",
				"type": "uint256"
			}
		],
		"name": "listDiamond",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "owner",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "renounceOwnership",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "diamondId",
				"type": "uint256"
			},
			{
				"internalType": "string",
				"name": "details",
				"type": "string"
			}
		],
		"name": "reportStolenDiamond",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "diamondId",
				"type": "uint256"
			}
		],
		"name": "resolveReport",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "newOwner",
				"type": "address"
			}
		],
		"name": "transferOwnership",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
],
};

// Helper function to get contract configuration
export function getContractConfig(contractType) {
  if (!CONTRACT_ADDRESSES[contractType] || !CONTRACT_ABIS[contractType]) {
    console.error(`Contract configuration for ${contractType} not found`);
    return null;
  }
  
  return {
    address: CONTRACT_ADDRESSES[contractType],
    abi: CONTRACT_ABIS[contractType]
  };
} 