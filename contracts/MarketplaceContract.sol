// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProvenanceContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Marketplace is Ownable {
    using Counters for Counters.Counter;
    
    // Structs
    struct Listing {
        uint256 diamondId;
        address seller;
        bool active;
        uint256 listedAt;
    }
    
    struct StolenReport {
        uint256 diamondId;
        address reporter;
        uint256 reportTime;
        string details;
        bool resolved;
    }
    
    // State variables
    Provenance private _provenanceContract;
    Counters.Counter private _listingIds;
    Counters.Counter private _reportIds;
    
    // Mappings
    mapping(uint256 => Listing) private _listings; // listingId => Listing
    mapping(uint256 => uint256) private _diamondToListing; // diamondId => listingId
    mapping(uint256 => StolenReport[]) private _stolenReports; // diamondId => StolenReport[]
    mapping(uint256 => bool) private _isStolen; // diamondId => stolen status
    
    // Events
    event DiamondListed(uint256 indexed listingId, uint256 indexed diamondId, address indexed seller);
    event DiamondSold(uint256 indexed listingId, uint256 indexed diamondId, address indexed buyer);
    event ListingCancelled(uint256 indexed listingId, uint256 indexed diamondId, address indexed seller);
    event DiamondReportedStolen(uint256 indexed diamondId, address indexed reporter, string details);
    event StolenReportResolved(uint256 indexed diamondId, address indexed resolver);
    
    // Constructor
    constructor(address provenanceAddress) Ownable(msg.sender) {
        _provenanceContract = Provenance(provenanceAddress);
    }
    
    // ====== External/Public Functions ======
    
    /**
     * @dev List a diamond in the marketplace
     * @param diamondId The ID of the diamond NFT to list
     */
    function listDiamond(uint256 diamondId) external {
        // Check ownership
        require(_provenanceContract.ownerOf(diamondId) == msg.sender, "Not the owner of this diamond");
        require(!_isStolen[diamondId], "Cannot list a stolen diamond");
        
        // Check if diamond is already listed
        uint256 existingListingId = _diamondToListing[diamondId];
        if (existingListingId != 0) {
            require(!_listings[existingListingId].active, "Diamond is already listed");
        }
        
        // Create new listing without checking approval
        _listingIds.increment();
        uint256 listingId = _listingIds.current();
        
        _listings[listingId] = Listing({
            diamondId: diamondId,
            seller: msg.sender,
            active: true,
            listedAt: block.timestamp
        });
        
        _diamondToListing[diamondId] = listingId;
        
        emit DiamondListed(listingId, diamondId, msg.sender);
    }
    
    /**
     * @dev Direct completion of a sale without requiring approval - uses Provenance's transferDiamond
     * @param listingId The ID of the listing to sell
     * @param buyer The address of the buyer
     */
    function directCompleteSale(uint256 listingId, address buyer) external {
        Listing storage listing = _listings[listingId];
        
        // Validate listing and seller
        require(listing.active, "Listing is not active");
        require(listing.seller == msg.sender, "Only the seller can complete this sale");
        require(!_isStolen[listing.diamondId], "Cannot sell a stolen diamond");
        require(buyer != address(0), "Invalid buyer address");
        
        // Get the diamond ID
        uint256 diamondId = listing.diamondId;
        
        // Transfer using transferDiamond function which doesn't require approval
        _provenanceContract.transferDiamond(diamondId, buyer);
        
        // Update listing status
        listing.active = false;
        
        emit DiamondSold(listingId, diamondId, buyer);
    }
    
    /**
     * @dev Cancel a listing
     * @param listingId The ID of the listing to cancel
     */
    function cancelListing(uint256 listingId) external {
        Listing storage listing = _listings[listingId];
        
        require(listing.active, "Listing is not active");
        require(listing.seller == msg.sender, "Not the seller of this listing");
        
        listing.active = false;
        
        emit ListingCancelled(listingId, listing.diamondId, msg.sender);
    }
    
    /**
     * @dev Report a diamond as stolen or lost
     * @param diamondId The ID of the diamond to report
     * @param details Details about the theft or loss
     */
    function reportStolenDiamond(uint256 diamondId, string calldata details) external {
        // Only the current or previous owner can report a diamond as stolen
        require(
            _provenanceContract.ownerOf(diamondId) == msg.sender || 
            _wasOwner(diamondId, msg.sender),
            "Only current or previous owner can report"
        );
        
        // Create report
        StolenReport memory report = StolenReport({
            diamondId: diamondId,
            reporter: msg.sender,
            reportTime: block.timestamp,
            details: details,
            resolved: false
        });
        
        _stolenReports[diamondId].push(report);
        _isStolen[diamondId] = true;
        
        // Deactivate any active listings
        uint256 listingId = _diamondToListing[diamondId];
        if (listingId != 0 && _listings[listingId].active) {
            _listings[listingId].active = false;
        }
        
        emit DiamondReportedStolen(diamondId, msg.sender, details);
    }
    
    /**
     * @dev Resolve a stolen report (only for administrators)
     * @param diamondId The ID of the diamond to mark as resolved
     */
    function resolveReport(uint256 diamondId) external onlyOwner {
        require(_isStolen[diamondId], "No active stolen report for this diamond");
        
        _isStolen[diamondId] = false;
        
        // Mark all reports as resolved
        StolenReport[] storage reports = _stolenReports[diamondId];
        for (uint i = 0; i < reports.length; i++) {
            if (!reports[i].resolved) {
                reports[i].resolved = true;
            }
        }
        
        emit StolenReportResolved(diamondId, msg.sender);
    }
    
    // ====== View Functions (Getters) ======
    
    /**
     * @dev Get details about a specific diamond and its listing
     * @param diamondId The ID of the diamond
     */
    function getDiamondDetails(uint256 diamondId) external view returns (
        address currentOwner,
        bool isListed,
        bool isReportedStolen,
        string memory origin,
        uint256 weight,
        bool isCertified,
        string memory certificationId
    ) {
        // Get current owner
        currentOwner = _provenanceContract.ownerOf(diamondId);
        
        // Check if listed
        uint256 listingId = _diamondToListing[diamondId];
        isListed = listingId != 0 && _listings[listingId].active;
        
        // Check if reported stolen
        isReportedStolen = _isStolen[diamondId];
        
        // Get basic diamond info from Provenance contract
        (origin, , weight, ) = _provenanceContract.getDiamondBasicInfo(diamondId);
        
        // Get certification info
        (isCertified, certificationId, ) = _provenanceContract.getDiamondCertInfo(diamondId);
        
        return (
            currentOwner,
            isListed,
            isReportedStolen,
            origin,
            weight,
            isCertified,
            certificationId
        );
    }
    
    /**
     * @dev Get all active listings
     * @return Array of listing IDs
     */
    function getActiveListings() external view returns (uint256[] memory) {
        uint256 totalListings = _listingIds.current();
        
        // Count active listings
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= totalListings; i++) {
            if (_listings[i].active && !_isStolen[_listings[i].diamondId]) {
                activeCount++;
            }
        }
        
        // Create array of active listing IDs
        uint256[] memory activeListings = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= totalListings; i++) {
            if (_listings[i].active && !_isStolen[_listings[i].diamondId]) {
                activeListings[index] = i;
                index++;
            }
        }
        
        return activeListings;
    }
    
    /**
     * @dev Get listing details
     * @param listingId The ID of the listing
     */
    function getListingDetails(uint256 listingId) external view returns (
        uint256 diamondId,
        address seller,
        bool active,
        uint256 listedAt
    ) {
        require(listingId > 0 && listingId <= _listingIds.current(), "Invalid listing ID");
        
        Listing storage listing = _listings[listingId];
        return (
            listing.diamondId,
            listing.seller,
            listing.active,
            listing.listedAt
        );
    }
    
    /**
     * @dev Get all stolen reports for a diamond
     * @param diamondId The ID of the diamond
     */
    function getStolenReports(uint256 diamondId) external view returns (
        address[] memory reporters,
        uint256[] memory reportTimes,
        string[] memory details,
        bool[] memory resolved
    ) {
        StolenReport[] storage reports = _stolenReports[diamondId];
        uint256 reportCount = reports.length;
        
        reporters = new address[](reportCount);
        reportTimes = new uint256[](reportCount);
        details = new string[](reportCount);
        resolved = new bool[](reportCount);
        
        for (uint256 i = 0; i < reportCount; i++) {
            reporters[i] = reports[i].reporter;
            reportTimes[i] = reports[i].reportTime;
            details[i] = reports[i].details;
            resolved[i] = reports[i].resolved;
        }
        
        return (reporters, reportTimes, details, resolved);
    }
    
    /**
     * @dev Check if a diamond is currently reported as stolen
     * @param diamondId The ID of the diamond
     */
    function isDiamondStolen(uint256 diamondId) external view returns (bool) {
        return _isStolen[diamondId];
    }
    
    // ====== Internal Helper Functions ======
    
    /**
     * @dev Check if an address was a previous owner of the diamond
     * This is a simplified implementation that always returns true for previous owners
     * In a real implementation, you would check the diamond's history from the Provenance contract
     */
    function _wasOwner(uint256 diamondId, address account) internal view returns (bool) {
        string[] memory history = _provenanceContract.getDiamondHistory(diamondId);
        
        // Convert address to string for comparison
        string memory accountStr = _addressToString(account);
        
        // Check if account appears in history
        for (uint256 i = 0; i < history.length; i++) {
            if (contains(history[i], accountStr)) {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * @dev Check if a string contains another string
     */
    function contains(string memory source, string memory search) internal pure returns (bool) {
        bytes memory sourceBytes = bytes(source);
        bytes memory searchBytes = bytes(search);
        
        if (searchBytes.length > sourceBytes.length) {
            return false;
        }
        
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
    
    /**
     * @dev Convert address to string
     * Similar implementation as in Provenance contract
     */
    function _addressToString(address addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr)));
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
}