// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EntityContract {
    string constant ROLE_MINER = "Miner";
    string constant ROLE_MANUFACTURER = "Manufacturer";
    string constant ROLE_CERTIFIER = "Certifier";
    string constant ROLE_RETAILER = "Retailer";

    struct Entity {
        string name;
        string location;
        bool isRegistered;
        string licenseNumber;
        string role;
    }
}
