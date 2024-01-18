const crypto = require("crypto");
require("dotenv").config();
const ethers = require("ethers");

function bufferFromBase64(value) {
  return Buffer.from(value, "base64");
}

function derToRS(der) {
  var offset = 3;
  var dataOffset;

  if (der[offset] == 0x21) {
    dataOffset = offset + 2;
  } else {
    dataOffset = offset + 1;
  }
  const r = der.slice(dataOffset, dataOffset + 32);
  offset = offset + der[offset] + 1 + 1;
  if (der[offset] == 0x21) {
    dataOffset = offset + 2;
  } else {
    dataOffset = offset + 1;
  }
  const s = der.slice(dataOffset, dataOffset + 32);
  return [r, s];
}

function concatenateBuffers(buffer1, buffer2) {
  var tmp = new Uint8Array(buffer1.byteLength + buffer2.byteLength);
  tmp.set(new Uint8Array(buffer1), 0);
  tmp.set(new Uint8Array(buffer2), buffer1.byteLength);
  return tmp;
}

function bufferToHex(buffer) {
  return "0x".concat(
    [...new Uint8Array(buffer)]
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("")
  );
}

async function getKey(pubkey) {
  const algoParams = {
    name: "ECDSA",
    namedCurve: "P-256",
    hash: "SHA-256",
  };
  return await crypto.subtle.importKey("spki", pubkey, algoParams, true, [
    "verify",
  ]);
}

async function getCordinates(pubkey) {
  const pubKeyBuffer = bufferFromBase64(pubkey);
  const rawPubkey = await crypto.subtle.exportKey(
    "jwk",
    await getKey(pubKeyBuffer)
  );
  const { x, y } = rawPubkey;

  const xBuffer = bufferFromBase64(x);
  const yBuffer = bufferFromBase64(y);

  const pubkeyHex = [bufferToHex(xBuffer), bufferToHex(yBuffer)];

  //   const uint8ArrayPubkey = concatenateBuffers(xBuffer, yBuffer);
  //   console.log("uint8ArrayPubkey: ", uint8ArrayPubkey);

  //   let pubkeyBytes32Array = [];
  //   let i = 0;
  //   for (i; i < uint8ArrayPubkey.length; i++) {
  //     pubkeyBytes32Array[i] = ethers.utils.hexZeroPad(
  //       `0x${uint8ArrayPubkey[i].toString(16)}`,
  //       32
  //     );
  //   }

  //   console.log("pubkeyBytes32Array: ", pubkeyBytes32Array);
  return pubkeyHex;
}

const getArray = (hex) => {
  return ethers.utils.arrayify(hex);
};

module.exports = {
  bufferFromBase64,
  derToRS,
  concatenateBuffers,
  bufferToHex,
  getKey,
  getCordinates,
  getArray,
};
