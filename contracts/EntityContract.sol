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

    //map entitiy addresses to their info
    mapping(address => Entity) private entities;

    //registered entity addresses by role
    mapping(string => address[]) private entitiesByRole;

    //events
    event EntityRegistered(address indexed entityAddress, string name, string role, string licenseNumber);

    //function to register entity
    function registerEntity(
        string memory _name,
        string memory _location,
        string memory _role,
        string memory _licenseNumber
    ) public {
        string memory normalisedRole = normaliseRole(_role);
        
        require(
            isValidRole(normalisedRole),
            "Invalid role. Must be Miner, Manufacturer, Certifier, or Retailer"
        );

        require(!entities[msg.sender].isRegistered, "Entity already registered");

        bytes memory licenseBytes = bytes(_licenseNumber);
        require(licenseBytes.length > 0, "License number cannot be empty");

        bytes1 expectedPrefix = getLicensePrefixForRole(normalisedRole);
        require(licenseBytes[0] == expectedPrefix, 
            string(abi.encodePacked("License must start with '", expectedPrefix, "' for ", normalisedRole)));
        
        //Create entity
        entities[msg.sender] = Entity({
            name: _name,
            location: _location,
            isRegistered: true,
            licenseNumber: _licenseNumber,
            role: normalisedRole
        });
    }

    function normaliseRole(string memory _role) private pure returns (string memory) {
        bytes32 roleHash = keccak256(abi.encodePacked(_toLowerCase(_role)));
        
        if (roleHash == keccak256(abi.encodePacked(_toLowerCase(ROLE_MINER)))) {
            return ROLE_MINER;
        } else if (roleHash == keccak256(abi.encodePacked(_toLowerCase(ROLE_MANUFACTURER)))) {
            return ROLE_MANUFACTURER;
        } else if (roleHash == keccak256(abi.encodePacked(_toLowerCase(ROLE_CERTIFIER)))) {
            return ROLE_CERTIFIER;
        } else if (roleHash == keccak256(abi.encodePacked(_toLowerCase(ROLE_RETAILER)))) {
            return ROLE_RETAILER;
        } else {
            return _role;
        }
    }

    function _toLowerCase(string memory _str) private pure returns (string memory) {
        bytes memory bStr = bytes(_str);
        bytes memory bLower = new bytes(bStr.length);
        
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        
        return string(bLower);
    }

    function isValidRole(string memory _role) private pure returns (bool) {
        return keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked(ROLE_MINER)) ||
               keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked(ROLE_MANUFACTURER)) ||
               keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked(ROLE_CERTIFIER)) ||
               keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked(ROLE_RETAILER));
    }

    function getLicensePrefixForRole(string memory _role) private pure returns (bytes1) {
        bytes32 roleHash = keccak256(abi.encodePacked(_role));
        
        if (roleHash == keccak256(abi.encodePacked(ROLE_MINER))) {
            return 'a';
        } else if (roleHash == keccak256(abi.encodePacked(ROLE_MANUFACTURER))) {
            return 'b';
        } else if (roleHash == keccak256(abi.encodePacked(ROLE_CERTIFIER))) {
            return 'c';
        } else if (roleHash == keccak256(abi.encodePacked(ROLE_RETAILER))) {
            return 'd';
        } else {
            revert("Invalid role");
        }
    }
}
