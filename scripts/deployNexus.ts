// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, run } from "hardhat";
import * as fs from 'fs';
import * as path from 'path';
import { Nexus, NodeOperator, Proxy, ValidatorExecutionRewards } from "../typechain";
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
let output_file;
export function get_file(network_name:String){
  let file_name;
  console.log(network_name)
  switch(network_name){
    case "goerli":{
      file_name = "output_goerli.json"
      break;
    }
    case "mainnet":{
      file_name = "output_mainnet.json"
      break;
    }
    case "local":{
      file_name = "output_local.json"
      break;

    }
  }
  output_file = process.cwd() + "/scripts/" + file_name;
  console.log(output_file)
  if(output_file){
    return JSON.parse(fs.readFileSync(output_file,"utf-8"))
  }
  else{
    throw Error("output file with necessay parameters is not present")
  }
}
async function main() {
  const network_name = (await ethers.provider.getNetwork()).name
  console.log(network_name)
  var output = get_file(network_name)
  console.log(output)
  let nodeOperatorImpl:NodeOperator,nodeOperatorProxy:Proxy,nexusProxy:Proxy, nexusImpl:Nexus,validatorExecutionRewardContract:ValidatorExecutionRewards;

  // node operator implementation Contract
  const NodeOperatorImpl = await ethers.getContractFactory("NodeOperator");
  if ("NodeOperatorImpl" in output && output["NodeOperatorImpl"] != ""){
    nodeOperatorImpl = await NodeOperatorImpl.attach(output["NodeOperatorImpl"]);
  } else {
    nodeOperatorImpl = await NodeOperatorImpl.deploy();
    console.log("node operator implmentation deployed to:", await nodeOperatorImpl.getAddress())
    output["NodeOperatorImpl"] =  await nodeOperatorImpl.getAddress();
  }

  // node operator proxy Contract
  const NodeOperatorProxy = await ethers.getContractFactory("Proxy");
  if("NodeOperatorProxy" in output && output["NodeOperatorProxy"] != ""){
    nodeOperatorProxy = await NodeOperatorProxy.attach(output["NodeOperatorProxy"]);
  } else {
    nodeOperatorProxy = await NodeOperatorProxy.deploy( NodeOperatorImpl.interface.encodeFunctionData("initialize", []),await nodeOperatorImpl.getAddress());
    console.log("node operator proxy deployed to:", await nodeOperatorProxy.getAddress())
    output["NodeOperatorProxy"] =  await nodeOperatorProxy.getAddress();
  }

  // Validator Execution Reward Contract
  const ValidatorExecutionRewardsContract = await ethers.getContractFactory("ValidatorExecutionRewards")
  if("ValidatorExecutionRewards" in output && output["ValidatorExecutionRewards"] != ""){
    validatorExecutionRewardContract = await ValidatorExecutionRewardsContract.attach(output["ValidatorExecutionRewards"])
  }else{
    validatorExecutionRewardContract = await ValidatorExecutionRewardsContract.deploy(output["reward_updation_bot"])
    console.log("validator ExecutionReward Contract deployed to:", await validatorExecutionRewardContract.getAddress())
    output["ValidatorExecutionRewards"] = await validatorExecutionRewardContract.getAddress()
  }

  // Nexus Implementation Contract
  const NexusImpl = await ethers.getContractFactory("Nexus");
  if ("NexusImpl" in output && output["NexusImpl"] != ""){
    nexusImpl = await NexusImpl.attach(output["NexusImpl"])
  }else {
    nexusImpl = await NexusImpl.deploy()
    console.log("nexus implementation Contract deployed to:", await nexusImpl.getAddress())
    output["NexusImpl"] = await nexusImpl.getAddress()
  }

  // Nexus Proxy Contract
  const NexusProxyContract = await ethers.getContractFactory("Proxy");
  if("NexusProxy" in output && output["NexusProxy"] != ""){
    nexusProxy = await NexusProxyContract.attach(output["NexusProxy"])
  } else {
    nexusProxy = await NexusProxyContract.deploy( NexusImpl.interface.encodeFunctionData("initialize", []),await nexusImpl.getAddress());
    console.log("nexus proxy deployed to:", await nexusProxy.getAddress())
    output["NexusProxy"] =  await nexusProxy.getAddress();
    const nexus_contract:Nexus = await NexusImpl.attach(nexusProxy);
    await nexus_contract.changeExecutionFeeAddress(await validatorExecutionRewardContract.getAddress());
    await nexus_contract.setOffChainBot(output["nexus_bot"]);
    await nexus_contract.setNodeOperatorContract(nodeOperatorProxy.getAddress())
  }

  fs.writeFile(output_file, JSON.stringify(output), function(err) {
    if(err) {
        return console.log(err);
    }
    console.log("The file was saved!");
  });
  if (process.env.verify){
    verifyContract(await nodeOperatorImpl.getAddress(),[])
    verifyContract(await validatorExecutionRewardContract.getAddress(),[output["reward_updation_bot"]])
    verifyContract(await nexusImpl.getAddress(),[])
    verifyContract(await nodeOperatorProxy.getAddress(),[NodeOperatorImpl.interface.encodeFunctionData("initialize", []),await nodeOperatorImpl.getAddress()])
    verifyContract(await nexusProxy.getAddress(),[NexusImpl.interface.encodeFunctionData("initialize", []),await nexusImpl.getAddress()])
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
