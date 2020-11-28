
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
//    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/
  it( 'isOperational function returns default isOperational() value', async function() {

    //get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");
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


/*
  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");

  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");

  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {

    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(newAirline);

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });


});
*/
