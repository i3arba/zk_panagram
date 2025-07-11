///SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { Ownable, Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IVerifier } from "src/Verifier.sol";

contract Panagram is ERC1155, Ownable {

    /**
                State Variables
    */
    ///@notice Immutable variable to store the Noir Verifier contract address
    IVerifier immutable i_verifier;

    ///@notice magic number removal: Duration of Each Round
    uint16 public constant MIN_DURATION = 10800; //3 hours
    ///@notice magic number removal: will be used to comparisons and as NFT id
    uint256 constant ZERO = 0;
    ///@notice magic number removal: Amount of NFTs to mint
    uint256 constant NFT_AMOUNT = 1;

    ///@notice storage variable to store the round's answer
    bytes32 s_expectedAnswer;
    ///@notice storage variable to keep track of each round starting time
    uint256 public s_roundStartTime;
    ///@notice storage variable to keep track of winners. It will be reset to zero every time a new round starts
    address s_roundWinner;
    ///@notice storage variable to store the round ID
    uint256 public s_currentRoundID;

    /**
                Events
    */
    ///@notice event emitted when a new round starts
    event Panagram_NewRoundStarted(bytes32 answer, uint256 roundStartedAt);
    ///@notice event emitted when a user input the correct answer
    event Panagram_RoundsWinnerSelected(address user, uint256 currentRoundId);


    /**
                Errors
    */
    ///@notice error emitted when the owner tries to start a new round before enough time has passed
    error Panagram_NotEnoughTimeHasPassed();
    ///@notice error emitted when the owner tries to start a new round before the previous one was completed
    error Panagram_PanagramDoesntHaveAWinnerYet();
    ///@notice error emitted when a user tries to guess for an already solved panagram round
    error Panagram_RoundOneSolved(uint256 currentRoundID, address roundWinner);
    ///@notice error emitted when the user input a empty proof
    error Panagram_theProofCantBeAnEmptyInput(bytes proof);
    ///@notice error emitted when the user proof is incorrect
    error Panagram_IncorrectProof();

    constructor(
        IVerifier _verifier,
        bytes32 _expectedAnswer,
        string memory _uri,
        address _owner
    ) ERC1155(_uri) Ownable(_owner) { //Ciara URI: "ipfs://bafybeicqfc4ipkle34tgqv3gh7gccwhmr22qdg7p6k6oxon255mnwb6csi/{id}.json"
        i_verifier = _verifier;
        s_expectedAnswer = _expectedAnswer;
        s_roundStartTime = block.timestamp;
    }

    /**
        @notice Function to enable the owners to start a new round
        @param _expectedAnswer the value to check against
    */
    function startRound(bytes32 _expectedAnswer) external onlyOwner{
        if(s_roundStartTime + MIN_DURATION < block.timestamp) revert Panagram_NotEnoughTimeHasPassed();
        if(s_roundWinner == address(0)) revert Panagram_PanagramDoesntHaveAWinnerYet();
        
        s_expectedAnswer = _expectedAnswer;
        s_roundStartTime = block.timestamp;
        s_roundWinner = address(0);
        s_currentRoundID = s_currentRoundID + 1;

        emit Panagram_NewRoundStarted(_expectedAnswer, block.timestamp);
    }

    // Function to allow users to submit a guess
    /**
        @notice external function to enable users to make a guess over the round's panagram
        @param _proof the user guess to be validated against the round answer.
    */
    function submitGuess(bytes memory _proof) external returns(bool isCorrect_){
        if(s_roundWinner != address(0)) revert Panagram_RoundOneSolved(s_currentRoundID, s_roundWinner);
        if(_proof.length == 0) revert Panagram_theProofCantBeAnEmptyInput(_proof);

        bytes32[] memory publicInputs = new bytes32[](2);
        publicInputs[0] = s_expectedAnswer;
        publicInputs[1] = bytes32(uint256(uint160(msg.sender)));

        isCorrect_ = i_verifier.verify(_proof, publicInputs);
        if(!isCorrect_) revert Panagram_IncorrectProof();

        s_roundWinner = msg.sender;

        emit Panagram_RoundsWinnerSelected(msg.sender, s_currentRoundID);

        _mint(msg.sender, ZERO, NFT_AMOUNT, "");
    }

    function getCurrentPanagram() external view returns (bytes32) {
        return s_expectedAnswer;
    }
}