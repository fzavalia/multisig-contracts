// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MultiSigWallet {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public confirmationsRequired;
    Transaction[] transactions;
    mapping(uint256 => mapping(address => bool)) transactionConfirmedBy;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    event TransactionSubmitted(uint256 _index, address _to, uint256 _value, bytes _data);
    event TransactionConfirmed(uint256 _index, address _sender);
    event TransactionExecuted(uint256 _index, address _sender);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    modifier transactionExists(uint256 _index) {
        require(_index < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 _index) {
        Transaction memory transaction = transactions[_index];
        require(!transaction.executed, "Already executed");
        _;
    }

    constructor(address[] memory _owners, uint256 _confirmationsRequired) {
        require(_owners.length >= 1, "Invalid owners length");
        require(_confirmationsRequired > 0 && _confirmationsRequired <= _owners.length, "Invalid confirmations required");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Repeated owner");

            isOwner[owner] = true;
            owners.push(owner);
        }

        confirmationsRequired = _confirmationsRequired;
    }

    function submit(address _to, uint256 _value, bytes memory _data) external onlyOwner {
        uint256 index = transactions.length;

        Transaction memory transaction;

        transaction.to = _to;
        transaction.value = _value;
        transaction.data = _data;

        transactions.push(transaction);

        emit TransactionSubmitted(index, _to, _value, _data);
    }

    function confirm(uint256 _index) external onlyOwner transactionExists(_index) notExecuted(_index) {
        address sender = msg.sender;

        Transaction storage transaction = transactions[_index];

        require(!transactionConfirmedBy[_index][sender], "Already confirmed by sender");

        transaction.confirmations++;
        transactionConfirmedBy[_index][sender] = true;

        emit TransactionConfirmed(_index, sender);
    }

    function execute(uint256 _index) external onlyOwner transactionExists(_index) notExecuted(_index) {
        Transaction storage transaction = transactions[_index];

        require(transaction.confirmations >= confirmationsRequired, "Not enough confirmations");

        (bool success,) = transaction.to.call{ value: transaction.value }(transaction.data);

        require(success, "Call execution failed");

        transaction.executed = true;

        emit TransactionExecuted(_index, msg.sender);
    }
}
