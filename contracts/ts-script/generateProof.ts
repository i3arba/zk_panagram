import { Noir } from "@noir-lang/noir_js";
import { ethers } from "ethers";
import { UltraHonkBackend } from "@aztec/bb.js";
import path from "path";
import fs from "fs";

// get the circuit file
// NOTE: This will enable us to run the script from anywhere in or environment.
const circuitPath = path.resolve(__dirname, "../../circuits/target/zk_panagram.json");
const circuit = JSON.parse(fs.readFileSync(circuitPath, "utf8"));

export default async function generateProof(){
    const inputsArray = process.argv.slice(2);
    
    try {
        // initialize Noir with the circuit
        const noir = new Noir(circuit);
        // initialize the backend using the circuit bytecode
        const honk = new UltraHonkBackend(circuit.bytecode, {threads: 1});
        // create the inputs
        const inputs = {
            // Private Inputs
            guess_hash: inputsArray[0],
            // Public Inputs
            answer_hash: inputsArray[1],
            address: inputsArray[2]
        }
        // execute the circuit with the inputs to create the witness
        const { witness } = await noir.execute(inputs);
        // generate the proof (using the backend) with the witness
        const originalLog = console.log;
        console.log = () => {};

        const { proof, publicInputs } = await honk.generateProof(witness, {keccak: true});

        console.log = originalLog;

        // return the proof
        const response = ethers.AbiCoder.defaultAbiCoder().encode(
            ["bytes", "bytes32[]"],
            [proof, publicInputs]
        );

        return response;

    } catch(error){
        console.log(error);
        throw error;
    }
}

(
    async () => {
        generateProof()
        .then((response) => {
            process.stdout.write(response);
            process.exit(0);
        })
        .catch((error) => {
            console.log(error);
            process.exit(1);
        })
    }
)();