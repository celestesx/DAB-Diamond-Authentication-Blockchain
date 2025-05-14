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

    
}