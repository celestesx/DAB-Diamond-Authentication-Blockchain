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
///// -ALWAYS USE transferDiamond() OR transferToConsumer() FOR ALL TRANSFERS 

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
//transferToConsumer - use this and ONLY this to transfer diamond from retailer to consumer (non-registered entity)
//transferBetweenConsumers - use this and ONLY this to transfer diamond between consumers (non-registered entities)

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
contract Provenance is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    
    // Structs
    struct Diamond {
        string origin;
        uint256 extractionDate;
        uint256 weight;
        string characteristics;
        bool isCertified;
        string certificationID;
        uint256 rawDiamondID; // 0 for raw diamonds
    }
    
    // State variables
    Counters.Counter private _tokenIds;
    EntityContract private _entityContract;
    
    // Mappings
    mapping(uint256 => Diamond) private _diamonds;
    mapping(uint256 => string[]) private _diamondHistory;
    mapping(uint256 => uint256[]) private _processedDiamonds;
    mapping(uint256 => bool) private _inConsumerMarket;
    
    // Events
    event DiamondRegistered(uint256 indexed diamondId, address indexed miner, string origin, uint256 weight);
    event DiamondProcessed(uint256 indexed rawDiamondId, uint256 indexed newDiamondId, address indexed manufacturer);
    event DiamondCertified(uint256 indexed diamondId, string certificationId, address indexed certifier);
    event DiamondTransferred(uint256 indexed diamondId, address indexed from, address indexed to, string transferType);
    event HistoryRecordAdded(uint256 indexed diamondId, string record);
    
    // Constructor
    constructor(address entityContractAddress) 
        ERC721("DiamondNFT", "DNFT")
        Ownable(msg.sender)
    {
        _entityContract = EntityContract(entityContractAddress);
    }
    
    // ====== External/Public Functions ======
    
    /**
     * @dev Register a new raw diamond (miners only)
     */
    function registerRawDiamond(
        string calldata origin,
        uint256 extractionDate,
        uint256 weight,
        string calldata characteristics
    ) external returns (uint256) {
        // Check if caller is a miner
        require(_hasRole(msg.sender, "Miner"), "Only miners can register diamonds");
        
        // Get new diamond ID
        _tokenIds.increment();
        uint256 diamondId = _tokenIds.current();
        
        // Create diamond
        _diamonds[diamondId] = Diamond({
            origin: origin,
            extractionDate: extractionDate,
            weight: weight,
            characteristics: characteristics,
            isCertified: false,
            certificationID: "",
            rawDiamondID: 0 // Raw diamond
        });
        
        // Mint NFT
        _safeMint(msg.sender, diamondId);
        
        // Add history record
        _addHistoryRecord(
            diamondId, 
            "REGISTERED", 
            msg.sender, 
            string(abi.encodePacked("Origin: ", origin))
        );
        
        emit DiamondRegistered(diamondId, msg.sender, origin, weight);
        return diamondId;
    }
    
    /**
     * @dev Process a raw diamond into a cut/polished diamond (manufacturers only)
     */
    function processDiamond(
        uint256 rawDiamondId,
        uint256 weight,
        string calldata characteristics
    ) external returns (uint256) {
        // Validate
        require(_exists(rawDiamondId), "Raw diamond does not exist");
        require(ownerOf(rawDiamondId) == msg.sender, "You don't own this diamond");
        require(_hasRole(msg.sender, "Manufacturer"), "Only manufacturers can process diamonds");
        
        // Get new diamond ID
        _tokenIds.increment();
        uint256 newDiamondId = _tokenIds.current();
        
        // Create processed diamond
        _diamonds[newDiamondId] = Diamond({
            origin: _diamonds[rawDiamondId].origin,
            extractionDate: _diamonds[rawDiamondId].extractionDate,
            weight: weight,
            characteristics: characteristics,
            isCertified: false,
            certificationID: "",
            rawDiamondID: rawDiamondId
        });
        
        // Mint NFT
        _safeMint(msg.sender, newDiamondId);
        
        // Add history record
        _addHistoryRecord(
            newDiamondId, 
            "PROCESSED", 
            msg.sender, 
            string(abi.encodePacked("From raw diamond #", _uint256ToString(rawDiamondId)))
        );
        
        // Track processed diamonds
        _processedDiamonds[rawDiamondId].push(newDiamondId);
        
        emit DiamondProcessed(rawDiamondId, newDiamondId, msg.sender);
        return newDiamondId;
    }
    
    /**
     * @dev Certify a diamond (certifiers only)
     */
    function certifyDiamond(
        uint256 diamondId,
        string calldata certificationId
    ) external {
        // Validate
        require(_exists(diamondId), "Diamond does not exist");
        require(ownerOf(diamondId) == msg.sender, "You don't own this diamond");
        require(_hasRole(msg.sender, "Certifier"), "Only certifiers can certify diamonds");
        
        // Update diamond
        _diamonds[diamondId].isCertified = true;
        _diamonds[diamondId].certificationID = certificationId;
        
        // Add history record
        _addHistoryRecord(
            diamondId, 
            "CERTIFIED", 
            msg.sender, 
            string(abi.encodePacked("Certification ID: ", certificationId))
        );
        
        emit DiamondCertified(diamondId, certificationId, msg.sender);
    }
    
    /**
     * @dev Unified transfer function for all transfer types
     */
    function transferDiamond(uint256 diamondId, address to) external {
        // Validate basic conditions
        require(_exists(diamondId), "Diamond does not exist");
        require(ownerOf(diamondId) == msg.sender, "You don't own this diamond");
        require(to != address(0), "Cannot transfer to zero address");
        
        // Determine sender and receiver status
        (bool senderRegistered, string memory senderRole) = _getEntityInfo(msg.sender);
        (bool receiverRegistered, string memory receiverRole) = _getEntityInfo(to);
        
        string memory transferType;
        string memory details;
        
        // Handle different transfer scenarios
        if (senderRegistered && receiverRegistered) {
            // Entity to Entity transfer
            require(_entityContract.validateTransfer(msg.sender, to), "Invalid transfer between entities");
            transferType = "ENTITY_TO_ENTITY";
            details = string(abi.encodePacked(
                "From: ", senderRole, " to ", receiverRole
            ));
        }
        else if (senderRegistered && !receiverRegistered) {
            // Retailer to Consumer transfer
            require(
                keccak256(abi.encodePacked(senderRole)) == keccak256(abi.encodePacked("Retailer")), 
                "Only retailers can transfer to consumers"
            );
            transferType = "RETAIL_SALE";
            details = "First consumer sale";
            
            // Mark as in consumer market
            _inConsumerMarket[diamondId] = true;
        }
        else if (!senderRegistered && !receiverRegistered) {
            // Consumer to Consumer transfer
            require(_inConsumerMarket[diamondId], "This diamond has not entered the consumer market");
            transferType = "SECONDARY_SALE";
            details = "Consumer resale";
        }
        else {
            revert("Consumers cannot transfer back to registered entities");
        }
        
        // Add history record
        _addHistoryRecord(diamondId, transferType, msg.sender, details);
        
        // Transfer NFT
        safeTransferFrom(msg.sender, to, diamondId);
        
        emit DiamondTransferred(diamondId, msg.sender, to, transferType);
    }
    
    // ====== View Functions (Getters) ======
    
    /**
     * @dev Get basic diamond information
     */
    function getDiamondBasicInfo(uint256 diamondId) external view returns (
        string memory origin,
        uint256 extractionDate,
        uint256 weight,
        string memory characteristics
    ) {
        require(_exists(diamondId), "Diamond does not exist");
        
        Diamond storage diamond = _diamonds[diamondId];
        return (
            diamond.origin,
            diamond.extractionDate,
            diamond.weight,
            diamond.characteristics
        );
    }
    
    /**
     * @dev Get diamond certification information
     */
    function getDiamondCertInfo(uint256 diamondId) external view returns (
        bool isCertified,
        string memory certificationId,
        uint256 rawDiamondId
    ) {
        require(_exists(diamondId), "Diamond does not exist");
        
        Diamond storage diamond = _diamonds[diamondId];
        return (
            diamond.isCertified,
            diamond.certificationID,
            diamond.rawDiamondID
        );
    }
    
    /**
     * @dev Get diamond ownership information
     */
    function getDiamondOwnershipInfo(uint256 diamondId) external view returns (
        address currentOwner
    ) {
        require(_exists(diamondId), "Diamond does not exist");
        
        return (
            ownerOf(diamondId)
        );
    }
    
    /**
     * @dev Get diamond history
     */
    function getDiamondHistory(uint256 diamondId) external view returns (string[] memory) {
        require(_exists(diamondId), "Diamond does not exist");
        return _diamondHistory[diamondId];
    }
    
    /**
     * @dev Get processed diamonds from a raw diamond
     */
    function getProcessedDiamonds(uint256 rawDiamondId) external view returns (uint256[] memory) {
        require(_exists(rawDiamondId), "Diamond does not exist");
        return _processedDiamonds[rawDiamondId];
    }
    
    /**
     * @dev Check if an address has a specific role
     */
    function hasRole(address account, string calldata role) external view returns (bool) {
        return _hasRole(account, role);
    }
    
   
    // ====== Internal Helper Functions ======
    
    /**
     * @dev Check if an address has a specific role
     */
    function _hasRole(address account, string memory role) internal view returns (bool) {
        (bool registered, string memory entityRole) = _getEntityInfo(account);
        return registered && keccak256(abi.encodePacked(entityRole)) == keccak256(abi.encodePacked(role));
    }
    
    /**
     * @dev Get entity information
     */
    function _getEntityInfo(address account) internal view returns (bool registered, string memory role) {
        (,, registered,, role) = _entityContract.getEntityInfo(account);
        return (registered, role);
    }
    
    /**
     * @dev Add a history record for a diamond
     */
    function _addHistoryRecord(
        uint256 diamondId, 
        string memory action, 
        address actor, 
        string memory details
    ) internal {
        string memory timestamp = _uint256ToString(block.timestamp);
        string memory record = string(abi.encodePacked(
            timestamp, " | ", 
            action, " | ", 
            _addressToString(actor), " | ", 
            details
        ));
        
        _diamondHistory[diamondId].push(record);
        emit HistoryRecordAdded(diamondId, record);
    }
    
    /**
     * @dev Convert address to string
     */
    function _addressToString(address addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr)));
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
    
    /**
     * @dev Convert uint256 to string
     */
    function _uint256ToString(uint256 value) internal pure returns (string memory) {
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
    
    /**
     * @dev Check if a token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId > 0 && tokenId <= _tokenIds.current();
    }
}
   
//to implement
// DONE 1. registerRawDiamond - for miners to register new diamonds
// 2. transferDiamond - transfer diamond between stakeholders
// 3. processDiamond - manufacturers process raw diamonds into new ones
// 4. certifyDiamond - certifiers add certification details
// 5. getDiamondHistory - get complete history of a diamond
