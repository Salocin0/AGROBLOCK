require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    polygon_testnet: {
      provider: () => new HDWalletProvider(process.env.PRIVATE_KEY, 'https://rpc-amoy.polygon.technology'),
      network_id: 80002,
      gas: 6000000,
      gasPrice: 60000000000,
      timeout: 10000,
      timeoutBlocks: 200,
      networkCheckTimeout: 100000,
      allowUnlimitedContractSize: true,
      confirmations: 2,
      skipDryRun: true,
    },
  },
  compilers: {
    solc: {
      version: "0.8.28",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        viaIR: true,
      },
    },
  },
  plugins: ["truffle-plugin-verify"],
  api_keys: {
    polygonscan: process.env.POLYGONSCAN_API,
  },
};
