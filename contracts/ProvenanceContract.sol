// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EntityContract.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ProvenanceContract is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIDs;

    EntityContract private entityContract;

    //diamond struct to track provenance
    struct Diamond {
        uint256 id; //same as the token ID
        string origin;
        uint256 extractionDate;
        //weight is in carats
        uint256 weight; 
        string characteristics;
        bool isCertified;
        string certificationID;
        string[] processingHistory;
        //this is for the original raw diamond (0 if this is a raw diamond)
        uint256 rawDiamondID; 
    }

    mapping(uint256 => Diamond) public diamonds;

    //raw diamond ID -> processed diamond IDs
    mapping(uint256 => uint256[]) private processedDiamonds; 

    event DiamondRegistered(uint256 diamondID, address indexed miner, string origin, uint256 weight);


    constructor(address _entityContractAddress) ERC721("DiamondNFT", "DNFT") {
        entityContract = EntityContract(_entityContractAddress);
    }

    //function to register a raw diamond (only can be completed by registered miners)
    function registerRawDiamond(
        string memory _origin,
        uint256 _extractionDate,
        uint256 _weight,
        string memory _characteristics
    ) external returns (uint256) {
        //verify the caller is a miner
        (,,bool isRegistered,,string memory role) = entityContract.getEntityInfo(msg.sender);
        require(isRegistered, "Caller is not a registered entity");
        require(keccak256(abi.encodePacked(role)) == keccak256(abi.encodePacked("Miner")),
            "Only miners can register new diamonds");
        
        //increment and get a new token id
        _tokenIDs.increment();
        uint256 diamondID = _tokenIDs.current();
        
        //create empty array for processing history
        string[] memory processingHistory = new string[](0);
        
        //store the diamond information
        diamonds[diamondID] = Diamond({
            id: diamondID,
            origin: _origin,
            extractionDate: _extractionDate,
            weight: _weight,
            characteristics: _characteristics,
            isCertified: false,
            certificationID: "",
            processingHistory: processingHistory,
            rawDiamondID: 0 //0 because this is a raw diamond
        });
        
        //mint the nft to the miner
        _safeMint(msg.sender, diamondID);
        
        //add first processing record
        addProcessingRecord(diamondID, string(abi.encodePacked(
            "Registered as raw diamond by miner ", addressToString(msg.sender),
            " from ", _origin
        )));
        
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