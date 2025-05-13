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
        uint256 weight;
        string characteristics;
        bool isCertified;
        string certificatioID;
        string[] processingHistory;
        uint256 rawDiamondID; //this is for the original raw diamond
    }

    mapping(uint256 => Diamond) public diamonds;
    uint256 private nextDiamondID = 1;

    constructor(address _entityContractAddress) {
        entityContract = EntityContract(_entityContractAddress);
    }

    //to implement
    // 1. registerRawDiamond - for miners to register new diamonds
    // 2. transferDiamond - transfer diamond between stakeholders
    // 3. processDiamond - manufacturers process raw diamonds into new ones
    // 4. certifyDiamond - certifiers add certification details
    // 5. getDiamondHistory - get complete history of a diamond
}