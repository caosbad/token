var Airdrop = artifacts.require("Airdrop");
var privateSale = artifacts.require("privateSale");
var publicSale = artifacts.require("publicSale");
var Token = artifacts.require("Token");
var Vesting = artifacts.require("Vesting");
var Whitelisting = artifacts.require("Whitelisting");

module.exports = function(deployer) {
    // 5M hodl premium cap - 25% of 20M tokens in crowdsale
    deployer.deploy(Token, "0x46e7d71c5101956c26ed66f520c86c455d24b7a4", "0x46e7d71c5101956c26ed66f520c86c455d24b7a4", "0", "5000000000000000000000000").then(function() {
        return deployer.deploy(Whitelisting).then(function () {
            return deployer.deploy(Vesting, Token.address).then(function () {
                //Epoch timestamp: 1552917600
                // Timestamp in milliseconds: 1552917600000
                // Human time (GMT): Monday, March 18, 2019 2:00:00 PM
                // Human time (your time zone): Monday, March 18, 2019 3:00:00 PM GMT+01:00
                //Epoch timestamp: 1553090400
                // Timestamp in milliseconds: 1553090400000
                // Human time (GMT): Wednesday, March 20, 2019 2:00:00 PM
                // Human time (your time zone): Wednesday, March 20, 2019 3:00:00 PM GMT+01:00
                //Epoch timestamp: 1553263200
                // Timestamp in milliseconds: 1553263200000
                // Human time (GMT): Friday, March 22, 2019 2:00:00 PM
                // Human time (your time zone): Friday, March 22, 2019 3:00:00 PM GMT+01:00
                //
                //
                //

                return deployer.deploy(privateSale, 1552917600, 1553090400, "0x46e7d71c5101956c26ed66f520c86c455d24b7a4", Whitelisting.address, Token.address, Vesting.address, 1553263200, "0", "5000000000000000000000000", "26750000000000000000000").then(function () {
                    //Epoch timestamp: 1553608800
                    // Timestamp in milliseconds: 1553608800000
                    // Human time (GMT): Tuesday, March 26, 2019 2:00:00 PM
                    // Human time (your time zone): Tuesday, March 26, 2019 3:00:00 PM GMT+01:00
                    //
                    //Epoch timestamp: 1553781600
                    // Timestamp in milliseconds: 1553781600000
                    // Human time (GMT): Thursday, March 28, 2019 2:00:00 PM
                    // Human time (your time zone): Thursday, March 28, 2019 3:00:00 PM GMT+01:00

                    return deployer.deploy(publicSale, 1553090400, 1553608800, "0x46e7d71c5101956c26ed66f520c86c455d24b7a4", Whitelisting.address, Token.address, Vesting.address, 1553781600, "0", "20000000000000000000000000", "104000000000000000000000");
                });
            });
        });
    });
};

