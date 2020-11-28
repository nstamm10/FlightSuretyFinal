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
        string abbreviation;
        bool registered;
        bool authorized;
    }

   //constant M refers to number of airlines needed to use multi-party consensus


    uint private authorizedAirlines = 1;
    mapping (address => mapping(address => bool)) private multiCalls;
    address[] multiCallsArray = new address[](0);   //array of addresses that have called the registerFlight function


    mapping(address => Airline) public airlines;
    Insurance[] private insurance;
    mapping(address => uint256) private credit;

    mapping(address => uint256) private voteCounter;
    mapping(address => bool) private authorizedCallers;
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event Bought(address buyer, bytes32 flightKey, uint256 amount);
    event Creditted(bytes32 flightKey);
    event Paid(address insuree, uint256 amount);

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

    modifier isAuthorized(address airline) {
        require(airlines[airline].authorized, "Airline is not authorized");
        _;
    }

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


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus
                            (
                                bool mode
                            )
                            external
                            isAuthorized(msg.sender)
    {
        operational = mode;
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
                            )
                            external
                            view
                            requireIsOperational
    {
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
                Insurance insur = insurance[i];
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
                            )
                            public
                            payable
                            requireIsOperational
    {
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
        fund();
    }


}
