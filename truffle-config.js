const HDWalletProvider = require('truffle-hdwallet-provider');
const { mnemonic, BSCSCANAPIKEY} = require('./secrets.json');


module.exports = {
  api_keys: {
    bscscan: BSCSCANAPIKEY
  },
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    testnet: {
     provider: function () {
       return new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s2.binance.org:8545/`)
     },
      network_id: 97,
      confirmations: 5,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    bsc: {
      provider: () => new HDWalletProvider(mnemonic, `https://bsc-dataseed1.binance.org`),
      network_id: 56,
      confirmations: 5,
      timeoutBlocks: 200,
      skipDryRun: true
    },
  },
  compilers: {
    solc: {
      version: "0.6.12",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200   // Optimize for how many times you intend to run the code
        },
        evmVersion: 'istanbul'
      }
    }    
  }
};