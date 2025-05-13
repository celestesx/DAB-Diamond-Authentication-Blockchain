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

    

}