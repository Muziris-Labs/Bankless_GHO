const express = require("express");
const router = express.Router();
require("dotenv").config();
const crypto = require("crypto");
const ethers = require("ethers");
const utils = require("../../lib/utils");
const { acvm } = require("@noir-lang/noir_js");

router.post("/passkey/inputs", async (req, res) => {
  const { pubkey, credentialId, authenticatorData, clientData } = req.body;

  if (!pubkey || !credentialId || !authenticatorData || !clientData) {
    return res.status(400).json({ msg: "Please enter all fields" });
  }

  const authDataBuffer = utils.bufferFromBase64(authenticatorData);
  const clientDataBuffer = utils.bufferFromBase64(clientData);

  const challengeOffset =
    clientDataBuffer.indexOf("226368616c6c656e6765223a", 0, "hex") + 12 + 1;

  const authDataHex = utils.bufferToHex(authDataBuffer);
  const clientDataHex = utils.bufferToHex(clientDataBuffer);

  const pubKeyCoordinates = await utils.getCordinates(pubkey);

  const pubkey_x_array = utils.getArray(pubKeyCoordinates[0]);
  const pubkey_x_hash = acvm.sha256(pubkey_x_array);
  const pubkey_x_hex = utils.bufferToHex(pubkey_x_hash.buffer);

  const abiCoder = new ethers.utils.AbiCoder();

  const inputs = abiCoder.encode(
    ["bytes32", "string", "bytes", "bytes1", "bytes", "uint"],
    [
      pubkey_x_hex,
      credentialId,
      authDataHex,
      0x05,
      clientDataHex,
      challengeOffset,
    ]
  );

  res.json({
    inputs: inputs,
    pubkey_x_hex: pubkey_x_hex,
    credentialId: credentialId,
    authDataHex: authDataHex,
    clientDataHex: clientDataHex,
    challengeOffset: challengeOffset,
  });
});

router.post("/recovery/inputs", async (req, res) => {
  const { signature, message } = req.body;

  if (!signature || !message) {
    return res.status(400).json({ msg: "Please enter all fields" });
  }

  const pubKey_uncompressed = ethers.utils.recoverPublicKey(
    ethers.utils.hashMessage(ethers.utils.toUtf8Bytes(message)),
    signature
  );

  let pubKey = pubKey_uncompressed.slice(4);
  let pub_key_x = pubKey.substring(0, 64);

  const pubkey_x_hash = acvm.sha256(
    ethers.utils.arrayify("0x" + pub_key_x).toString()
  );
  const pubkey_x_hex = utils.bufferToHex(pubkey_x_hash.buffer);

  res.json({
    pub_key_x: pub_key_x,
    recoveryKeyHash: pubkey_x_hex,
  });
});

module.exports = router;
