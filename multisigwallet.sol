
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Multisigwallet {
    using SafeMath for uint256;

    event ProposeTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event Deposit(address indexed sender, uint amount, uint balance);

    struct transaction{
        uint256 txIndex;
        address from;
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    mapping(uint =>mapping(address=>bool)) public txConfirmations;

    transaction[] public transactions;

    // Addres of the access registry contract
    address AccessregistryAddress =0xa9d281dA3B02DF2ffc8A1955c45d801B5726661D;

    modifier onlyOwner() {
        (bool result,bytes memory data) =AccessregistryAddress.call(abi.encodeWithSignature("isOwner(address)", msg.sender));
        require(result,"Call to AccessRegistry contract failed");
        bool isowner;
        isowner =abi.decode(data,(bool));
        require(isowner, "You are not an owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!txConfirmations[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor() payable{
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // Get the balance of this contract
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    // Propose a new transaction 
    function proposeTransaction(address _to, uint _value, bytes memory _data) public {
        uint txIndex =transactions.length;
        transactions.push(
            transaction({
                txIndex:txIndex,
                from:msg.sender,
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                confirmations: 0  
            })
        );
        emit ProposeTransaction(msg.sender, txIndex, _to, _value, _data);
    }
    // Confirm an already existing transaction 
    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        transaction storage _transaction = transactions[_txIndex];
        _transaction.confirmations ++;
        txConfirmations[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    // Execute a transaction  
    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        transaction storage _transaction = transactions[_txIndex];
        
        (bool result,bytes memory data) =AccessregistryAddress.call(abi.encodeWithSignature("MINIMUM_CONFIRMATIONS()"));
        require(result,"Call to AccessRegistry contract failed");
        uint256 _MINIMUM_CONFIRMATIONS;
        _MINIMUM_CONFIRMATIONS =abi.decode(data,(uint256));

        require(_transaction.confirmations >= _MINIMUM_CONFIRMATIONS,"cannot execute tx");
        _transaction.executed = true;

        (bool success,) = (_transaction.to).call{value: _transaction.value}(_transaction.data);
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    // Revoke a transaction 
    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        transaction storage _transaction = transactions[_txIndex];
        require(txConfirmations[_txIndex][msg.sender], "tx not confirmed");

        _transaction.confirmations--;
        txConfirmations[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }
    function transactionsCount() public view returns(uint){
        return transactions.length;
    }
}