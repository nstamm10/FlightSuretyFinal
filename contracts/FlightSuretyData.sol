pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                    // Account used to deploy contract
    bool private operational = true;                 // Blocks all state changes throughout the contract if false

    uint private funds;

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


    mapping(address => Airline) public airlines;      // Mapping for storing employees. Question: Does this contract have to inheret from the app contract in order to use a mapping that maps to an Airline type? (airline type is stored in the app contract, maybe this will have to change)
    mapping(address => uint256) private authorizedAirlines;   // Mapping for airlines authorized
    Insurance[] private insurance;
    mapping(address => uint256) private credit;

    mapping(address => uint256) private voteCounter;

    mapping(address => bool) private authorizedCallers;
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
    * Event fired when a new Airline is registered
    * "indexed" keyword indicates that the data should be stored as a "topic" in event log data. This makes it
    * searchable by event log filters. A maximum of three parameters may use the indexed keyword per event.
    */
    event RegisterAirline(address indexed account);

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

    //modifier isAuthorized(Airline air) {
        //require(air.authorized);
    //}

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

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

    function getAirlineName(address account) public view returns(string){
        return airlines[account].name;
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
                            requireContractOwner
                            //isAuthorized
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
                              address caller
                            )
                            external
                            //isAuthorized(caller)
                            returns
                            (
                                bool success,
                                uint256 authorizedAirlineNumber,
                                uint256 votes
                            )
    {
      if (authorizedAirlineCount < 4) {
        airlines[newAirline] = Airline({
                    name: name,
                    account: newAirline,
                    isRegistered: true,
                    isAuthorized: true,
                    operationalVote: true
                    });

        emit RegisterAirline(newAirline);
        return(true, authorizedAirlineCount, 1);
      } else { //multiparty consensus
        bool isDuplicate = false;
        //better to use an owner parameter than msg.sender here?
        if (multiCalls[newAirline][caller] == 1) {
          isDuplicate = true;
        }

        require(!isDuplicate, "Caller has already called this function");
        multiCalls[newAirline][caller] = 1;
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
    *
    */
    function buy
                            (
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund
                            (
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
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
    {
        fund();
    }


}
