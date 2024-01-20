const express = require("express");
const router = express.Router();
require("dotenv").config();
const ethers = require("ethers");
const abi = require("../../constants/forwarderABI.json");

router.post("/", async (req, res) => {
  const apiKey = req.header("x-api-key");

  if (apiKey !== process.env.API_KEY) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const forwardRequest = req.body.forwardRequest;

  if (!forwardRequest) {
    return res.status(400).json({ error: "Bad Request" });
  }

  const privateKey = process.env.PRIVATE_KEY;
  const rpcUrl = process.env.RPC_URL;
  const relayerAddress = process.env.RELAYER_ADDRESS;

  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey, provider);
  const contract = new ethers.Contract(relayerAddress, abi, wallet);

  try {
    const data = contract.interface.encodeFunctionData("execute", [
      forwardRequest,
    ]);

    const unSignedTx = {
      to: relayerAddress,
      data,
      value: 0,
      gasLimit: 1000000,
    };

    const tx = await wallet.sendTransaction(unSignedTx);

    const receipt = await tx.wait();

    res.json({ success: true, receipt });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

module.exports = router;
