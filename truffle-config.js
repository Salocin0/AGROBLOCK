require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    polygon_testnet: {
      provider: () => new HDWalletProvider(process.env.PRIVATE_KEY, 'https://rpc-amoy.polygon.technology'), // Considera usar un RPC alternativo
      network_id: 80002, // Asegúrate de que el ID de la red sea correcto (80001 para Mumbai)
      gas: 1500000, // Aumenta el gas disponible
      gasPrice: 25000000000, // Aumenta el gas price a 60 gwei
      timeout: 10000, // Aumenta el tiempo de espera
      timeoutBlocks: 100, // Aumenta los bloques de timeout
      networkCheckTimeout: 10000, // Aumenta el tiempo de espera para verificar la red
      skipDryRun: true, // Ignora la verificación de prueba
      allowUnlimitedContractSize: true, // Permite el tamaño de contrato ilimitado
    },
  },
  compilers: {
    solc: {
      version: "0.8.28", // Mantén la versión de Solidity
      settings: {
        optimizer: {
          enabled: true,
          runs: 100, // Mantén las configuraciones del optimizador
        },
        viaIR: true,
      },
    },
  },
};
