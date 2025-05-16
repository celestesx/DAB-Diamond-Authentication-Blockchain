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

    ////////////mappings
    mapping(uint256 => DiamondListing) private diamondListings;
    mapping(uint256 => OwnershipRecord) private consumerOwnership;
    mapping(uint256 => TheftReport[]) private theftReports;
    ////////////

    ///////////events
    event DiamondListed(uint256 indexed diamondId, address indexed seller);
    ///////////

    //constructor
    constructor(address _entityContractAddress, address _provenanceContractAddress) 
        Ownable(msg.sender) 
    {
        entityContract = EntityContract(_entityContractAddress);
        provenanceContract = ProvenanceContract(_provenanceContractAddress);
    }

    //function to list the diamond by retailer
    function listDiamond(uint256 _diamondID) external {
        //check if the caller is the diamond owner in the provenance contract
        (uint256 id, address currentOwner, , , , , , , ) = provenanceContract.getDiamondInfo(_diamondID);
        require(currentOwner == msg.sender, "Only the diamond owner can list it");
        
        //check if the caller is a registered retailer
        (,,bool isRegistered,,string memory role) = entityContract.getEntityInfo(msg.sender);
        require(isRegistered, "Caller is not a registered entity");
        require(keccak256(abi.encodePacked(role)) == keccak256(abi.encodePacked("Retailer")),
            "Only retailers can list diamonds for initial sale");
        
        //Create the listing
        diamondListings[_diamondID] = DiamondListing({
            diamondID: _diamondID,
            seller: msg.sender,
            isListed: true,
            status: DiamondStatus.Available
        });
        
        emit DiamondListed(_diamondID, msg.sender);
    }

}

//TO IMPLEMENT
//DONE listDiamond
//sellToConsumer
//transferConsumerDiamond
//reportStolen
//reportLost
//resolveTheftReport
//verifyDiamond
//getDiamondStatus
//getConsumerOwnership
//generateProvenanceCertificate
//