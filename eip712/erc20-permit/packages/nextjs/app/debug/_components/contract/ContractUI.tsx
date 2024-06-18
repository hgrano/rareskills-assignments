"use client";

// @refresh reset
import { FormEvent, useReducer, useState } from "react";
import { ContractReadMethods } from "./ContractReadMethods";
import { ContractVariables } from "./ContractVariables";
import { ContractWriteMethods } from "./ContractWriteMethods";
import { Address, Balance, AddressInput } from "~~/components/scaffold-eth";
import { useDeployedContractInfo, useNetworkColor } from "~~/hooks/scaffold-eth";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";
import { ContractName } from "~~/utils/scaffold-eth/contract";

import { useAccount, useConfig, useReadContract, useSignTypedData } from "wagmi";
import { writeContract } from '@wagmi/core'
import { readContracts } from "wagmi/actions";
import { getParsedContractFunctionArgs } from "./utilsContract";
import { parseSignature } from 'viem'
import { deployContract } from "viem/actions";

type ContractUIProps = {
  contractName: ContractName;
  className?: string;
};

/**
 * UI component to interface with deployed contracts.
 **/
export const ContractUI = ({ contractName, className = "" }: ContractUIProps) => {
  const [refreshDisplayVariables, triggerRefreshDisplayVariables] = useReducer(value => !value, false);
  const { targetNetwork } = useTargetNetwork();
  console.log("target network", targetNetwork);
  const { data: deployedContractData, isLoading: deployedContractLoading } = useDeployedContractInfo(contractName);
  const networkColor = useNetworkColor();

  const { signTypedDataAsync } = useSignTypedData();

  const myAccount = useAccount();
  //const contractAddr = "0xa513e6e4b8f2a923d98304ec87f64353c4d5c853";
  const [contractAddr, setContractAddr] = useState("");

  const readAllowance = useReadContract({
    address: contractName === "YourToken" ? deployedContractData?.address : undefined,
    functionName: "allowance",
    abi: deployedContractData?.abi,
    chainId: targetNetwork.id,
    args: [myAccount.address, contractAddr]
  });

  const readNonces = useReadContract({
    address: contractName === "YourToken" ? deployedContractData?.address : undefined,
    functionName: "nonces",
    abi: deployedContractData?.abi,
    chainId: targetNetwork.id,
    args: [myAccount.address]
  });

  const config = useConfig();

  console.log("nonces = ", readNonces);

  const signData = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    if (myAccount.address === undefined) {
      console.error("myAccount.address === undefined");
      return;
    }
    if (deployedContractData?.address === undefined) {
      console.error("deployedContractData.address === undefined");
      return;
    }
    console.log("typeof(deployedContractData.address)", typeof(deployedContractData.address));
    const amount = BigInt(1000);
    const deadline = BigInt(+ new Date() + 60 * 60);
    console.log("deadline: " + deadline);

    const nonce = readNonces.data; 
    console.log("nonce:", nonce);

    const signature = await signTypedDataAsync(
      {
        types: {
          EIP712Domain: [
            { name: "name", type: "string" },
            { name: "version", type: "string" },
            { name: "chainId", type: "uint256" },
            { name: "verifyingContract", type: "address" },
          ],
          Permit: [
            { name: "owner", type: "address" },
            { name: "spender", type: "address" },
            { name: "value", type: "uint256" },
            { name: "nonce", type: "uint256" },
            { name: "deadline", type: "uint256" }
          ],
        },
        primaryType: "Permit",
        domain: {
          name: "DomainName",
          version: "1",
          chainId: BigInt(targetNetwork.id),
          verifyingContract: deployedContractData.address
        },
        message: {
          owner: myAccount.address,
          spender: contractAddr,
          value: amount,
          nonce: nonce as any,
          deadline: deadline
        }
      }
    );
    console.log("signature = ", signature);
    // signer.provider.send("eth_signTypedData_v4",
    //   [myAccount, JSON.stringify(typedData)]
    // );
    const split = parseSignature(signature);

    // console.log("r: ", split.r);
    // console.log("s: ", split.s);
    // console.log("v: ", split.v);

    // let allowance = (await readContracts.YourContract.allowance(myAccount, contractAddr)).toNumber();
    // console.log("ALLOWANCE BEFORE:", allowance);

    const hash = await writeContract(
      config,
      {
        address: deployedContractData.address,
        functionName: "permit",
        abi: deployedContractData.abi,
        chainId: targetNetwork.id,
        args: [myAccount.address, contractAddr, amount, deadline, Number(split.v), split.r, split.s]
      }
    );
    console.log("tx hash", hash);

    // const tx = await writeContracts.YourContract.permit(
    //   myAccount, contractAddr, amount, deadline, split.v, split.r, split.s);
    // await tx.wait();

    // // confirm that the allowance was changed:
    // allowance = (await readContracts.YourContract.allowance(myAccount, contractAddr)).toNumber();
    // console.log("ALLOWANCE AFTER:", allowance);
  };

  if (myAccount.status !== "connected") {
    return (
      <p className="text-3xl mt-14">
        {`Account is not connected`}
      </p>
    );
  }

  console.log("deployedContractData", deployedContractData);
  console.log("account = ", myAccount);
  console.log("readContract", readAllowance);

  if (deployedContractLoading || (readAllowance !== undefined && readAllowance.isLoading)) {
    return (
      <div className="mt-14">
        <span className="loading loading-spinner loading-lg"></span>
      </div>
    );
  }

  if (!deployedContractData) {
    return (
      <p className="text-3xl mt-14">
        {`No contract found by the name of "${contractName}" on chain "${targetNetwork.name}"!`}
      </p>
    );
  }

  if (readAllowance !== undefined && readAllowance.isError) {
    console.warn("Read contract error");
    // return (
    //   <p className="text-3xl mt-14">
    //     {`Unable to create the read contract`}
    //   </p>
    // );
  }

  const signAllowanceForm =
    <form onSubmit={signData}>
      <AddressInput onChange={setContractAddr} value={contractAddr} placeholder="Address to permit"/>
      <button type="submit">Permit</button>
    </form>

  const currentAllowanceDisplay = readAllowance !== undefined && !readAllowance.isLoading && !readAllowance.isError &&
    <p>Current allowance: {`${readAllowance.data}`}</p>

  // const getAllowance = async () => {
  //   let allowance = (await readContracts.YourContract.allowance(myAccount, contractAddr)).toNumber();
  //   console.log("CURRENT ALLOWANCE", allowance);
  // }

  return (
    <div className={`grid grid-cols-1 lg:grid-cols-6 px-6 lg:px-10 lg:gap-12 w-full max-w-7xl my-0 ${className}`}>
      <div className="col-span-5 grid grid-cols-1 lg:grid-cols-3 gap-8 lg:gap-10">
        <div className="col-span-1 flex flex-col">
          <div className="bg-base-100 border-base-300 border shadow-md shadow-secondary rounded-3xl px-6 lg:px-8 mb-6 space-y-1 py-4">
            <div className="flex">
              <div className="flex flex-col gap-1">
                <span className="font-bold">{contractName}</span>
                <Address address={deployedContractData.address} />
                <div className="flex gap-1 items-center">
                  <span className="font-bold text-sm">Balance:</span>
                  <Balance address={deployedContractData.address} className="px-0 h-1.5 min-h-[0.375rem]" />
                </div>
              </div>
            </div>
            {targetNetwork && (
              <p className="my-0 text-sm">
                <span className="font-bold">Network</span>:{" "}
                <span style={{ color: networkColor }}>{targetNetwork.name}</span>
              </p>
            )}
          </div>
          <div className="bg-base-300 rounded-3xl px-6 lg:px-8 py-4 shadow-lg shadow-base-300">
            <ContractVariables
              refreshDisplayVariables={refreshDisplayVariables}
              deployedContractData={deployedContractData}
            />
          </div>
        </div>
        <div className="col-span-1 lg:col-span-2 flex flex-col gap-6">
          <div className="z-10">
            <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 flex flex-col mt-10 relative">
              <div className="h-[5rem] w-[5.5rem] bg-base-300 absolute self-start rounded-[22px] -top-[38px] -left-[1px] -z-10 py-[0.65rem] shadow-lg shadow-base-300">
                <div className="flex items-center justify-center space-x-2">
                  <p className="my-0 text-sm">Read</p>
                </div>
              </div>
              <div className="p-5 divide-y divide-base-300">
                <ContractReadMethods deployedContractData={deployedContractData} />
              </div>
            </div>
          </div>
          <div className="z-10">
            <div className="bg-base-100 rounded-3xl shadow-md shadow-secondary border border-base-300 flex flex-col mt-10 relative">
              <div className="h-[5rem] w-[5.5rem] bg-base-300 absolute self-start rounded-[22px] -top-[38px] -left-[1px] -z-10 py-[0.65rem] shadow-lg shadow-base-300">
                <div className="flex items-center justify-center space-x-2">
                  <p className="my-0 text-sm">Write</p>
                </div>
              </div>
              <div className="p-5 divide-y divide-base-300">
                <ContractWriteMethods
                  deployedContractData={deployedContractData}
                  onChange={triggerRefreshDisplayVariables}
                />
              </div>
            </div>
          </div>
        </div>
        {signAllowanceForm}
        {currentAllowanceDisplay}
      </div>
    </div>
  );
};
