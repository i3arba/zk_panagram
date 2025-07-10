import { Noir } from "@noir-lang/noir_js";
import { ethers } from "ethers";
import { UltraHonkBackend } from "@aztec/bb.js";

// get the circuit file
// initialize Noir with the circuit
// initialize the backend using the circuit bytecode
// create the inputs
// execute the circuit with the inputs to create the witness
// generate the proof (using the backend) with the witness
// return the proof