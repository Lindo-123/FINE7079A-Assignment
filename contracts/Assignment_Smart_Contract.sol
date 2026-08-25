// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Assigment {

    address public creator;

    // Register Manufacturing facilities
    struct Facility {
        string name;
        address owner;

    }

    // Submit emissions records (or hashes of emissions reports)
    struct EmissionRecord {
        //uint256 RecordID;
        uint256 FacilityID;
        uint256 Year; 
        address submittedBy;
        uint256 Timestamp;
        bytes32 ReportHash;
        bool verified;
        address verifier;  // or auditor
    }

    Facility[] public facilities; 
    EmissionRecord[] public records;

    mapping(uint256 => uint256[]) public FacilityRecords; //facility to record
    mapping(address => bool) public AuthSubmitter; 
    mapping(address => bool) public AuthVerifier;   

    //Events 
    event FacilityRegistered(uint256 FacilityID, string name, address owner); //triggered when a new facility is added
    event RecordSubmitted(uint256 RecordID, uint256 FacilityID, bytes32 ReportHash, address SubmittedBy); //triggered when emission is reported
    event RecordVerified(uint256 RecordID, address verifier);  //When auditor signs reported emissions
    event SubmitterChanged(address account, bool allowed); //submitter authorisation changes
    event VerifierChanged(address account, bool allowed); //verifier authority changes

    constructor() {
        creator = msg.sender;
        AuthSubmitter[msg.sender] = true; 
    }

    // Now we create functions 

    // Setting authorised submitters and verifiers/auditors, this should only be done by creator of the smart contract. 

    modifier onlyCreator() {
        require(msg.sender == creator, "creator capabilities");
        _;
    }

    function setSubmitter(address account, bool allowed) public onlyCreator {
        require(account != address(0), "Invalid address");
        AuthSubmitter[account] = allowed;
        emit SubmitterChanged(account, allowed);
    }

    function setVerifier(address account, bool allowed) public onlyCreator {
        require(account != address(0), "Invalid address");
        AuthVerifier[account] = allowed;
        emit VerifierChanged(account, allowed);
    }

    // Adding Facilities to register 
    function RegisterFacility(string memory name, address owner) public onlyCreator{
        require(bytes(name).length >0, "No name");
        require(owner != address(0), "Invalid address");
        facilities.push(Facility(name, owner));

        uint256 FacilityID = facilities.length-1; 
        emit FacilityRegistered(FacilityID, name, owner);

    }

    //Submitting emission record
    
    modifier onlySubmitter() {
        require(AuthSubmitter[msg.sender], "not authorised submitter");
        _;
    }

    function submitRecord(
        uint256 FacilityID, bytes32 ReportHash, uint256 Year) public onlySubmitter(){
            require(FacilityID < facilities.length, "Facility does not exist");
            require(ReportHash != bytes32(0), "Hash cannot be empty");
            require(Year >= 2000 && Year <2100, "Invalid year");

            records.push(EmissionRecord({
                FacilityID: FacilityID, ReportHash: ReportHash, Year: Year, submittedBy: msg.sender, Timestamp: block.timestamp,
                verified: false, verifier: address(0)

            })); 
            uint256 RecordID = records.length-1;
            FacilityRecords[FacilityID].push(RecordID);

            emit RecordSubmitted(RecordID, FacilityID, ReportHash, msg.sender);
        }

    
    //Auditor verifying/approving record (more of a sign-off)

    modifier onlyVerifier() {
        require(AuthVerifier[msg.sender], "not authorised verifier");
        _;
    }

    function verifyRecord(uint256 RecordID) public onlyVerifier {
        require(RecordID < records.length, "Record does not exist");
        require(!records[RecordID].verified, "Record already verified"); 
        require(records[RecordID].submittedBy != msg.sender, "Cannot verify your own submission");
        records[RecordID].verified = true;
        records[RecordID]. verifier = msg.sender;
        emit RecordVerified(RecordID, msg.sender);
    }

    // Retrieve emissions records for verification.
    function computeHash(string memory report, string memory salt) public pure returns (bytes32) {
        return keccak256(abi.encode(report, salt));
    }

    function checkRecord(uint256 RecordId, string memory report, string memory salt)
        public view returns (bool)
    {
        require(RecordId < records.length, "Record does not exist");
        return records[RecordId].ReportHash == keccak256(abi.encode(report, salt));
    }

    function getRecordIdsForFacility(uint256 FacilityID) public view returns (uint256[] memory) {
        require(FacilityID < facilities.length, "Facility does not exist");
        return FacilityRecords[FacilityID];
    }

    function totalFacilities() public view returns (uint256) {
        return facilities.length;
    }

    function totalRecords() public view returns (uint256) {
        return records.length;
    }

}


