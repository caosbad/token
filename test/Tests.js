const BigNumber = web3.BigNumber;

var Airdrop = artifacts.require("Airdrop");
var privateSale = artifacts.require("privateSale");
var publicSale = artifacts.require("publicSale");
var Token = artifacts.require("Token");
var Vesting = artifacts.require("Vesting");
var Whitelisting = artifacts.require("Whitelisting");

async function assertRevert(promise) {
    try {
        await promise;
        assert.fail('Expected revert not received');
    } catch (error) {
        const revertFound = error.message.search('revert') >= 0;
        assert(revertFound, `Expected "revert", got ${error} instead`);
    }
};

const promisify = (inner) =>
    new Promise((resolve, reject) =>
        inner((err, res) => {
            if (err) { reject(err) }
            resolve(res);
        })
    );

const getBalance = (account, at) =>
    promisify(cb => web3.eth.getBalance(account, at, cb));


const increaseTime = function(duration) {
    const ids = Date.now()

    web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [duration], id: ids}, function(){});
}

contract('PrivateSale', function(accounts) {
   it("shall receive ehters in the vault", async function(){
       let token = await Token.new(accounts[1], accounts[1], 0, "5000000000000000000000000" );
       let whitelisting = await Whitelisting.new();
       let vesting = await Vesting.new(token.address);
       let now = Math.floor(Date.now()/1000);
       console.log(now);
       await whitelisting.approveInvestorPayment(accounts[2]);
       let privsale = await privateSale.new( now + 1000, now+10000, accounts[1], whitelisting.address, token.address, vesting.address, now+11000, "0", "5000000000000000000000000", "26750000000000000000000");
       increaseTime(2000);
       console.log(await getBalance(accounts[2]));

       await privsale.send("10000000000000000000", {from: accounts[2], gas: 1000000 }, function(){});
       console.log(await getBalance(accounts[2]));

       increaseTime(10000);

       console.log(await getBalance(accounts[1]));

       await privsale.closeRefunds();

       console.log(await getBalance(accounts[1]));

   });
});

/*contract('TokenTest', function(accounts) {
    it("Shall create token contract and transfer 100000000000000000000000 tokens to other user", async function() {
        let token = await Token.new(accounts[1], accounts[1], 0, "5000000000000000000000000" );
        let testtoken = await TestToken.new("5000000000000000000000000",{from: accounts[1]} );

        await token.setTokenInformation("LITION", "LIT");
        await token.setRefundSignupDetails("1550000000", "1553293200", testtoken.address, accounts[1]);
        await token.mint( accounts[2], "1000000000000000000000000");
        await token.sethodlPremium( accounts[2], "1000000000000000000000000", 1553260000 );
        await token.signUpForRefund( "600000000000000000000000", {from: accounts[2]});
        await token.signUpForRefund( "500000000000000000000000", {from: accounts[2]});

        //
        // console.log("AAAA " + (await token.hodlPremium(accounts[2])).buybackTokens );
        // if( ! (((await token.hodlPremium(accounts[2])).hodlTokens) == 0) )
        //     throw new Error("hodlTokens not equal 0");
        //
        // if( ! (((await token.hodlPremium(accounts[2])).buybackTokens).equals("1000000000000000000000000")) )
        //     throw new Error("buybackTokens not equal 0");

        await token.mint( accounts[3], "1000000000000000000000000");
        await token.sethodlPremium( accounts[3], "1000000000000000000000000", 1553260000 );

        await token.mint( accounts[4], "1000000000000000000000000");
        await assertRevert(token.signUpForRefund( "600000000000000000000000", {from: accounts[4]}));

        await token.transfer( accounts[4], "800000000000000000000000", {from: accounts[2]} );
        let a3_hodl = (await token.hodlPremium(accounts[3])).hodlTokens;
        let a2_bb = (await token.hodlPremium(accounts[2])).buybackTokens;
        let a2 = (await token.balanceOf(accounts[2]));
        let a3 = (await token.balanceOf(accounts[3]));
        console.log("AAAA " + a3_hodl + "  "+a2_bb );
        console.log("balances " + a2 + "  "+a3 );

        await token.transfer( accounts[4], "800000000000000000000000", {from: accounts[3]} );
        a3_hodl = (await token.hodlPremium(accounts[3])).hodlTokens;
        a2_bb = (await token.hodlPremium(accounts[2])).buybackTokens;
        a2 = (await token.balanceOf(accounts[2]));
        a3 = (await token.balanceOf(accounts[3]));
        console.log("BBBB " + a3_hodl + "  "+a2_bb );
        console.log("balances " + a2 + "  "+a3 );


        await token.transfer( accounts[2], "800000000000000000000000", {from: accounts[4]} );
        await token.transfer( accounts[3], "800000000000000000000000", {from: accounts[4]} );
        a3_hodl = (await token.hodlPremium(accounts[3])).hodlTokens;
        a2_bb = (await token.hodlPremium(accounts[2])).buybackTokens;
        a2 = (await token.balanceOf(accounts[2]));
        a3 = (await token.balanceOf(accounts[3]));
        let a2_tt = (await testtoken.balanceOf(accounts[2]));
        console.log("CCCC " + a3_hodl + "  "+a2_bb+ "   " + a2_tt  );
        console.log("balances " + a2 + "  "+a3 );


        await token.setRefundSignupDetails("1500000000", "1553293200", testtoken.address, accounts[1]);
        await testtoken.increaseAllowance( token.address, "1000000000000000000000000", {from: accounts[1]});

        await token.refund( "100000000000000000000000" ,{from: accounts[2]})
        a3_hodl = (await token.hodlPremium(accounts[3])).hodlTokens;
        a2_bb = (await token.hodlPremium(accounts[2])).buybackTokens;
        a2 = (await token.balanceOf(accounts[2]));
        a3 = (await token.balanceOf(accounts[3]));
        a2_tt = (await testtoken.balanceOf(accounts[2]));
        console.log("DDDD " + a3_hodl + "  "+a2_bb+ "   " + a2_tt  );
        console.log("balances " + a2 + "  "+a3 );

        await assertRevert(token.refund( "200000000000000000000000", {from: accounts[2]}));
        await assertRevert(token.refund( "200000000000000000000000", {from: accounts[3]}));
        await assertRevert(token.refund( "200000000000000000000000", {from: accounts[4]}));




        //   5000 000000 000000 000000
        // 100000 000000 000000 000000
    });
});*/