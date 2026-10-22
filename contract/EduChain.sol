// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Soulbound-style certificate registry: certificates are bound to the student and cannot be transferred.
/// Store only a hash/CID of the certificate file, never personal documents.
contract EduChain {
    address public admin = msg.sender;
    struct Institution { string name; bool active; }
    struct Cert { address issuer; address student; string studentName; string title; string fileHash; uint256 issuedAt; bool revoked; }

    mapping(address => Institution) public institutions;
    address[] private instList;
    Cert[] private certs;
    mapping(address => uint256[]) private byStudent;
    mapping(address => uint256[]) private byIssuer;

    event InstitutionAdded(address indexed institution, string name);
    event InstitutionRemoved(address indexed institution);
    event Issued(uint256 indexed id, address indexed issuer, address indexed student);
    event Revoked(uint256 indexed id, address indexed issuer);

    modifier onlyAdmin() { require(msg.sender == admin, "admin only"); _; }

    function transferAdmin(address a) external onlyAdmin { require(a != address(0), "zero"); admin = a; }

    function addInstitution(address a, string calldata name) external onlyAdmin {
        require(a != address(0) && bytes(name).length > 0, "invalid");
        if (bytes(institutions[a].name).length == 0) instList.push(a);
        institutions[a] = Institution(name, true);
        emit InstitutionAdded(a, name);
    }
    function removeInstitution(address a) external onlyAdmin { institutions[a].active = false; emit InstitutionRemoved(a); }
    function institutionCount() external view returns (uint256) { return instList.length; }
    function institutionAt(uint256 i) external view returns (address, string memory, bool) {
        address a = instList[i]; return (a, institutions[a].name, institutions[a].active);
    }

    function issue(address student, string calldata studentName, string calldata title, string calldata fileHash) external returns (uint256 id) {
        require(institutions[msg.sender].active, "not an approved institution");
        require(student != address(0) && bytes(title).length > 0 && bytes(studentName).length > 0, "invalid");
        certs.push(Cert(msg.sender, student, studentName, title, fileHash, block.timestamp, false));
        id = certs.length - 1;
        byStudent[student].push(id); byIssuer[msg.sender].push(id);
        emit Issued(id, msg.sender, student);
    }
    function revoke(uint256 id) external {
        require(id < certs.length, "not found");
        Cert storage c = certs[id];
        require(c.issuer == msg.sender, "only issuer");
        require(!c.revoked, "already revoked");
        c.revoked = true;
        emit Revoked(id, msg.sender);
    }

    function totalCerts() external view returns (uint256) { return certs.length; }
    function getCert(uint256 id) external view returns (address, string memory, address, string memory, string memory, string memory, uint256, bool) {
        require(id < certs.length, "not found");
        Cert storage c = certs[id];
        return (c.issuer, institutions[c.issuer].name, c.student, c.studentName, c.title, c.fileHash, c.issuedAt, c.revoked);
    }
    function certsOf(address student) external view returns (uint256[] memory) { return byStudent[student]; }
    function issuedBy(address inst) external view returns (uint256[] memory) { return byIssuer[inst]; }
}
