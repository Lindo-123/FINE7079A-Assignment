// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Assignment {

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
        bool signedOff;    // internal auditor sign-off
        address auditor;   // internal auditor who signed off
        bool verified;     // external verification 
        bool rejected;
        address verifier;  // external verifier
    }

    Facility[] public facilities; 
    EmissionRecord[] public records;

    mapping(uint256 => uint256[]) public FacilityRecords; //facility to record
    mapping(uint256 => mapping(address => bool)) public AuthSubmitter; 
    mapping(uint256 => mapping(address => bool)) public AuthAuditor; //internal auditor, per facility
    mapping(address => bool) public AuthVerifier; // External verifier
    mapping(uint256 => mapping(uint256 => bool)) public PeriodReported; 

    //Events 
    event FacilityRegistered(uint256 indexed FacilityID, string name, address indexed owner); //triggered when a new facility is added
    event RecordSubmitted(uint256 indexed RecordID, uint256 indexed FacilityID, bytes32 ReportHash, address indexed SubmittedBy); //triggered when emission is reported
    event RecordSignedOff(uint256 indexed RecordID, address indexed auditor); //When the internal auditor signs off
    event RecordVerified(uint256 indexed RecordID, address indexed verifier);  //When auditor signs reported emissions
    event RecordRejected(uint256 indexed RecordID, address indexed verifier, string reason); //When auditor rejects reported emissions
    event SubmitterChanged(uint256 indexed FacilityID, address indexed account, bool allowed); //submitter authorisation changes
    event AuditorChanged(uint256 indexed FacilityID, address indexed account, bool allowed); //internal auditor authorisation changes
    event VerifierChanged(address indexed account, bool allowed); //verifier authority changes

    constructor() {
        creator = msg.sender;
        //AuthSubmitter[msg.sender] = true; 
    }

    // Now we create functions 

    // Setting authorised submitters and verifiers/auditors, this should only be done by creator (regulator) of the smart contract. 

    modifier onlyCreator() {
        require(msg.sender == creator, "creator capabilities");
        _;
    }

    function setSubmitter(uint256 FacilityID, address account, bool allowed) public onlyCreator {
        require(FacilityID < facilities.length, "Facility does not exist");
        require(account != address(0), "Invalid address");
        AuthSubmitter[FacilityID][account] = allowed;
        emit SubmitterChanged(FacilityID, account, allowed);
    }

    function setAuditor(uint256 FacilityID, address account, bool allowed) public onlyCreator {
        require(FacilityID < facilities.length, "Facility does not exist");
        require(account != address(0), "Invalid address");
        AuthAuditor[FacilityID][account] = allowed;
        emit AuditorChanged(FacilityID, account, allowed);
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
        AuthSubmitter[FacilityID][owner] = true;
        emit FacilityRegistered(FacilityID, name, owner);
        emit SubmitterChanged(FacilityID, owner, true);

    }

    //Submitting emission record
    
    modifier onlySubmitter(uint256 FacilityID) {
        require(FacilityID < facilities.length, "Facility does not exist");
        require(AuthSubmitter[FacilityID][msg.sender], "not authorised submitter");
        _;
    }

    function submitRecord(
        uint256 FacilityID, bytes32 ReportHash, uint256 Year) public onlySubmitter(acilityID){
            // require(FacilityID < facilities.length, "Facility does not exist");
            require(ReportHash != bytes32(0), "Hash cannot be empty");
            require(Year >= 2000 && Year <2100, "Invalid year");
            require(!PeriodReported[FacilityID][Year], "Period already reported");

            records.push(EmissionRecord({
                FacilityID: FacilityID, ReportHash: ReportHash, Year: Year, submittedBy: msg.sender, Timestamp: block.timestamp,
                signedOff: false, auditor: address(0), verified: false, rejected: false, verifier: address(0)

            })); 
            uint256 RecordID = records.length-1;
            FacilityRecords[FacilityID].push(RecordID);
            PeriodReported[FacilityID][Year] = true;

            emit RecordSubmitted(RecordID, FacilityID, ReportHash, msg.sender);
        }

    
    //Auditor verifying/approving record (more of a sign-off)

    modifier onlyAuditor(uint256 RecordID) {
        require(RecordID < records.length, "Record does not exist");
        require(AuthAuditor[records[RecordID].FacilityID][msg.sender], "not authorised auditor");
        _;
    }

    function signOffRecord(uint256 RecordID) public onlyAuditor(RecordID) {
        require(!records[RecordID].signedOff, "Record already signed off");
        require(!records[RecordID].verified, "Record already verified");
        require(!records[RecordID].rejected, "Record already rejected");
        require(records[RecordID].submittedBy != msg.sender, "Cannot sign off your own submission");
        require(!AuthSubmitter[records[RecordID].FacilityID][msg.sender], "Submitter cannot act as auditor");
        records[RecordID].signedOff = true;
        records[RecordID].auditor = msg.sender;
        emit RecordSignedOff(RecordID, msg.sender);
    }

    // External verifier sign-off or approval

    modifier onlyVerifier() {
        require(AuthVerifier[msg.sender], "not authorised verifier");
        _;
    }

    function verifyRecord(uint256 RecordID) public onlyVerifier {
        require(RecordID < records.length, "Record does not exist");
        require(records[RecordID].signedOff, "Record not signed off internally");
        require(!records[RecordID].verified, "Record already verified"); 
        require(!records[RecordID].rejected, "Record already rejected");
        require(records[RecordID].submittedBy != msg.sender, "Cannot verify your own submission");
        require(records[RecordID].auditor != msg.sender, "Cannot verify your own sign-off");
        require(!AuthSubmitter[records[RecordID].FacilityID][msg.sender], "Submitter cannot act as verifier");
        records[RecordID].verified = true;
        records[RecordID].verifier = msg.sender;
        emit RecordVerified(RecordID, msg.sender);
    }

    // Either the internal auditor or the external verifier may reject a record

    function rejectRecord(uint256 RecordID, string memory reason) public onlyVerifier {
        require(RecordID < records.length, "Record does not exist");
        require(!records[RecordID].verified, "Record already verified");
        require(!records[RecordID].rejected, "Record already rejected");
        require(records[RecordID].submittedBy != msg.sender, "Cannot reject your own submission");
        records[RecordID].rejected = true;
        records[RecordID].verifier = msg.sender;
        PeriodReported[records[RecordID].FacilityID][records[RecordID].Year] = false;
        emit RecordRejected(RecordID, msg.sender, reason);
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


