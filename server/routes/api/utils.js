const express = require("express");
const router = express.Router();
require("dotenv").config();
const crypto = require("crypto");
const ethers = require("ethers");
const utils = require("../../lib/utils");
const { acvm, Noir } = require("@noir-lang/noir_js");
const { BarretenbergBackend } = require("@noir-lang/backend_barretenberg");
const passkeyCircuit = require("../../circuits/passkey_circuit/target/passkey_circuit.json");
const recoveryCircuit = require("../../circuits/recovery_circuit/target/recovery_circuit.json");

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

router.post("/passkey/generate", async (req, res) => {
  const { pubkey, signature, message } = req.body;

  if (!pubkey || !signature || !message) {
    return res.status(400).json({ msg: "Please enter all fields" });
  }

  const backend = new BarretenbergBackend(passkeyCircuit);
  const noir = new Noir(passkeyCircuit, backend);

  const pubKeyCoordinates = await utils.getCordinates(pubkey);

  const pub_key_x = pubKeyCoordinates[0];
  const pub_key_y = pubKeyCoordinates[1];

  const pub_key_x_array = utils.getArray(pub_key_x);
  const pub_key_y_array = utils.getArray(pub_key_y);

  const signatureHex = await utils.getSignature(signature);
  const signatureArray = utils.getArray(signatureHex);

  const messageArray = utils.getArray(message);

  const pubkey_x_hash = acvm.sha256(pub_key_x_array);

  const input = {
    pub_key_x: Array.from(pub_key_x_array),
    pub_key_y: Array.from(pub_key_y_array),
    signature: Array.from(signatureArray),
    message: Array.from(messageArray),
    pub_key_x_hash: Array.from(pubkey_x_hash),
  };

  const proof = await noir.generateFinalProof(input);

  res.json({
    proof: "0x" + Buffer.from(proof.proof).toString("hex"),
  });
});

router.post("/recovery/generate", async (req, res) => {
  const { signature, message } = req.body;

  if (!signature || !message) {
    return res.status(400).json({ msg: "Please enter all fields" });
  }

  const backend = new BarretenbergBackend(recoveryCircuit);
  const noir = new Noir(recoveryCircuit, backend);

  const pubKey_uncompressed = ethers.utils.recoverPublicKey(
    ethers.utils.hashMessage(ethers.utils.toUtf8Bytes(message)),
    signature
  );

  let pubKey = pubKey_uncompressed.slice(4);
  let pub_key_x = pubKey.substring(0, 64);
  let pub_key_y = pubKey.substring(64);

  const pub_key_x_array = ethers.utils.arrayify("0x" + pub_key_x);
  const pub_key_y_array = ethers.utils.arrayify("0x" + pub_key_y);

  const signatureArray = ethers.utils.arrayify(signature);

  const messageArray = ethers.utils.arrayify(
    ethers.utils.hashMessage(ethers.utils.toUtf8Bytes(message))
  );

  const pubkey_x_hash = acvm.sha256(pub_key_x_array);

  const input = {
    pub_key_x: Array.from(pub_key_x_array),
    pub_key_y: Array.from(pub_key_y_array),
    signature: Array.from(signatureArray.slice(0, 64)),
    hashed_message: Array.from(messageArray),
    pub_key_x_hash: Array.from(pubkey_x_hash),
  };

  console.log(input);

  const proof = await noir.generateFinalProof(input);

  res.json({
    proof: "0x" + Buffer.from(proof.proof).toString("hex"),
  });
});

module.exports = router;
