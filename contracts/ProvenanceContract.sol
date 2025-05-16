// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EntityContract.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//WARNING: DO NOT USE THE STATED BELOW
//1)safeTransferFrom
//2)transferFrom
//3)approve
//4)setApprovalForAll
///// -ALWAYS USE transferDiamond() FOR ALL TRANSFERS 

/////////////////
//Miners
////////////////
//registerRawDiamond - use this to register newly mined diamonds with their origin and extraction details

////////////////
//Manufacturers
///////////////
//processDiamond - use this to process raw diamonds into cut/polished diamonds

///////////////
//Certifiers
//////////////
//certifyDiamond - use this to add certification details to a diamond

//////////////
//All stakeholders
//////////////
//!!!!!!!IMPORTANT!!!!!!!
//transferDiamond - use this and ONLY this to transfer diamond between registered entities in the supply chain

//////////////
//For tracking and verification purposes
//////////////
//1)getDiamondInfo - use this to get complete details about a diamond
//2)getDiamondHistory - use this to view the complete processing and ownership history


/////////////
//Admin
/////////////
//addProcessingRecord - use this to manually add processing records if needed



//nft reference: https://docs.openzeppelin.com/contracts/3.x/erc721
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
    event DiamondProcessed(uint256 rawDiamondID, uint256 newDiamondID, address indexed manufacturer);
    event DiamondCertified(uint256 diamondID, string certificationID, address indexed certifier);
    event ProcessingRecordAdded(uint256 diamondID, string processingDetail);

    constructor(address _entityContractAddress) 
        ERC721("DiamondNFT", "DNFT") 
        Ownable(msg.sender) //pass the deployer's address as the initial owner to Ownable
    {
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

    function transferDiamond(uint256 _diamondID, address _to) external {
        //use ERC721Enumerable to check if token exists
        require(_diamondID <= _tokenIDs.current() && _diamondID > 0, "Diamond does not exist");
        require(ownerOf(_diamondID) == msg.sender, "Only the current owner can transfer");

        //validate the transfer using entity contract
        bool isValidTransfer = entityContract.isValidTransfer(msg.sender, _to);
        require(isValidTransfer, "Invalid transfer between entities");

        //add processing record to track the transfer
        addProcessingRecord(_diamondID, string(abi.encodePacked(
            "Transferred from ", addressToString(msg.sender), 
            " to ", addressToString(_to)
        )));

        //transfer the NFT
        safeTransferFrom(msg.sender, _to, _diamondID);
    }

    function processDiamond(
        uint256 _rawDiamondID,
        uint256 _weight,
        string memory _characteristics
    ) external returns (uint256) {
        //use ERC721Enumerable to check if token exists
        require(_rawDiamondID <= _tokenIDs.current() && _rawDiamondID > 0, "Raw diamond does not exist");
        require(ownerOf(_rawDiamondID) == msg.sender, "Only the current owner can process");
        
        // Verify caller is a registered manufacturer
        (,,bool isRegistered,,string memory role) = entityContract.getEntityInfo(msg.sender);
        require(isRegistered, "Caller is not a registered entity");
        require(keccak256(abi.encodePacked(role)) == keccak256(abi.encodePacked("Manufacturer")), 
            "Only manufacturers can process diamonds");
        
        // Increment and get the new token ID
        _tokenIDs.increment();
        uint256 newDiamondID = _tokenIDs.current();
        
        // Create empty array for processing history
        string[] memory processingHistory = new string[](0);
        
        // Store the processed diamond information
        diamonds[newDiamondID] = Diamond({
            id: newDiamondID,
            origin: diamonds[_rawDiamondID].origin, // Inherit origin from raw diamond
            extractionDate: diamonds[_rawDiamondID].extractionDate, // Inherit extraction date
            weight: _weight,
            characteristics: _characteristics,
            isCertified: false,
            certificationID: "",
            processingHistory: processingHistory,
            rawDiamondID: _rawDiamondID // Link to original raw diamond
        });
        
        // Mint the NFT to the manufacturer
        _safeMint(msg.sender, newDiamondID);
        
        // Add processing record
        addProcessingRecord(newDiamondID, string(abi.encodePacked(
            "Processed from raw diamond #", uint256ToString(_rawDiamondID),
            " by manufacturer ", addressToString(msg.sender)
        )));
        
        // Track processed diamonds from the raw diamond
        processedDiamonds[_rawDiamondID].push(newDiamondID);
        
        emit DiamondProcessed(_rawDiamondID, newDiamondID, msg.sender);
        
        return newDiamondID;
    }

    //function to certify diamond (only certifiers can call this)
    function certifyDiamond(
        uint256 _diamondID,
        string memory _certificationID,
        string memory _characteristics
    ) external {
        //use ERC721Enumerable to check if token exists
        require(_diamondID <= _tokenIDs.current() && _diamondID > 0, "Diamond does not exist");
        require(ownerOf(_diamondID) == msg.sender, "Only the current owner can certify");
        
        // Verify caller is a registered certifier
        (,,bool isRegistered,,string memory role) = entityContract.getEntityInfo(msg.sender);
        require(isRegistered, "Caller is not a registered entity");
        require(keccak256(abi.encodePacked(role)) == keccak256(abi.encodePacked("Certifier")), 
            "Only certifiers can certify diamonds");
        
        // Update diamond certification
        diamonds[_diamondID].isCertified = true;
        diamonds[_diamondID].certificationID = _certificationID;
        diamonds[_diamondID].characteristics = _characteristics; // Update with certified characteristics
        
        // Add certification record
        addProcessingRecord(_diamondID, string(abi.encodePacked(
            "Certified with ID ", _certificationID,
            " by certifier ", addressToString(msg.sender)
        )));
        
        emit DiamondCertified(_diamondID, _certificationID, msg.sender);
    }

    function addProcessingRecord(uint256 _diamondID, string memory _processingDetail) public {
        //use ERC721Enumerable to check if token exists
        require(_diamondID <= _tokenIDs.current() && _diamondID > 0, "Diamond does not exist");
        require(ownerOf(_diamondID) == msg.sender, "Only the current owner can add records");
        
        // Add the processing record with timestamp
        string memory recordWithTimestamp = string(abi.encodePacked(
            uint256ToString(block.timestamp),
            ": ",
            _processingDetail
        ));
        
        diamonds[_diamondID].processingHistory.push(recordWithTimestamp);
        
        emit ProcessingRecordAdded(_diamondID, _processingDetail);
    }

    //function to get all diamond information
    function getDiamondInfo(uint256 _diamondID) external view returns (
        uint256 id,
        address currentOwner,
        string memory origin,
        uint256 extractionDate,
        uint256 weight,
        string memory characteristics,
        string memory certificationID,
        uint256 rawDiamondID
    ) {
        //use ERC721Enumerable to check if token exists
        require(_diamondID <= _tokenIDs.current() && _diamondID > 0, "Diamond does not exist");
        
        Diamond storage diamond = diamonds[_diamondID];
        address owner = ownerOf(_diamondID);
        
        return (
            diamond.id,
            owner,
            diamond.origin,
            diamond.extractionDate,
            diamond.weight,
            diamond.characteristics,
            diamond.certificationID,
            diamond.rawDiamondID
        );
    }

    //function to get all history of diamond, processing etc
    function getDiamondHistory(uint256 _diamondID) external view returns (string[] memory) {
        //use ERC721Enumerable to check if token exists
        require(_diamondID <= _tokenIDs.current() && _diamondID > 0, "Diamond does not exist");
        return diamonds[_diamondID].processingHistory;
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        // Fix: Use ERC721Enumerable's method for checking if token exists
        require(tokenID <= _tokenIDs.current() && tokenID > 0, "ERC721Metadata: URI query for nonexistent token");
        
        // This can be extended to return detailed JSON metadata or link to IPFS
        return string(abi.encodePacked("https://diamond-provenance.example/token/", uint256ToString(tokenID)));
    }

    function addressToString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        
        return string(str);
    }

    function uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        
        uint256 temp = value;
        uint256 digits;
        
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }


    
    //to implement
    // DONE 1. registerRawDiamond - for miners to register new diamonds
    // 2. transferDiamond - transfer diamond between stakeholders
    // 3. processDiamond - manufacturers process raw diamonds into new ones
    // 4. certifyDiamond - certifiers add certification details
    // 5. getDiamondHistory - get complete history of a diamond
}