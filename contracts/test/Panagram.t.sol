// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { Test, console } from "forge-std/Test.sol";
import { Panagram } from "src/Panagram.sol";
import { HonkVerifier } from "src/Verifier.sol";

contract PanagramTest is Test {
    HonkVerifier s_verifier;
    Panagram s_panagram;

    bytes s_proof;
    bytes32[] publicInputs;

    address s_admin = address(0x77);
    address s_user = makeAddr("user");
    uint256 constant FIELD_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    bytes32 ANSWER = bytes32(uint256(keccak256("triangles")) % FIELD_MODULUS);
    bytes32 CORRECT_GUESS = bytes32(uint256(keccak256("triangles")) % FIELD_MODULUS);
    bytes32 INCORRECT_GUESS = bytes32(uint256(keccak256("tranisleg")) % FIELD_MODULUS);

    function setUp() public {
        s_verifier = new HonkVerifier();
        s_panagram = new Panagram(
            s_verifier,
            ANSWER,
            "ipfs://bafybeicqfc4ipkle34tgqv3gh7gccwhmr22qdg7p6k6oxon255mnwb6csi/{id}.json",
            s_admin
        );

        s_proof = _getProof(ANSWER, CORRECT_GUESS, s_user);
    }

    function _getProof(bytes32 _guess, bytes32 _correctAnswer, address _user) internal returns (bytes memory proof_) {
        uint256 NUM_ARGS = 6;
        string[] memory inputs = new string[](NUM_ARGS);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "ts-script/generateProof.ts";
        inputs[3] = vm.toString(_guess);
        inputs[4] = vm.toString(_correctAnswer);
        inputs[5] = vm.toString(bytes32(uint256(uint160(_user))));

        bytes memory result = vm.ffi(inputs);
        
        (proof_, /*publicInputs*/) = abi.decode(result, (bytes, bytes32[]));
    }

    function testCorrectGuessPasses() public {
        vm.prank(s_user);
        s_panagram.submitGuess(s_proof);
        // vm.assertEq(s_panagram.s_winnerWins(s_user), 1);
        vm.assertEq(s_panagram.balanceOf(s_user, 0), 1);
        vm.assertEq(s_panagram.balanceOf(s_user, 1), 0);

        // check they can't try again
        vm.prank(s_user);
        vm.expectRevert();
        s_panagram.submitGuess(s_proof);
    }

    function testStartNewRound() public {
        // start a round (in setUp)
        // get a winner
        vm.prank(s_user);
        s_panagram.submitGuess(s_proof);
        // min time passed
        vm.warp(s_panagram.MIN_DURATION() + 1);
        // start a new round
        s_panagram.startRound(bytes32(uint256(keccak256("abcdefghi")) % FIELD_MODULUS));
        // validate the state has reset
        vm.assertEq(s_panagram.getCurrentPanagram(), bytes32(uint256(keccak256("abcdefghi")) % FIELD_MODULUS));
        vm.assertEq(s_panagram.s_currentRoundID(), 2);
    }

    function testIncorrectGuessFails() public {
        // start a round
        // get hash(?) of guess
        // use script to get proof
        // make a guess call
        // validate they got the winner NFT
        // validate they have been incremented in winnerWins mapping  
        bytes memory incorrectProof = _getProof(INCORRECT_GUESS, INCORRECT_GUESS, s_user);
        vm.prank(s_user);
        vm.expectRevert();
        s_panagram.submitGuess(incorrectProof);
    }
}