// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EntityContract.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

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
    
    // State variables & mappings
    Counters.Counter private _tokenIds;
    EntityContract private _entityContract;
    mapping(uint256 => Diamond) private _diamonds;
    mapping(uint256 => string[]) private _diamondHistory;
    mapping(uint256 => uint256[]) private _processedDiamonds;
    mapping(uint256 => bool) private _inConsumerMarket;
    mapping(address => bool) private _authorizedMarketplaces;
    
    // Events
    event DiamondRegistered(uint256 indexed diamondId, address indexed miner, string origin, uint256 weight);
    event DiamondProcessed(uint256 indexed rawDiamondId, uint256 indexed newDiamondId, address indexed manufacturer);
    event DiamondCertified(uint256 indexed diamondId, string certificationId, address indexed certifier);
    event DiamondTransferred(uint256 indexed diamondId, address indexed from, address indexed to, string transferType);
    event HistoryRecordAdded(uint256 indexed diamondId, string record);
    event LogMessage(string message, address value);
    
    constructor(address entityContractAddress) 
        ERC721("DiamondNFT", "DNFT")
        Ownable(msg.sender)
    {
        _entityContract = EntityContract(entityContractAddress);
    }
    
    // ====== External Functions ======
    
    function registerRawDiamond(
        string calldata origin,
        uint256 extractionDate,
        uint256 weight,
        string calldata characteristics
    ) external returns (uint256) {
        require(_hasRole(msg.sender, "Miner"), "Only miners can register diamonds");
        
        _tokenIds.increment();
        uint256 diamondId = _tokenIds.current();
        
        _diamonds[diamondId] = Diamond({
            origin: origin,
            extractionDate: extractionDate,
            weight: weight,
            characteristics: characteristics,
            isCertified: false,
            certificationID: "",
            rawDiamondID: 0
        });
        
        _safeMint(msg.sender, diamondId);
        _addHistoryRecord(diamondId, "REGISTERED", msg.sender, string(abi.encodePacked("Origin: ", origin)));
        emit DiamondRegistered(diamondId, msg.sender, origin, weight);
        
        return diamondId;
    }
    
    function processDiamond(
        uint256 rawDiamondId,
        uint256 weight,
        string calldata characteristics
    ) external returns (uint256) {
        require(_exists(rawDiamondId), "Raw diamond does not exist");
        require(ownerOf(rawDiamondId) == msg.sender, "You don't own this diamond");
        require(_hasRole(msg.sender, "Manufacturer"), "Only manufacturers can process diamonds");
        
        _tokenIds.increment();
        uint256 newDiamondId = _tokenIds.current();
        
        _diamonds[newDiamondId] = Diamond({
            origin: _diamonds[rawDiamondId].origin,
            extractionDate: _diamonds[rawDiamondId].extractionDate,
            weight: weight,
            characteristics: characteristics,
            isCertified: false,
            certificationID: "",
            rawDiamondID: rawDiamondId
        });
        
        _safeMint(msg.sender, newDiamondId);
        _addHistoryRecord(newDiamondId, "PROCESSED", msg.sender, 
            string(abi.encodePacked("From raw diamond #", _uint256ToString(rawDiamondId))));
        
        _processedDiamonds[rawDiamondId].push(newDiamondId);
        emit DiamondProcessed(rawDiamondId, newDiamondId, msg.sender);
        
        return newDiamondId;
    }
    
    function certifyDiamond(uint256 diamondId, string calldata certificationId) external {
        require(_exists(diamondId), "Diamond does not exist");
        require(ownerOf(diamondId) == msg.sender, "You don't own this diamond");
        require(_hasRole(msg.sender, "Certifier"), "Only certifiers can certify diamonds");
        
        _diamonds[diamondId].isCertified = true;
        _diamonds[diamondId].certificationID = certificationId;
        
        _addHistoryRecord(diamondId, "CERTIFIED", msg.sender, 
            string(abi.encodePacked("Certification ID: ", certificationId)));
        
        emit DiamondCertified(diamondId, certificationId, msg.sender);
    }
    
    function setMarketplaceAuthorization(address marketplace, bool authorized) external onlyOwner {
        _authorizedMarketplaces[marketplace] = authorized;
    }

    function marketplaceTransferDiamond(uint256 diamondId, address from, address to) external {
        require(_authorizedMarketplaces[msg.sender], "Not an authorized marketplace");
        require(_exists(diamondId), "Diamond does not exist");
        require(ownerOf(diamondId) == from, "Seller doesn't own this diamond");
        require(to != address(0), "Cannot transfer to zero address");
        
        (bool senderRegistered, string memory senderRole) = _getEntityInfo(from);
        (bool receiverRegistered, string memory receiverRole) = _getEntityInfo(to);
        
        (string memory transferType, string memory details) = _determineTransferType(
            diamondId, senderRegistered, receiverRegistered, senderRole, receiverRole, from, to
        );
        
        _addHistoryRecord(diamondId, transferType, from, 
            string(abi.encodePacked("Via marketplace: ", _addressToString(msg.sender), " | ", details)));
        
        _transfer(from, to, diamondId);
        emit DiamondTransferred(diamondId, from, to, transferType);
    }

    function transferDiamond(uint256 diamondId, address to) external {
        require(_exists(diamondId), "Diamond does not exist");
        require(ownerOf(diamondId) == msg.sender, "You don't own this diamond");
        emit LogMessage("Diamond owner", ownerOf(diamondId));
        require(to != address(0), "Cannot transfer to zero address");
        
        (bool senderRegistered, string memory senderRole) = _getEntityInfo(msg.sender);
        (bool receiverRegistered, string memory receiverRole) = _getEntityInfo(to);
        
        (string memory transferType, string memory details) = _determineTransferType(
            diamondId, senderRegistered, receiverRegistered, senderRole, receiverRole, msg.sender, to
        );
        
        _addHistoryRecord(diamondId, transferType, msg.sender, details);
        safeTransferFrom(msg.sender, to, diamondId);
        
        emit DiamondTransferred(diamondId, msg.sender, to, transferType);
    }
    
    // ====== View Functions ======
    
    function getDiamondBasicInfo(uint256 diamondId) external view returns (
        string memory origin, uint256 extractionDate, uint256 weight, string memory characteristics
    ) {
        require(_exists(diamondId), "Diamond does not exist");
        Diamond storage diamond = _diamonds[diamondId];
        return (diamond.origin, diamond.extractionDate, diamond.weight, diamond.characteristics);
    }
    
    function getDiamondCertInfo(uint256 diamondId) external view returns (
        bool isCertified, string memory certificationId, uint256 rawDiamondId
    ) {
        require(_exists(diamondId), "Diamond does not exist");
        Diamond storage diamond = _diamonds[diamondId];
        return (diamond.isCertified, diamond.certificationID, diamond.rawDiamondID);
    }
    
    function getDiamondOwnershipInfo(uint256 diamondId) external view returns (address) {
        require(_exists(diamondId), "Diamond does not exist");
        return ownerOf(diamondId);
    }
    
    function getDiamondHistory(uint256 diamondId) external view returns (string[] memory) {
        require(_exists(diamondId), "Diamond does not exist");
        return _diamondHistory[diamondId];
    }
        
    // ====== Internal Helper Functions ======
    
    function _determineTransferType(
        uint256 diamondId, 
        bool senderRegistered, 
        bool receiverRegistered, 
        string memory senderRole, 
        string memory receiverRole,
        address from,
        address to
    ) internal returns (string memory transferType, string memory details) {
        if (senderRegistered && receiverRegistered) {
            // Entity to Entity transfer
            require(_entityContract.validateTransfer(from, to), "Invalid transfer between entities");
            transferType = "ENTITY_TO_ENTITY";
            details = string(abi.encodePacked("From: ", senderRole, " to ", receiverRole));
        }
        else if (senderRegistered && !receiverRegistered) {
            // Retailer to Consumer transfer
            require(
                keccak256(abi.encodePacked(senderRole)) == keccak256(abi.encodePacked("Retailer")), 
                "Only retailers can transfer to consumers"
            );
            transferType = "RETAIL_SALE";
            details = "First consumer sale";
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
        
        return (transferType, details);
    }
    
    function _hasRole(address account, string memory role) internal view returns (bool) {
        (bool registered, string memory entityRole) = _getEntityInfo(account);
        return registered && keccak256(abi.encodePacked(entityRole)) == keccak256(abi.encodePacked(role));
    }
    
    function _getEntityInfo(address account) internal view returns (bool registered, string memory role) {
        (,, registered,, role) = _entityContract.getEntityInfo(account);
        return (registered, role);
    }
    
    function _addHistoryRecord(
        uint256 diamondId, string memory action, address actor, string memory details
    ) internal {
        string memory timestamp = _uint256ToString(block.timestamp);
        string memory record = string(abi.encodePacked(
            timestamp, " | ", action, " | ", _addressToString(actor), " | ", details
        ));
        
        _diamondHistory[diamondId].push(record);
        emit HistoryRecordAdded(diamondId, record);
    }
    
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
    
    function _uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        
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
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId > 0 && tokenId <= _tokenIds.current();
    }
}