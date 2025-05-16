// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EntityContract.sol";
import "./ProvenanceContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketplaceContract is Ownable{
    EntityContract private entityContract;
    ProvenanceContract private provenanceContract;

    enum DiamondStatus {Avaialable, Sold, Stolen, Lost}

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

    mapping(uint256 => DiamondListing) private diamondListings;
    mapping(uint256 => OwnershipRecord) private consumerOwnership;
    mapping(uint256 => TheftReport[]) private theftReports;

    constructor(address _entityContractAddress, address _provenanceContractAddress) 
        Ownable(msg.sender) 
    {
        entityContract = EntityContract(_entityContractAddress);
        provenanceContract = ProvenanceContract(_provenanceContractAddress);
    }
}