

contract Assigment {

    // Register Manufacturing facilities
    struct Facility {
        string name;
        address owner;

    }

    // Submit emissions records (or hashes of emissions reports)
    struct EmissionRecord {
        uint256 RecordID;
        string FacilityName;
        uint64 Date; 
        address submittedBy;
        uint256 ReportHash;

    }




}


