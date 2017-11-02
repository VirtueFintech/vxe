module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    live: {
      host: "localhost",
      port: 8545,
      network_id: "1" // live net
    },
    ropsten: {
      host: "https://ropsten.infura.io",
      port: 8545,
      network_id: "3" // ropsten net
    }
  }
};
