var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "quiz large maple visual loyal rapid uniform hidden train now scene copper";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: '*'
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};
