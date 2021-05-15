# Banking-kyc
An Ethereum based Blockchain solution for kyc process.

### Private Network setup

Installation of geth : https://geth.ethereum.org/docs/install-and-build/installing-geth

Setting up private network using geth:
1. geth --datadir ./datadir init ./genesis.json (In the KYC-Blockchain directory)
2. geth --datadir ./datadir --networkid 9986944 --rpc --allow-insecure-unlock console
3. personal.newAccount('password')
4. personal.newAccount('password')
5. personal.newAccount('password')
6. personal.unlockAccount(‘Address of 1st Account’, ‘password of the account’, 0)
7. miner.start()

Installation of truffle : https://www.trufflesuite.com/docs/truffle/getting-started/installation

Setting up truffle framework to interact with geth network:
1. truffle init
2. truffle compile
3. truffle migrate --network development
4. truffle console --network development
5. let kyc = await KYC.deployed()

### Contract details:

1. KYC.sol - Contract contains code for admin functionalities and inherits BankInterface.sol
2. BankInterface.sol - Contract contains code for bank,customer and kyc functionalities.

Important:
1. There should be min of 3 banks to ensure 1/3rd quorum in the network.
2. Static sized array kycRequest[5] = Assuming that the user might not have more than 5 accounts ( to avoid consuming more gas )
    Array of Value:
    Eg : ['0x5B38Da6a701c568545dCfcB03FcB875f56beddC4','0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2','0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db']
3. To upvote     =  Customer is checked in request list and not customer list
4. To downvote   = Customer is checked in customer list and not request list
5. constructor():
    1. In BankInterface.sol sets the following:
        _isAllowed = false;
        totalBanks = 0;
        refresh = false;
    2. In Kyc.sol sets : first account that initiates the transaction as super admin.

### Control Flow:

1. The first address that initiates a transaction will become the super admin.
2. Only super admin can add other bank as admins ( Assuming that in a network there will be multiple admins based on the requirement) , hence added this feature.
3. addAdmins()          - To add admins.
4. addBank()            - To add banks to the network.
5. getBankDetails()     - Function used get banks unique address.
6. addRequest()         - To add customers kyc request ( name and data )
7. upVote()             - Functionality that depicts a bank validates the data and upvote stating the customer data is valid.
8. downVote()           - Functionality that depicts a bank validates the data and downvote stating the customer data is invalid.
9. addCustomer()        - To add customer to global customer list post authenticity of the customer is met.
10. getCustomerStatus() - Used to get customer kyc status , This works only when user is added to global customer list.
11. viewCustomer()      - Get the data of the customer added to global customer list
10. modifyCustomer()    - Function used when when customer wants to update this data.
11. removeCustomer()    - Function used to remove a customer from global customer list and also from request list if present.
12. reportBank()        - Function used by other banks to report against bank incase of malicious activities found.
13. getBankReport()     - Function used to get number of banks that have reported against it.
14. modifyBank()        - Only Admin user can perform this activity to set kycPermission of bank to false incase the bank is reported as malicious by 1/3rd of the network
15. removeBank()        - Function used only by admin to remove bank if the number of reports against is greater than 1/3rd nodes in the network

#### NOTE: 
1. Double spending problems are taken care like:
    1. Adding already existing bank as admin.
    2. Ensuring that a bank cannot vote twice for the same customers data.

