// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EntityContract {
    string constant ROLE_MINER = "Miner";
    string constant ROLE_MANUFACTURER = "Manufacturer";
    string constant ROLE_CERTIFIER = "Certifier";
    string constant ROLE_RETAILER = "Retailer";

    //hardcode blacklisted locations for proof of concept
    //info from: https://verite.org/project/diamonds-3/
    string[] private blacklistedLocations = [
        "angola",
        "central african republic",
        "congo",
        "guinea",
        "liberia",
        "sierra leone"
    ];

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
        
        //Only stated roles can register
        require(
            isValidRole(normalisedRole),
            "Invalid role. Must be Miner, Manufacturer, Certifier, or Retailer"
        );

        //reject if blacklisted zone
        string memory normalisedLocation = _toLowerCase(_location);
        require(!isLocationBlacklisted(normalisedLocation), 
            "Registration rejected: Location is in a conflict zone banned by the Kimberley Process");

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

        entitiesByRole[normalisedRole].push(msg.sender);

        emit EntityRegistered(msg.sender, _name, normalisedRole, _licenseNumber);
    }

    //check if a location is blacklisted
    function isLocationBlacklisted(string memory _location) private view returns (bool) {
        string memory lowerLocation = _toLowerCase(_location);
        
        for (uint i = 0; i < blacklistedLocations.length; i++) {
            if (containsString(lowerLocation, blacklistedLocations[i])) {
                return true;
            }
        }
        return false;
    }

    //check if a string contains another string
    function containsString(string memory _source, string memory _search) private pure returns (bool) {
        bytes memory sourceBytes = bytes(_source);
        bytes memory searchBytes = bytes(_search);
        
        if (searchBytes.length > sourceBytes.length) {
            return false;
        }
        
        //substring search
        for (uint i = 0; i <= sourceBytes.length - searchBytes.length; i++) {
            bool found = true;
            for (uint j = 0; j < searchBytes.length; j++) {
                if (sourceBytes[i + j] != searchBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                return true;
            }
        }
        
        return false;
    }

    //check if a wallet address has a role
    function hasRole(address _address, string memory _role) private view returns (bool) {
        if (!entities[_address].isRegistered) {
            return false;
        }
        
        string memory normalizedRole = normaliseRole(_role);
        return keccak256(abi.encodePacked(entities[_address].role)) == 
               keccak256(abi.encodePacked(normalizedRole));
    }

    //get entities by role
    function getEntitiesByRole(string memory _role) public view returns (address[] memory) {
        string memory normalisedRole = normaliseRole(_role);
        return entitiesByRole[normalisedRole];
    } 

    //get entity info
    function getEntityInfo(address _entityAddress) public view returns (
        string memory name,
        string memory location,
        bool isRegistered,
        string memory licenseNumber,
        string memory role
    ) {
        Entity storage entity = entities[_entityAddress];
        return (
            entity.name,
            entity.location,
            entity.isRegistered,
            entity.licenseNumber,
            entity.role
        );
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
