// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract Accessregistry{

    using SafeMath for uint256;

    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event TransferOwner(address indexed from, address indexed to);

    address admin;

    address[] public owners;

    mapping(address =>bool) public isOwner; 
    uint256 public MINIMUM_CONFIRMATIONS;

    modifier onlyAdmin(){
        require(msg.sender ==admin, "Only admin can call");
        _;
    }

    constructor(){
        admin =msg.sender;
    }

    function getOwnerCount() public view returns(uint){
        return owners.length;    
    }

    // Only admin add a new owner to the multisig Wallet
    function addOwner(address _owner) public onlyAdmin{
        require(address(_owner)==_owner,"Invalid address");
        require(isOwner[_owner]==false,"Address already owner");
        owners.push(_owner);
        isOwner[_owner]= true;

        if((owners.length*6)%10 ==0){
            MINIMUM_CONFIRMATIONS =(owners.length*6)/10;
        }else{
            MINIMUM_CONFIRMATIONS =((owners.length*6)/10).add(1);
        }
        emit OwnerAdded(_owner);
    }

    // Only admin delete already existing owner from the multisig Wallet
    function revokeOwner(address _owner) public onlyAdmin{
        require(address(_owner)==_owner,"Invalid address");
        require(isOwner[_owner]==true,"Address not an owner");
        
        bool temp =false;
        for(uint i=0; i<owners.length; i++){
            if(temp){
                owners[i-1] =owners[i];
            }
            if(owners[i]== _owner){
                delete owners[i];
                temp =true;
            }
        } 
        delete owners[owners.length-1];
        isOwner[_owner]= false;
        owners.pop();

        if((owners.length*6)%10 ==0){
            MINIMUM_CONFIRMATIONS =(owners.length*6)/10;
        }else{
            MINIMUM_CONFIRMATIONS =((owners.length*6)/10).add(1);
        }
        emit OwnerRemoved(_owner);
    }

    // Only admin replaces an owner `_from` with another `_to`.
    function transferOwner(address _from, address _to) public onlyAdmin{
        require(address(_from)==_from,"Invalid from address");
        require(address(_to)==_to,"Invalid to address");

        require(isOwner[_from]==true,"from address is not an owner");
        require(isOwner[_to]==false,"to address is already an owner");

        for(uint i=0; i<owners.length; i++){
            if(owners[i]== _from){
                delete owners[i];
                owners[i] =_to;
                break;
            }
        } 
        emit TransferOwner(_from,_to);
    }
}


// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 

// 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
// 0x617F2E2fD72FD9D5503197092aC168c91465E7f2

// proposeTransaction
// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,10,"0x00"