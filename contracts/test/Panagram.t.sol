// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { Test, console } from "forge-std/Test.sol";
import { Panagram } from "src/Panagram.sol";
import { HonkVerifier } from "src/Verifier.sol";

contract PanagramTest is Test {
    HonkVerifier verifier;
    Panagram panagram;

    bytes proof;
    bytes32[] publicInputs;

    address admin = address(0x77);
    address user = makeAddr("user");
    uint256 constant FIELD_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    bytes32 ANSWER = bytes32(uint256(keccak256(abi.encodePacked(bytes32(uint256(keccak256("triangles")) % FIELD_MODULUS)))) % FIELD_MODULUS);
    bytes32 CORRECT_GUESS = bytes32(uint256(keccak256("triangles")) % FIELD_MODULUS);
    bytes32 INCORRECT_GUESS = bytes32(uint256(keccak256("tranisleg")) % FIELD_MODULUS);

    function setUp() public {
        verifier = new HonkVerifier();
        panagram = new Panagram(
            verifier,
            ANSWER,
            "ipfs://bafybeicqfc4ipkle34tgqv3gh7gccwhmr22qdg7p6k6oxon255mnwb6csi/{id}.json",
            admin
        );

        proof = _getProof(CORRECT_GUESS, ANSWER, user);
    }

    function testCorrectGuessPasses() public {
        vm.prank(user);
        panagram.submitGuess(proof);
        // vm.assertEq(panagram.s_winnerWins(user), 1);
        vm.assertEq(panagram.balanceOf(user, 0), 1);

        // check they can't try again
        vm.prank(user);
        vm.expectRevert();
        panagram.submitGuess(proof);
    }

    function testStartNewRound() public {
        // start a round (in setUp)
        vm.assertEq(panagram.s_currentRoundID(), 0);
        // get a winner
        vm.prank(user);
        panagram.submitGuess(proof);
        // min time passed
        vm.warp(panagram.MIN_DURATION() + 1);
        //Generates a new answer
        bytes32 newAnswer = bytes32(uint256(keccak256(abi.encodePacked(bytes32(uint256(keccak256("outnumber")) % FIELD_MODULUS)))) % FIELD_MODULUS);
        // start a new round
        vm.prank(admin);
        panagram.startRound(newAnswer);
        // validate the state has reset
        vm.assertEq(panagram.getCurrentPanagram(), newAnswer);
        vm.assertEq(panagram.s_currentRoundID(), 1);
    }

    function testIncorrectGuessFails() public {
        bytes32 incorrectAnswer = bytes32(uint256(keccak256(abi.encodePacked(bytes32(uint256(keccak256("suahsuahsa")) % FIELD_MODULUS)))) % FIELD_MODULUS);
        bytes32 incorrectGuess = bytes32(uint256(keccak256("suahsuahsa")) % FIELD_MODULUS);

        bytes memory incorrectProof = _getProof(incorrectGuess, incorrectAnswer, user);
        
        vm.prank(user);
        vm.expectRevert();
        panagram.submitGuess(incorrectProof);
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
}