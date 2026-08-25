

contract Assigment {

    address public creator;

    // Register Manufacturing facilities
    struct Facility {
        string name;
        address owner;

    }

    // Submit emissions records (or hashes of emissions reports)
    struct EmissionRecord {
        uint256 RecordID;
        uint256 FacilityID;
        uint64 Year; 
        address submittedBy;
        uint256 Timestamp;
        uint256 ReportHash;
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
    event RecordSubmitted(uint256 RecordID, uint256 FacilityID, uint256 ReportHash, address SubmittedBy); //triggered when emission is reported
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

}


