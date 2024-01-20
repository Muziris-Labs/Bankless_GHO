import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

/**
 * Deploys a contract named "YourContract" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployYourContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
    On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

    When deploying to live networks (e.g `yarn deploy --network goerli`), the deployer account
    should have sufficient balance to pay for the gas fees for contract creation.

    You can generate a random account with `yarn generate` which will fill DEPLOYER_PRIVATE_KEY
    with a random private key in the .env file (then used on hardhat.config.ts)
    You can run the `yarn account` command to check your balance in every network.
  */
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  await deploy("ValeriumFactory", {
    from: deployer,
    // Contract constructor arguments
    args: [
      "0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165",
      "0xb1D4538B4571d411F07960EF2838Ce337FE1E80E",
      "0x75a7d9B87391664F816863e28df0c2e63dfb4543",
      "0x2EF41EC23021bD5aBa53C6599D763e89A897Acad",
      "0x2aa4c97688f340C8A2bDE2016b16dEFDC259834D",
      "0x8487F6630510A00bFACd9Fe701700F193F52C04F",
      "0xc4bF5CbDaBE595361438F8c6a187bDc330539c60",
      "0x635A86F9fdD16Ff09A0701C305D3a845F1758b8E",
      "0x694AA1769357215DE4FAC081bf1f309aDC325306",
    ],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });

  // Get the deployed contract
  // const yourContract = await hre.ethers.getContract("YourContract", deployer);
};

export default deployYourContract;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployYourContract.tags = ["PasskeyVerifier"];
