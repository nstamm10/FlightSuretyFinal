
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
//const TruffleAssert = require('../node_modules/truffle-assertions/index.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    //await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);

  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  //THIS WORKS GREAT
  it( 'check that default airline has registered correctly upon deployment of contracts', async function() {

    //get field of default airline at address config.firstAirline
    const firstAirline = config.firstAirline;

    let nameDefault = await config.flightSuretyApp.getAirlineName(firstAirline);
    let accountDefault = await config.flightSuretyApp.getAirlineAccount(firstAirline);
    let isRegisteredDefault = await config.flightSuretyApp.getRegistrationStatus(firstAirline);
    let isAuthorizedDefault = await config.flightSuretyApp.getAuthorizationStatus(firstAirline);
    let operationalVoteDefault = await config.flightSuretyApp.getOperationalVote(firstAirline);


    assert.equal(nameDefault, "Default Name", "Incorrect name of default airline");
    assert.equal(accountDefault, firstAirline, "Incorrect account of default airline");
    assert.equal(isRegisteredDefault, true, "Incorrect registration status of default airline");
    assert.equal(isAuthorizedDefault, true, "Incorrect authorization status of default airline");
    assert.equal(operationalVoteDefault, true, "Incorrect operational vote of default airline");
/*
    //assign new airline address
    let americanAirline = accounts[2];
    //register an Airline and check that this function worked correctly
    await config.flightSuretyApp.registerAirline.sendTransaction("American Airlines", americanAirline, firstAirline, {from: firstAirline});

    //check all 5 fields of new airline
    let name = await config.flightSuretyApp.getAirlineName(americanAirline);
    let account = await config.flightSuretyApp.getAirlineAccount(americanAirline);
    let isRegistered = await config.flightSuretyApp.getRegistrationStatus(americanAirline);
    let isAuthorized = await config.flightSuretyApp.getAuthorizationStatus(americanAirline);
    let operationalVote = await config.flightSuretyApp.getOperationalVote(americanAirline);
    let list = await config.flightSuretyApp.getAuthorizedAirlineCount();

    assert.equal(name, "American Airlines", name.toString());
    assert.equal(account, americanAirline, "Incorrect account of registered airline 1");
    assert.equal(isRegistered, true, "Incorrect registration status of registered airline 1");
    assert.equal(isAuthorized, false, "Incorrect authorization status of registered airline 1");
    assert.equal(operationalVote, true, "Incorrect operational vote of registered airline 1");
    assert.equal(list.toString() === "1", true, "Incorrect authorized airline count of ${list}");

    await config.flightSuretyApp.fund.sendTransaction({from: firstAirline, value: 1000000000000000000 });
*/

  });





  //THIS WORKS GREAT
  it( 'correct initial isOperational() value', async function() {

    //get operating status
    let status = await config.flightSuretyApp.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");
  });

  it('setOperatingStatus requires authorizedAirline to call function', async function() {



  });

  it('register an airline and check if fields register correctly', async function() {

    //assign airline vairables
    const americanAirline = accounts[3];
    const firstAirline = config.firstAirline; // should be already authorized as a participating airline

    //This should work and return true, 1, 1
    await config.flightSuretyApp.registerAirline.sendTransaction("American Airlines", americanAirline, firstAirline, {from: firstAirline});

    //check all 5 fields of new airline
    let name = await config.flightSuretyApp.getAirlineName(americanAirline);
    let account = await config.flightSuretyApp.getAirlineAccount(americanAirline);
    let isRegistered = await config.flightSuretyApp.getRegistrationStatus(americanAirline);
    let isAuthorized = await config.flightSuretyApp.getAuthorizationStatus(americanAirline);
    let operationalVote = await config.flightSuretyApp.getOperationalVote(americanAirline);
    let list = await config.flightSuretyApp.getAuthorizedAirlineCount();

    assert.equal(name, "American Airlines", name.toString());
    assert.equal(account, americanAirline, "Incorrect account of registered airline 1");
    assert.equal(isRegistered, true, "Incorrect registration status of registered airline 1");
    assert.equal(isAuthorized, false, "Incorrect authorization status of registered airline 1");
    assert.equal(operationalVote, true, "Incorrect operational vote of registered airline 1");
    assert.equal(list.toString() === "1", true, "Incorrect authorized airline count of ${list}");

    //check that registerAirline function is returning the correct three fields for this particular case -- NOT WORKING YET
    //assert.equal(register[0], true, register);
    //assert.equal(register[1].toString() === "1", true, "Incorrect number of Authorized Airlines");
    //assert.equal(register[2].toString() === "1", true, "Incorrect number of votes");

  });


  it('americanAirline "American Airlines" can be funded using fund() function', async function() {
    //check that registerAirline function is returning the correct three fields for this particular case
    //assert.equal(register, true, register);
    //assert.equal(register[1].toString() === "1", true, "Incorrect number of Authorized Airlines");
    //assert.equal(register[2].toString() === "1", true, "Incorrect number of votes");


    let americanAirline = accounts[3];
    let firstAirline = config.firstAirline; // should be already authorized as a participating airline


    //call the fund transaction from both firstAirline which is already authorized and from americanAirline which is registered but not authorized
    await config.flightSuretyApp.fund.sendTransaction(firstAirline, {from: firstAirline, value: 10 }); //use to field
  //  await config.flightSuretyApp.fund.sendTransaction({from: americanAirline, "value": 10 });

    //American Airline should now be authorized
    let isAuthorized = await config.flightSuretyApp.getAuthorizationStatus(americanAirline);
    assert.equal(isAuthorized, true, "Incorrect authorization status of registered airline 1");

  });





  it( 'isOperational function returns default isOperational() value', async function() {

    //get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");
  });

  it('consumer can buy insurance', async function() {
      let flight = 'United flight 280';
      let consumer = accounts[1];
      let buyAmount = 500000000000000000;
      let airline = accounts[2];
      let time = Date.now()

      let buy = await config.flightSuretyData.buy(airline, flight, time, buyAmount.toString(), {from: consumer, value: buyAmount.toString()});

      //TruffleAssert.eventEmitted(buy, 'Bought');

  });

  it('americanAirline "American Airlines" can be funded using fund() function', async function() {

    let americanAirline = accounts[3];
    let firstAirline = config.firstAirline; // should be already authorized as a participating airline


    //call the fund transaction from both firstAirline which is already authorized and from americanAirline which is registered but not authorized
    await config.flightSuretyApp.fund.sendTransaction(firstAirline, {
                                                      "from": firstAirline,
                                                      "value": 10000000000000000000,
                                                      "gas":4712388,
                                                      "gasPrice":100000000000}); //use to field
  //  await config.flightSuretyApp.fund.sendTransaction({from: americanAirline, "value": 10 });

    //American Airline should now be authorized
    let isAuthorized = await config.flightSuretyApp.getAuthorizationStatus(americanAirline);
    assert.equal(isAuthorized, true, "Incorrect authorization status of registered airline 1");

  });

  it('setOperatingStatus requires authorizedAirline to call function', async function() {



  });

  it('setOperatingStatus can change operating status to desired mode IF less than 4 authorized Airlines', async function() {



  });

  it('setOperatingStatus will change operating status to false IF 50% consensus is reached for 4 or more authorized Airlines', async function() {

    //register 5 airlines

    //call change operating status 3 times for three different planes

    //assert should indicate that first two times, operational variable does not change
    //assert should indicate that the third time, operational variable should change to false
    //also, changeOperatingStatusVotes variable should go to two (two votes for true now)


  });

  it('setOperatingStatus will change operating status back to true in the same scenario as above', async function() {

    //call change operating status 1 time for airline that had previously set vote to false

    //assert should indicate that operational variable should change back to false
    //also, changeOperatingStatusVotes variable should go back to two (two votes for false now)

    //call change operaing status on other two airlines set to false and make sure changeOperatingStatusVotes
    //lines up as it should  -- this could be a bug here
    //do I need line 129?
    //how do i make sure the variable changeOperatingStatus works as intended


  });

  it('setOperatingStatus will reject duplicate callers', async function() {

    //assert that operating status is currently set to true
    //check operating stauts field of all airlines so that they are set to true

    //call change operating status -- should work but operational variable should not change
    //assert should not change

    //call change operating status(false) again with the same airline
    //assert should reject

  });




});
