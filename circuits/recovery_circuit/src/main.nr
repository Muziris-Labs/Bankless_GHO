use dep::std;
use dep::ecrecover;

fn main(
    pub_key_x: [u8; 32],
    pub_key_y: [u8; 32],
    signature: [u8; 64],
    hashed_message: pub [u8; 32],
    pub_key_x_hash: pub [u8;32]
) {
    let hash = std::sha256::digest(pub_key_x);
    assert(hash == pub_key_x_hash);

    let key = ecrecover::secp256k1::PubKey::from_xy(pub_key_x, pub_key_y);
    let is_valid = key.verify_sig(signature, hashed_message);

    assert(is_valid == true);
}

#[test]
fn test_main() {
    let pub_key_x:[u8;32] = [
        170, 60, 143, 56, 248, 157, 141, 21, 50, 59, 118, 206, 25, 184, 193, 178, 24, 94, 134, 182, 23, 75, 190, 175, 196, 0, 115, 207, 219, 41, 80, 7
    ];

    let pub_key_y:[u8;32] = [
        236, 173, 206, 117, 192, 95, 205, 216, 12, 197, 238, 54, 32, 74, 217, 37, 58, 46, 91, 93, 224, 94, 136, 170, 203, 64, 182, 58, 67, 142, 66, 166
    ];

    let signature:[u8;64] = [
        204, 97, 78, 27, 238, 142, 35, 219, 48, 246, 255, 157, 128, 194, 165, 49, 212, 186, 243, 145, 118, 239, 112, 28, 222, 214, 25, 99, 114, 229, 127, 148, 36, 49, 90, 42, 81, 34, 171, 149, 27, 78, 126, 97, 249, 201, 122, 177, 162, 17, 162, 138, 36, 155, 207, 114, 181, 15, 73, 86, 241, 150, 169, 104
    ];

    let hashed_message:[u8;32] = [
        161, 222, 152, 134, 0, 164, 44, 75, 74, 176, 137, 182, 25, 41, 124, 23, 213, 60, 255, 174, 93, 81, 32, 216, 45, 138, 146, 208, 187, 59, 120, 242
    ];

    let pub_key_x_hash:[u8;32] = [
        0xfd, 0x58, 0x72, 0x60, 0xa6, 0xc4, 0xd7, 0x6c, 0x32, 0x1b, 0x18, 0x8f, 0xf7, 0xf9, 0x36, 0x3f, 0xe0, 0x4a, 0x11, 0xdc, 0x5b, 0x38, 0x90, 0xdc, 0xcd, 0x8d, 0x67, 0xfd, 0xa6, 0xc2, 0xc4, 0x58
    ];

    main(pub_key_x, pub_key_y, signature, hashed_message, pub_key_x_hash);
}
