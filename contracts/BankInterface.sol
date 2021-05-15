pragma solidity >=0.5.9 <0.9.0;

contract Bank{
    
   bool private _isAllowed;
   uint256 internal totalBanks;
   bool private voteStatus;
   bool private refresh;
   
   constructor () public {
       _isAllowed = false;
       totalBanks = 0;
       refresh = false;
   }

    struct customer {
        bytes32 username;
        bytes32 data;
        bool kycStatus;
        uint256 downVote;
        uint256 upVote;
        address bank;
    }    
    
    struct bank {
        bytes32 name;
        address ethAddress;
        uint256 report;
        uint256 kycCount;
        bool kycPermission;
        bytes32 regNumber;
    }
    
    struct kycRequest {
        bytes32 username;
        address bankAddress;
        bytes32 customerData;
        uint256 downVote;
        uint256 upVote;
    }
    
    
    mapping(address => bank) internal bnk;
    
    // customer_name => kycRequest
    /*
    Basic assumption that a user will have max of 5 accounts , this is only to avoid dynamic sized array in the code..
    */
    mapping(bytes32 => kycRequest[5]) private requestList;
    
    mapping (bytes32 => customer) private customerList;
    
    // Variable to keep track of bank that is already voted..
    mapping (bytes32 => address) private votes;
    
    // Variable to keep track of bank that has reported another bank..
    mapping (address => address) private reporters;
    
    /*************************************************************************************************************
    Methods for bank use only...
    *************************************************************************************************************/
    
    // Function to add customer to the global customer list

    function addCustomer(bytes32 name, bytes32 data) public _isAbsent(name,data) _validateCustomer(name) {
        //require(_isAllowed == true,"kyc request for the customer is not approved..");
        customerList[name] = customer({
            username: name,
            data: data,
            kycStatus: true,
            upVote: 0,
            downVote: 0,
            bank: msg.sender
        });
    }
    
    // Function to remove a customer from global customer list
    function removeCustomer(bytes32 name) public {
        
        //Remove the customer from the request list if present.
        for(uint256 i = 0 ; i < requestList[name].length; i++){
            if(requestList[name][i].username == name && requestList[name][i].bankAddress == msg.sender){
                removeRequest(name,customerList[name].data);
            }else if(customerList[name].username == name && customerList[name].bank == msg.sender){
                // Remove the customer from the global customer list
                delete(customerList[name]);
            }
        }
        
        // Removing the bank from votes list, to cast revote on user.
        if(votes[name] == msg.sender){
            delete(votes[name]);
        }
    }
    
    // Function to modify existing customer
    function modifyCustomer(bytes32 name, bytes32 data) public _isPresentInCustomerList(name) {
        
        // remove the customer from request list
        removeRequest(name,data);
        
        customerList[name] = customer({
            username: name,
            data: data,
            bank: msg.sender,
            downVote: 0,
            upVote: 0,
            kycStatus: false
        });
        
        // Removing the bank from votes list, to cast revote on updated data.
        if(votes[name] == msg.sender){
            delete(votes[name]);
        }
    }
    
    // Function to view customer data
    function viewCustomer(bytes32 name) view public _isPresentInCustomerList(name) returns (bytes32){
        return customerList[name].data;
    }
    
    // Function to upvote a customer kyc ( only valid banks can perform this )
    function upVote(bytes32 name) public _customerPresent(name) _alreadyVoted(msg.sender,name) _isBank(msg.sender){
        for(uint256 i = 0 ; i < requestList[name].length; i++){
            if(requestList[name][i].username == name){
                requestList[name][i].upVote++;
            }
            if(customerList[name].username == name){
                customerList[name].upVote++;
            }
        }
        votes[name] = msg.sender;
    }
    
    // Function to downvote a customer kyc ( only valid banks can perform this )
    function downVote(bytes32 name) public _customerPresent(name) _alreadyVoted(msg.sender,name) _isBank(msg.sender) {
        for(uint256 i = 0 ; i < requestList[name].length; i++){
            if(requestList[name][i].username == name){
                requestList[name][i].downVote++;
            }
        }
        if(customerList[name].username == name){
            customerList[name].downVote++;    
        }
        votes[name] = msg.sender;
        // Check if more than 1/3rd of the banks have downVoted this customer
        if(customerList[name].downVote > (totalBanks/3)){
            customerList[name].kycStatus = false;
        }
    }
    
    // Function to get bank details
    function getBankDetails(address bankAddress) view public _isBank(bankAddress) returns(address){
        assert(bankAddress != address(0));
        return bnk[bankAddress].ethAddress;
    }
    
    // Function to get get a bank report
    function getBankReport(address bankAddress) view public _isBank(bankAddress) returns(uint256) {
        assert(bankAddress != address(0));
        return bnk[bankAddress].report;
    }
    
    // Report a bank to be corrupt.
    function reportBank(address bankAddress) public _isBank(bankAddress) _canReport(bankAddress) {
        bnk[bankAddress].report++;
        
        // Check if more than 1/3rd of the banks in the network is voting against this bank..
        if(bnk[bankAddress].report > (totalBanks/3)){
            bnk[bankAddress].kycPermission = false;
        }
        
        // reporting_bank_address = reported_bank_address
        reporters[msg.sender] = bankAddress;
    }
    
    
    /*
    Function to check if the customer is valid/invalid and performs the following.
        1. Sets flag IsAllowed to true for Add Customer for valid customer
        2. Calls Remove Customer and removes kyc request from the list for invalid cusomer.
    */
    function isValidCustomer(bytes32 name) private returns(bool){
        // CustomerList
        if(customerList[name].username == name){
            if(customerList[name].downVote > (totalBanks/3)){
                customerList[name].kycStatus = false;
                return false;
            }else if(customerList[name].upVote > customerList[name].downVote) {
                _isAllowed = true;
                return true;
            }
        }
        // RequestList
        for(uint256 i = 0 ; i < requestList[name].length; i++){
            if(requestList[name][i].username == name){
                if(requestList[name][i].downVote > (totalBanks/3)){
                    return false;
                }else if(requestList[name][i].upVote > requestList[name][i].downVote) {
                    _isAllowed = true;
                    return true;
                }            
            }
        }
    }
    
    // To avoid double spending problemn..
    function voted(address bankAddress,bytes32 name) private view returns(bool){
        if(votes[name] == bankAddress){
            return true;
        }else{
            return false;
        }
    }
    
    /**********************************************************************************************************************************
    Methods for Kyc Process
    ******************************************************************************************************************************/
    
    // Function to add request to request list
    function addRequest(bytes32 name, bytes32 data) public {
        require(bnk[msg.sender].kycPermission == true && bnk[msg.sender].report < (totalBanks/3),"This bank is not allowed to process the kyc request.");
        for(uint256 i = 0 ; i < requestList[name].length; i++){
            require(requestList[name][i].customerData != data,"The kyc request containing the same data already exists , kindly check its current status..");
            requestList[name][i] = kycRequest({
                username: name,
                customerData: data,
                bankAddress: msg.sender,
                upVote: 0,
                downVote: 0
            });
        }
    }
    
    // Returns kyc status from global customer list.
    function getCustomerStatus(bytes32 name) public view _isPresentInCustomerList(name) returns (bool) {
        return customerList[name].kycStatus;
    }
    
    /* This function is called when:
        1. Customer kyc is successfull and Customer is added to global customer list.
        2. Remove customer from requestList if present.
        3. Remove the customer - Invalidating a customer
    */
    function removeRequest(bytes32 name,bytes32 data) internal _isPresentInRequestList(name){
        for(uint256 i = 0 ; i < requestList[name].length; i++){
            if (requestList[name][i].username == name){
                delete(requestList[name][i]);
            }
        }
    }    
    
    // Modifiers
    
    //To check if the user is present 
    modifier _isPresentInCustomerList(bytes32 name) {
        require(customerList[name].username == name,"There is no such user present");
        _;
    }
    
    
    //To check if the user is present 
    modifier _isPresentInRequestList(bytes32 name) {
        for(uint256 i = 0 ; i < requestList[name].length; i++){
            require(requestList[name][i].username == name,"Kyc request for this user is not present");
        }
        _;
    }
    
    
    //To check if the user is present 
    modifier _customerPresent(bytes32 name) {
        for(uint256 i = 0 ; i < requestList[name].length; i++){
            require(requestList[name][i].username == name || customerList[name].username == name,"Kyc request for this user is not present");
        }
        _;
    }    
    
    // To check if the user is absent 
    modifier _isAbsent(bytes32 name,bytes32 data) {
        require(customerList[name].data != data,"Customer with same data already exists");
        _;
    }
    
    // To check the autheticity for removing a customer.
    modifier _isOwner(bytes32 name) {
        require(customerList[name].bank == msg.sender ,"Looks like the customer is not added to global customer kycStatus = false list or only the bank that added this customer has the permission to remove.." );
        _;
    }
    
    // To check if the bank exisits.
    modifier _isBank(address bankAddress) {
        require(bnk[bankAddress].ethAddress == bankAddress,"The specified Bank does not exists.");
        _;
    }
    
    modifier _validateCustomer(bytes32 name) {
        require(isValidCustomer(name),"kyc request for the customer is not approved... kycStatus = false");
        _;
    }
    
    modifier _alreadyVoted(address bankAddress,bytes32 name){
        require(votes[name] != bankAddress,"This bank has already voted for the customer..");
        _;
    }
    
    modifier _canReport(address bankAdress) {
        require(reporters[bankAdress] != msg.sender, "This bank has already voted for the bank");
        _;
    }
}