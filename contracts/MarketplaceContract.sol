// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EntityContract.sol";
import "./ProvenanceContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketplaceContract is Ownable{
    EntityContract private entityContract;
    ProvenanceContract private provenanceContract;

    enum DiamondStatus {Available, Sold, Stolen, Lost}

    struct DiamondListing {
        uint256 diamondID;
        address seller;
        bool isListed;
        DiamondStatus status;
    }

    struct OwnershipRecord {
        address owner;
        uint256 purchaseDate;
        string purchaseDetails;
    }

    struct TheftReport {
        uint256 reportDate;
        address reportedBy;
        string reportDetails;
        bool isResolved;
    }

    struct DiamondDetails {
        uint256 id;
        address currentOwner;
        string origin;
        uint256 extractionDate;
        uint256 weight;
        string characteristics;
        string certificationID;
        uint256 rawDiamondID;
        DiamondStatus marketStatus;
    }

    ////////////mappings
    mapping(uint256 => DiamondListing) private diamondListings;
    mapping(uint256 => OwnershipRecord) private consumerOwnership;
    mapping(uint256 => TheftReport[]) private theftReports;
    ////////////

    ///////////events
    event DiamondListed(uint256 indexed diamondID, address indexed seller);
    event DiamondSold(uint256 indexed diamondID, address indexed seller, address indexed buyer);
    event DiamondStatusUpdated(uint256 indexed diamondID, DiamondStatus status);
    event DiamondTransferred(uint256 indexed diamondId, address indexed from, address indexed to, uint256 date);
    event DiamondTheftReported(uint256 indexed diamondId, address indexed reportedBy, uint256 reportDate);
    event DiamondLostReported(uint256 indexed diamondId, address indexed reportedBy, uint256 reportDate);
    event DiamondFoundReported(uint256 indexed diamondId, address indexed reportedBy, uint256 reportDate);
    ///////////

    //constructor
    constructor(address _entityContractAddress, address _provenanceContractAddress) 
        Ownable(msg.sender) 
    {
        entityContract = EntityContract(_entityContractAddress);
        provenanceContract = ProvenanceContract(_provenanceContractAddress);
    }

    //function for retailers to sell directly to consumers without listing
    function sellToConsumer(uint256 _diamondID, address _buyer, string memory _purchaseDetails) external {
        // Check if the caller is the diamond owner in the provenance contract
        (uint256 id, address currentOwner, , , , , , ) = provenanceContract.getDiamondInfo(_diamondID);
        require(currentOwner == msg.sender, "Only the diamond owner can sell it");
        
        // Check if the caller is a registered retailer
        (,,bool isRegistered,,string memory role) = entityContract.getEntityInfo(msg.sender);
        require(isRegistered, "Seller is not a registered entity");
        require(keccak256(abi.encodePacked(role)) == keccak256(abi.encodePacked("Retailer")), 
            "Only retailers can complete initial sales to consumers");
        
        // Check that buyer is not a registered entity
        (,,bool isBuyerRegistered,,) = entityContract.getEntityInfo(_buyer);
        require(!isBuyerRegistered, "Buyer cannot be a registered entity");
        
        // Update or create listing status directly (no need to list first)
        diamondListings[_diamondID] = DiamondListing({
            diamondID: _diamondID,
            seller: msg.sender,
            isListed: false, // Not needed since we're selling directly
            status: DiamondStatus.Sold
        });
        
        // Create ownership record for the consumer
        consumerOwnership[_diamondID] = OwnershipRecord({
            owner: _buyer,
            purchaseDate: block.timestamp,
            purchaseDetails: _purchaseDetails
        });
        
        // Transfer ownership in the provenance contract using the special consumer transfer
        provenanceContract.transferToConsumer(_diamondID, _buyer);
        
        emit DiamondSold(_diamondID, msg.sender, _buyer);
        emit DiamondStatusUpdated(_diamondID, DiamondStatus.Sold);
    }
    
    ////function to transfer diamond from consumer to consumer
    function transferConsumerDiamond(uint256 _diamondID, address _newOwner, string memory _transferDetails) external {
        // Check if the caller is the current consumer owner
        require(consumerOwnership[_diamondID].owner == msg.sender, "Only the current owner can transfer");
        
        // Check if the diamond is actually owned by the caller in the provenance contract
        (,address currentProvenanceOwner,,,,,, ) = provenanceContract.getDiamondInfo(_diamondID);
        require(currentProvenanceOwner == msg.sender, "Caller does not own this diamond in the provenance contract");
        
        // Check that new owner is not a registered entity
        (,,bool isNewOwnerRegistered,,) = entityContract.getEntityInfo(_newOwner);
        require(!isNewOwnerRegistered, "New owner cannot be a registered entity");
        
        // Check if diamond is not reported stolen or lost
        require(diamondListings[_diamondID].status != DiamondStatus.Stolen, "Cannot transfer a stolen diamond");
        require(diamondListings[_diamondID].status != DiamondStatus.Lost, "Cannot transfer a lost diamond");
        
        // Update consumer ownership record
        consumerOwnership[_diamondID] = OwnershipRecord({
            owner: _newOwner,
            purchaseDate: block.timestamp,
            purchaseDetails: _transferDetails
        });
        
        // Transfer the diamond in the provenance contract using the consumer-to-consumer transfer
        provenanceContract.transferBetweenConsumers(_diamondID, _newOwner);
        
        // Make sure the status stays as Sold
        diamondListings[_diamondID].status = DiamondStatus.Sold;
        
        emit DiamondTransferred(_diamondID, msg.sender, _newOwner, block.timestamp);
    }

    //function to report stolen diamond
    function reportStolen(uint256 _diamondID, string memory _reportDetails) external {
        //check if the caller is the registered owner
        require(consumerOwnership[_diamondID].owner == msg.sender, "Only the registered owner can report theft");
        
        // Check if the diamond is actually owned by the caller in the provenance contract
        (,address currentProvenanceOwner,,,,,, ) = provenanceContract.getDiamondInfo(_diamondID);
        require(currentProvenanceOwner == msg.sender, "Caller does not own this diamond in the provenance contract");
        
        diamondListings[_diamondID].status = DiamondStatus.Stolen;
        
        //create the theft report
        theftReports[_diamondID].push(TheftReport({
            reportDate: block.timestamp,
            reportedBy: msg.sender,
            reportDetails: _reportDetails,
            isResolved: false
        }));
        
        emit DiamondTheftReported(_diamondID, msg.sender, block.timestamp);
        emit DiamondStatusUpdated(_diamondID, DiamondStatus.Stolen);
    }
    
    //function to report a lost diamond
    function reportLost(uint256 _diamondId) external {
        //check if the caller is the registered owner
        require(consumerOwnership[_diamondId].owner == msg.sender, "Only the registered owner can report loss");
        
        // Check if the diamond is actually owned by the caller in the provenance contract
        (,address currentProvenanceOwner,,,,,, ) = provenanceContract.getDiamondInfo(_diamondId);
        require(currentProvenanceOwner == msg.sender, "Caller does not own this diamond in the provenance contract");
        
        diamondListings[_diamondId].status = DiamondStatus.Lost;
        
        emit DiamondLostReported(_diamondId, msg.sender, block.timestamp);
        emit DiamondStatusUpdated(_diamondId, DiamondStatus.Lost);
    }
    
    //function to report a found diamond that was previously lost
    function reportFound(uint256 _diamondId) external {
        //check if the caller is the registered owner
        require(consumerOwnership[_diamondId].owner == msg.sender, "Only the registered owner can report found");
        
        // Check if the diamond is actually owned by the caller in the provenance contract
        (,address currentProvenanceOwner,,,,,, ) = provenanceContract.getDiamondInfo(_diamondId);
        require(currentProvenanceOwner == msg.sender, "Caller does not own this diamond in the provenance contract");
        
        // Check that the diamond was previously reported as lost
        require(diamondListings[_diamondId].status == DiamondStatus.Lost, "Diamond was not reported as lost");
        
        // Update the status back to Sold
        diamondListings[_diamondId].status = DiamondStatus.Sold;
        
        emit DiamondFoundReported(_diamondId, msg.sender, block.timestamp);
        emit DiamondStatusUpdated(_diamondId, DiamondStatus.Sold);
    }
    
    //function to resolve a report
    function resolveTheftReport(uint256 _diamondId, uint256 _reportIndex) external onlyOwner {
        require(_reportIndex < theftReports[_diamondId].length, "Invalid report index");
        
        theftReports[_diamondId][_reportIndex].isResolved = true;
        
        //if this was the most recent report and it's resolved then reset the status
        if (_reportIndex == theftReports[_diamondId].length - 1) {
            diamondListings[_diamondId].status = DiamondStatus.Sold; // Set to Sold rather than Available
            emit DiamondStatusUpdated(_diamondId, DiamondStatus.Sold);
        }
    }

    //function to get theft report
    function getTheftReport(uint256 _diamondId, uint256 _reportIndex) external view returns (
        uint256 reportDate,
        address reportedBy,
        string memory reportDetails,
        bool isResolved
    ) {
        require(_reportIndex < theftReports[_diamondId].length, "Invalid report index");
        
        TheftReport storage report = theftReports[_diamondId][_reportIndex];
        return (report.reportDate, report.reportedBy, report.reportDetails, report.isResolved);
    }

    //function to get diamond status
    function getDiamondStatus(uint256 _diamondId) external view returns (DiamondStatus) {
        return diamondListings[_diamondId].status;
    }

    //function to get current owner
    function getConsumerOwnership(uint256 _diamondId) external view returns (
        address owner,
        uint256 purchaseDate,
        string memory purchaseDetails
    ) {
        OwnershipRecord storage record = consumerOwnership[_diamondId];
        return (record.owner, record.purchaseDate, record.purchaseDetails);
    }

    //function to get the diamond details
    function getDiamondDetails(uint256 _diamondId) external view returns (DiamondDetails memory details) {
        // Get basic diamond info from provenance contract
        (
            details.id, 
            details.currentOwner, 
            details.origin, 
            details.extractionDate, 
            details.weight, 
            details.characteristics, 
            details.certificationID, 
            details.rawDiamondID
        ) = provenanceContract.getDiamondInfo(_diamondId);
        
        // Add marketplace status
        details.marketStatus = diamondListings[_diamondId].status;
        
        return details;
    }

    //function to verify consumer ownership matches provenance contract
    function verifyOwnership(uint256 _diamondId) external view returns (bool) {
        (,address provenanceOwner,,,,,, ) = provenanceContract.getDiamondInfo(_diamondId);
        return consumerOwnership[_diamondId].owner == provenanceOwner;
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

    function statusToString(DiamondStatus _status) internal pure returns (string memory) {
        if (_status == DiamondStatus.Available) return "Available";
        if (_status == DiamondStatus.Sold) return "Sold";
        if (_status == DiamondStatus.Stolen) return "Reported Stolen";
        if (_status == DiamondStatus.Lost) return "Reported Lost";
        return "Unknown";
    }
}

//TO IMPLEMENT
//DONE listDiamond
//DONE sellToConsumer
//DONE transferConsumerDiamond
//DONE reportStolen
//DONE reportLost
//DONE resolveTheftReport
//DONE getDiamondStatus
//DONE getConsumerOwnership
//DONE getDiamondDetails
//