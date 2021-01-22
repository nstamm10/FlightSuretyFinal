pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                    // Account used to deploy contract
    bool private operational = true;                 // Blocks all state changes throughout the contract if false

    struct Insurance {
        address owner;
        bytes32 key;
        uint256 amount;
    }

    struct Airline {  //Struct to classify an airline and hold relevant info
        string name;
        address account;
        bool isRegistered;
        bool isAuthorized;
        bool operationalVote;

    }


   //constant M refers to number of airlines needed to use multi-party consensus
    uint256 private changeOperatingStatusVotes = 0;


    uint statusVotes;
    uint256 private authorizedAirlineCount = 0;
    mapping (address => mapping(address => uint8)) private multiCalls;
    address[] multiCallsArray = new address[](0);   //array of addresses that have called the registerFlight function

    mapping(address => uint256) funds;                // Mapping to store the funds contributed by the airline. The minnimum contribution to get authorized is 10 ether
    mapping(address => Airline) public airlines;      // Mapping for storing employees. Question: Does this contract have to inheret from the app contract in order to use a mapping that maps to an Airline type? (airline type is stored in the app contract, maybe this will have to change)
    mapping(address => uint256) private authorizedAirlines;   // Mapping for airlines authorized
    mapping(address => uint8) authorizedCaller; //mapping that stores the app contract addresses that
                                                //are authorized to call the data contract. If authorized, the mapping[address]
                                                //should equal 1

    Insurance[] private insurance;
    mapping(address => uint256) private credit;
    mapping(address => uint256) private voteCounter;

    mapping(address => bool) private authorizedCallers;
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event AuthorizedCaller(address caller);
    event DeAuthorizedCaller(address caller);

    event Bought(address buyer, bytes32 flightKey, uint256 amount);
    event Creditted(bytes32 flightKey);
    event Paid(address insuree, uint256 amount);


    /**
    * Event fired when a new Airline is registered
    * "indexed" keyword indicates that the data should be stored as a "topic" in event log data. This makes it
    * searchable by event log filters. A maximum of three parameters may use the indexed keyword per event.
    */
    event RegisterAirline(address indexed account);
    event AuthorizeAirline(address account);


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                )
                                public
    {
        contractOwner = msg.sender;

        airlines[contractOwner] = Airline({
                    name: "Default Name",
                    account: contractOwner,
                    isRegistered: true,
                    isAuthorized: true,
                    operationalVote: true
                    });

        authorizedAirlineCount = authorizedAirlineCount.add(1);

        emit RegisterAirline(contractOwner);

    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational()
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireIsCallerAuthorized(address admin) {
        require(airlines[admin].isAuthorized, "Airline is not authorized");

        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/


        /* authorize caller */
    function authorizeCaller(address _caller) public onlyOwner returns(bool)
    {
        authorizedCaller[_caller] = 1;
        emit AuthorizedCaller(_caller);
        return true;
    }


    /* deauthorize caller */
    function deAuthorizeCaller(address _caller) public onlyOwner returns(bool)
    {
        authorizedCaller[_caller] = 0;
        emit DeAuthorizedCaller(_caller);
        return true;
    }
    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational()
                            public
                            view
                            returns(bool)
    {
        return operational;
    }

    //getters for fields of the Airline struct -- don


    function getAirlineName(address account) external view returns(string){
        return airlines[account].name;
    }
    function getAuthorizedAirlineCount() external view returns(uint256) {
        return authorizedAirlineCount;
    }
    function getAirlineAccount(address account) external view returns(address){
        return airlines[account].account;
    }
    function getRegistrationStatus(address account) external view returns(bool){
        return airlines[account].isRegistered;
    }
    function getAuthorizationStatus(address account) external view returns(bool){
        return airlines[account].isAuthorized;
    }
    function getOperationalVote(address account) external view returns(bool){
        return airlines[account].operationalVote;
    }



    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus
                            (
                                bool mode,
                                address caller
                            )
                            external

                            requireIsCallerAuthorized(caller)

                            requireContractOwner


    {
        require(operational == airlines[caller].operationalVote, "Duplicate caller");
        require(mode!=operational, "New mode must be different from existing mode");


        if (authorizedAirlineCount < 4) {
          operational = mode;
        } else { //use multi-party consensus amount authorized airlines to reach 50% aggreement
          changeOperatingStatusVotes = changeOperatingStatusVotes.add(1);
          airlines[caller].operationalVote = mode;
          if (changeOperatingStatusVotes >= (authorizedAirlineCount.div(2))) {
            operational = mode;
            changeOperatingStatusVotes = authorizedAirlineCount - changeOperatingStatusVotes;
          }
        }

    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function registerAirline
                            (
                              string name,
                              address newAirline,
                              address admin
                            )
                            external
                            requireIsOperational
                            requireIsCallerAuthorized(admin)
                            returns
                            (
                                bool success,
                                uint256 authorizedAirlineNumber,
                                uint256 votes
                            )

    {
      require(!airlines[newAirline].isRegistered, "New Airline is already registered");
      require(airlines[admin].isRegistered, "Admin Airline is not registered");

      if (authorizedAirlineCount < 4) {
        airlines[newAirline] = Airline({
                    name: name,
                    account: newAirline,
                    isRegistered: true,
                    isAuthorized: false,
                    operationalVote: true
                    });
        emit RegisterAirline(newAirline);
        return(true, authorizedAirlineCount, 1);
      } else { //multiparty consensus
        bool isDuplicate = false;
        //better to use an owner parameter than msg.sender here?
        if (multiCalls[newAirline][admin] == 1) {
          isDuplicate = true;
        }

        require(!isDuplicate, "Caller has already called this function");
        multiCalls[newAirline][admin] = 1;
        voteCounter[newAirline] = voteCounter[newAirline].add(1);

        if (voteCounter[newAirline] >= (authorizedAirlineCount.div(2))) {
          airlines[newAirline] = Airline({
                      name: name,
                      account: newAirline,
                      isRegistered: true,
                      isAuthorized: true,
                      operationalVote: true
                      });

          emit RegisterAirline(newAirline);

          return(true, authorizedAirlineCount, voteCounter[newAirline]);
        } else {
          return(false, authorizedAirlineCount, voteCounter[newAirline]);
        }

      }

    }
    /**
    * @dev Buy insurance for a flight
    */
    function buy (address airline, string flight, uint256 timestamp, uint256 amount) external payable requireIsOperational {
        require(msg.value == amount, "Transaction is suspect");
        uint256 newAmount = amount;
        if (amount > 1 ether) {
            uint256 creditAmount = amount - 1;
            newAmount = 1;
            credit[msg.sender] = creditAmount;
        }
        bytes32 key = getFlightKey(airline, flight, timestamp);
        Insurance memory newInsurance = Insurance(msg.sender, key, newAmount);
        insurance.push(newInsurance);
        emit Bought(msg.sender, key, amount);
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees (address airline, string flight, uint256 timestamp) external view requireIsOperational {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        for (uint i=0; i < insurance.length; i++) {
            if (insurance[i].key == flightKey) {
                credit[insurance[i].owner] = insurance[i].amount.mul(15).div(10);
                Insurance memory insur = insurance[i];
                insurance[i] = insurance[insurance.length - 1];
                insurance[insurance.length - 1] = insur;
                delete insurance[insurance.length - 1];
                insurance.length--;
            }
        }
        emit Creditted(flightKey);
    }
    /**
     *  @dev Transfers eligible payout funds to insuree

     */

    function pay () external payable requireIsOperational {
        require(credit[msg.sender] > 0, "Caller does not have any credit");
        uint256 amountToReturn = credit[msg.sender];
        credit[msg.sender] = 0;
        msg.sender.transfer(amountToReturn);
        emit Paid(msg.sender, amountToReturn);

    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund
                            (
                              address sender
                            )
                            public
                            payable
                            requireIsOperational

    {
        require(msg.value >= 10 ether, "Inadaquate funds");
        require(airlines[sender].isRegistered, "Sending account must be registered before it can be funded");


        uint256 existingAmount = funds[sender];
        uint256 totalAmount = existingAmount.add(msg.value);
        funds[sender] = 0;
        sender.transfer(msg.value); //their code has the totalAmount being transferred to the contract account. Why?

        if (airlines[sender].isAuthorized == false) {
            airlines[sender].isAuthorized = true;
            authorizedAirlineCount = authorizedAirlineCount.add(1);
            emit AuthorizeAirline(sender);
        }
        funds[sender] = totalAmount;


    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        view
                        internal
                        requireIsOperational
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function()
                            external
                            payable
                            requireIsOperational
    {
        fund(msg.sender);
    }


}
