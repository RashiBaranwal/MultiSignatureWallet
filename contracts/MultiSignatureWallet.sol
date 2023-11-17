// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSignatureWallet {
    //It is a Counter to keep track of transaction IDs
    uint256 public transactionCount;

    //This mapping is to store whether an owner has approved a specific transaction
    mapping(uint256 => mapping(address => bool)) public approvals;

    // To store the balance of each owner
    mapping(address => uint256) public balances;

    // Array to store the addresses of the owners
    address[3] public owners;

    // Event emitted when a new transaction is proposed
    event TransactionProposed(uint256 indexed transactionId, address indexed destination, uint256 amount);

    // Event emitted when a transaction is approved by an owner
    event TransactionApproved(uint256 indexed transactionId, address indexed approver);

    // Event emitted when a transaction is executed
    event TransactionExecuted(uint256 indexed transactionId, address indexed destination, uint256 amount);

    // Event emitted when an owner is added to the wallet
    event OwnerAdded(address indexed newOwner);

    // Modifier to ensure that the caller is one of the owners
    modifier onlyOwners() {
        require(
            msg.sender == owners[0] || msg.sender == owners[1] || msg.sender == owners[2],
            "Caller is not an owner"
        );
        _;
    }

    // Modifier to ensure that the transaction ID is valid
    modifier validTransaction(uint256 _transactionId) {
        require(_transactionId < transactionCount, "Invalid transaction ID");
        _;
    }

    // Modifier to ensure that the transaction has not been already approved by the caller
    modifier notApproved(uint256 _transactionId) {
        require(!approvals[_transactionId][msg.sender], "Transaction already approved by the caller");
        _;
    }

    // Modifier to ensure that the transaction requires at least two approvals
    modifier twoApprovals(uint256 _transactionId) {
        uint256 approvalsCount = 0;
        for (uint8 i = 0; i < 3; i++) {
            if (approvals[_transactionId][owners[i]]) {
                approvalsCount++;
            }
        }
        require(approvalsCount >= 2, "Transaction requires at least two approvals");
        _;
    }

    // Constructor to initialize the owners
    constructor(address _owner1, address _owner2, address _owner3) {
        owners[0] = _owner1;
        owners[1] = _owner2;
        owners[2] = _owner3;

        // Emit an event for each owner added
        emit OwnerAdded(_owner1);
        emit OwnerAdded(_owner2);
        emit OwnerAdded(_owner3);
    }

    // Function to propose a new transaction
    function proposeTransaction(address _destination, uint256 _amount)
        external
        onlyOwners
    {
        // Increment the transaction count to generate a unique ID
        uint256 transactionId = transactionCount++;

        // Emit an event for the proposed transaction
        emit TransactionProposed(transactionId, _destination, _amount);
    }

    // Function for owners to approve a transaction
    function approveTransaction(uint256 _transactionId)
        external
        onlyOwners
        validTransaction(_transactionId)
        notApproved(_transactionId)
    {
        // Mark the transaction as approved by the caller
        approvals[_transactionId][msg.sender] = true;

        // Emit an event for the approval
        emit TransactionApproved(_transactionId, msg.sender);
    }

    // Function to execute a transaction once it has enough approvals
    function executeTransaction(uint256 _transactionId)
        external
        onlyOwners
        validTransaction(_transactionId)
        twoApprovals(_transactionId)
    {
        // Ensure the transaction has not been executed before
        require(!approvals[_transactionId][address(0)], "Transaction already executed");

        // Mark the transaction as executed
        approvals[_transactionId][address(0)] = true;

        // Get the destination and amount of the transaction
        address destination = address(bytes20(approvals[_transactionId][0]));
        uint256 amount = uint256(bytes32(approvals[_transactionId][1]));

        // Transfer the specified amount to the destination address
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(destination).transfer(amount);

        // Emit an event for the executed transaction
        emit TransactionExecuted(_transactionId, destination, amount);
    }

    // Function to get the balance of an owner
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
}
