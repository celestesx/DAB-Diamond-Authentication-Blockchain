// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EntityContract.sol";
import "./ProvenanceContract.sol";

contract MarketplaceContract {
    EntityContract private entityContract;
    ProvenanceContract private provenanceContract;

    struct DiamondStatus {
        bool isForSale;
        uint256 price;
        bool isStolenMissing;
        string statusDetails;
    }

    mapping(uint256 => DiamondStatus) public diamondStatuses;
    mapping(uint256 => address) public consumerOwners;

    constructor(address _entityContractAddress, address _provenanceContractAddress) {
        entityContract = EntityContract(_entityContractAddress);
        provenanceContract = ProvenanceContract(_provenanceContractAddress);
    }

    //to be implemented
    // 1. listDiamondForSale - retailers list diamonds for consumer purchase
    // 2. purchaseDiamond - consumers buy from retailers
    // 3. transferOwnership - consumer-to-consumer transfers
    // 4. reportStolen - mark diamonds as stolen
    // 5. generateProvenance - create consumer-facing provenance certificate
}