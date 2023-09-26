// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, run } from "hardhat";
export async function verifyContract(
  contractAddress: string,
  constructorArguments: any
) {
  await run("verify:verify", {
    address: contractAddress,
    constructorArguments: constructorArguments,
  });
}
function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
async function main() {
  const Nexus = await ethers.getContractFactory("Nexus");
  const nexus = await Nexus.attach(
    "0x7AE880B5013FB950e3B1d87a3501ff5a5f166a15"
  );
  // const txInitialize = Nexus.interface.encodeFunctionData("initialize", []);
  //   console.log(txInitialize);
  // await nexus.deployed();
  // await sleep(2000);
  verifyContract(nexus.address, []);
  console.log("nexus contract deployed to:", nexus.address);
  //   verifyContract("0x1d5f23baC2FB13fB5CbD9312b5c7EdF75c4C6417", []);
  const NexusProxy = await ethers.getContractFactory("Nexus");
  const nexusProxy = await NexusProxy.attach(
    "0x29030F72EB50dECf3d8eb86Ce58256a3e8f85253"
  );
  //   const nexusProxy = await Nexus.attach(
  //     "0x5DfFeE1B9C7D68726545c3e05fB99ACc6660aC05"
  //   );
  nexusProxy.updateProxy(nexus.address);
  // await nexusProxy.deployed();
  await sleep(2000);
  console.log("proxy deployed to:", nexusProxy.address);
  // verifyContract(nexusProxy.address, [txInitialize, nexus.address]);
  // const Implementation = await ethers.getContractFactory("Implement");
  // const implementation = await Implementation.deploy(
  //   1000,0x29030F72EB50dECf3d8eb86Ce58256a3e8f85253 = await Implementation.attach(
  //   "0x0d191cb43F34A7B6F156AfEB42D20448b0408D28"
  // );
  // await implementation.deployed();

  // console.log("implementation deployed to:", implementation.address);
  // verifyContract(implementation.address, [
  //   1000,
  //   "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6",
  // ]);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
