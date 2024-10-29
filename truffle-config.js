require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    polygon_testnet: {
      provider: () => new HDWalletProvider(process.env.PRIVATE_KEY, 'https://rpc-amoy.polygon.technology/'),
      network_id: 80002,
      gas: 30000000,
      gasPrice: 25000000000,
      timeout:600000
    },
  },
  compilers: {
    solc: {
      version: "0.8.26",
    },
  },
};
