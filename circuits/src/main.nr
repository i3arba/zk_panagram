use dep::keccak256;
fn main(guess_hash: Field, answer_hash: pub Field, address: pub Field) {

    // Convert the one-time-hashed guess_hash to bytes
    let guess_hash_decompose : [u8; 32] = guess_hash.to_be_bytes();

    // hash the guess_hash_decompose again using the keccak256 function
    let guess_double_hash_decompose: [u8; 32] = keccak256::keccak256(guess_hash_decompose, 32);

    // Compares the double hashed `guess_hash` to an already double hashed `answer_hash`
    assert(Field::from_be_bytes(guess_double_hash_decompose) == answer_hash);

    // This is necessary to avoid users to bypass the frontend and generate their own proof and validate it calling the on-chain function.
}

// #[test]
// fn test_main() {
//     main(1, 2);

//     // Uncomment to make test fail
//     // main(1, 1);
// }
