// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EntityContract.sol";

contract ProvenanceContract {
    EntityContract private entityContract;

    //diamond struct to track provenance
    struct Diamond {
        uint256 id;
        address currentOwner;
        string origin;
        uint256 extractionDate;
        //weight in carats (1 carat = 0.2grams)
        uint256 weight;
        string characteristics;
        bool isCertified;
        string certificationID;
        string[] processingHistory;
        //this is for the original raw diamond - 0 if this is the raw diamond
        uint256 rawDiamondID; 
    }

    mapping(uint256 => Diamond) public diamonds;
    uint256 private nextDiamondID = 1;
    mapping(address => uint256[]) private diamondsByOwner;
    //raw diamond ID -> processed diamond IDs
    mapping(uint256 => uint256[]) private processedDiamonds; 

    event DiamondRegistered(uint256 diamondID, address indexed miner, string origin, uint256 weight);


    constructor(address _entityContractAddress) {
        entityContract = EntityContract(_entityContractAddress);
    }

    function registerRawDiamond(
        string memory _origin,
        uint256 _extractionDate,
        uint256 _weight,
        string memory _characteristics
    ) external returns (uint256) {
        // Verify caller is a registered miner
        (,,bool isRegistered,,string memory role) = entityContract.getEntityInfo(msg.sender);
        require(isRegistered, "Caller is not a registered entity");
        require(keccak256(abi.encodePacked(role)) == keccak256(abi.encodePacked("Miner")),
            "Only miners can register new diamonds");
        
        // Create new diamond record
        uint256 diamondID = nextDiamondID++;
        
        // Create empty array for processing history
        string[] memory processingHistory = new string[](0);
        
        // Store the diamond information
        diamonds[diamondID] = Diamond({
            id: diamondID,
            currentOwner: msg.sender,
            origin: _origin,
            extractionDate: _extractionDate,
            weight: _weight,
            characteristics: _characteristics,
            isCertified: false,
            certificationID: "",
            processingHistory: processingHistory,
            rawDiamondID: 0 // 0 indicates this is a raw diamond
        });
        
        // Add diamond to owner's collection
        diamondsByOwner[msg.sender].push(diamondID);
        
        emit DiamondRegistered(diamondID, msg.sender, _origin, _weight);
        
        return diamondID;
    }

    //to implement
    // DONE 1. registerRawDiamond - for miners to register new diamonds
    // 2. transferDiamond - transfer diamond between stakeholders
    // 3. processDiamond - manufacturers process raw diamonds into new ones
    // 4. certifyDiamond - certifiers add certification details
    // 5. getDiamondHistory - get complete history of a diamond
}