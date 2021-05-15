pragma solidity >=0.5.9 <0.9.0;

import './BankInterface.sol';

contract KYC is Bank {
    
    // Admin Functionalities..
    address[] private admins;
    address owner;
    
    // The first account becomes the super admin..
    constructor() public {
        owner = msg.sender;
    }

    // Function to add admin banks for the network..
    function addAdmins(address[] memory bankAddress) public _onlySuperAdmin _adminPresent(admins,bankAddress) {
        for(uint i = 0 ; i < bankAddress.length ; i++){
            assert(bankAddress[i] != address(0));
            admins.push(bankAddress[i]);
        }
        
    }
    // Function to add bank to the network
    function addBank(bytes32 bankName, address bankAddress, bytes32 regNumber) public _isAdmin(msg.sender) returns(uint256){
        require(bnk[bankAddress].name != bankName && bnk[bankAddress].regNumber != regNumber && bnk[bankAddress].ethAddress != bankAddress,"Bank with this name and register number already exists.. ");
        bnk[bankAddress] = bank({
            name: bankName,
            ethAddress: bankAddress,
            regNumber: regNumber,
            report: 0,
            kycCount: 0,
            kycPermission: true
        });
        totalBanks++; // Incrementing the total number of banks in the network..
        return totalBanks;
    }
    
    // Function to modify bank in the network
    function modifyBank(address bankAddress) public _isAdmin(msg.sender){
        assert(bankAddress != address(0));
        require(bnk[bankAddress].ethAddress == bankAddress,"The specified Bank does not exists.");
        bnk[bankAddress].kycPermission = false;
    }
    
    // Function to remove bank in the network
    function removeBank(address bankAddress) public _isAdmin(msg.sender) {
        assert(bankAddress != address(0));
        require(bnk[bankAddress].ethAddress == bankAddress,"The specified Bank does not exists.");
        delete(bnk[bankAddress]);
    }
    
    // Function to check if the bank is a valid admin 
    function validity(address bankAddress) private view returns(bool){
        for(uint i = 0 ; i < admins.length; i ++){
            if(admins[i] == bankAddress){
                return true;
            }
        }
        return false;
    }
    
    // Function to check if bank is already present as admin - To avoid double spending problem.
    function isPresent(address[] memory adminList ,address[] memory bank) private view returns(bool){
        for(uint256 i = 0 ; i < bank.length ; i++){
            for(uint256 j = 0 ; j < adminList.length ; j++){
                if(admins[j] == bank[i]){
                    return false;
                }
            }
        }
        return true;
    }
    
    modifier _isAdmin(address bankAddress){
        require(validity(bankAddress),"Only banks with admin priviledges can perform this operation..");
        _;
    }
    
    modifier _adminPresent(address[] memory admins ,address[] memory bankAddress){
        require(isPresent(admins,bankAddress),"One of the admin address is Duplicated please check..");
        _;
    }
    
    modifier _onlySuperAdmin {
        require(msg.sender == owner,"Only super admin can add admin banks..");
        _;
    }
}