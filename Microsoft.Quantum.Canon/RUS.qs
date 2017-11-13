// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

namespace Microsoft.Quantum.Canon {
    open Microsoft.Quantum.Primitive;

    /// <summary>
    ///     Returns Boolean value indicating whether all qubits of a register are in the 0 state, when measured in a specified single qubit Pauli basis. 
    /// </summary>
    /// <param name = "qs"> A register of qubits which is measured in the pauli basis. 
    /// <param name = "pauli"> The Pauli operator that specifies the basis for the Pauli measurements. 

    operation AllMeasurementsZero (qs : Qubit[], pauli : Pauli) : Bool {
        body {
            mutable value = true;
            for (i in 0..Length(qs)-1) {
                if ( Measure([pauli], [qs[i]]) == One ) {
                    set value = false;
                }
            }
            return value;
        }
    }

    /// <summary>
    ///     Example of a Repeat-Until-Success (RUS) circuit implementing the V gate, according to Nielsen & Chuang. 
    /// </summary>
    /// <param name = "qubit"> A single qubit to which the RUS protocol is applied that implements the V gate. </param>
    /// <remarks>  The circuit first creates two ancillas and initializes them both in the |+> state. Then a circuit that involves 2 Toffoli 
    ///     gates is applied and the ancillas are measured in the Z basis. If the result of both ancillas is Zero, the V gate has been applied 
    ///     to the input data. For any other result, the identity has been applied, in which case the procedure is repeated. 
    ///     [ Nielsen & Chuang, CUP 2000, Section 1.3.6, http://doi.org/10.1017/CBO9780511976667 ]
    /// </remarks>

    operation RUScircuitV1 (qubit : Qubit) : () {
        body {
            using(ancillas = Qubit[2]) {
                ApplyToEachA(H, ancillas);
                mutable finished = false;
                repeat { 
                    (Controlled X)(ancillas, qubit);
                    S(qubit);
                    (Controlled X)(ancillas, qubit);
                    Z(qubit);
                }
                until(finished)
                fixup {
                    AssertProb([PauliX], [ancillas[0]], Zero, 0.75, "Error: the probability to measure Zero in the first ancilla must be 3/4", 1e-10);
                    // note that conditioned on the first ancilla measurement being Zero, the probability of the second being Zero becomes 5/6
                    // but when measured individuall, the probabilities to be Zero are the same and are equal to 3/4
                    AssertProb([PauliX], [ancillas[1]], Zero, 0.75, "Error: the probability to measure Zero in the second ancilla must be 3/4", 1e-10);
                    if AllMeasurementsZero(ancillas, PauliX) {
                        set finished = true;
                    }
                }
            }
        }
    }

    /// <summary>
    ///     Example of a Repeat-Until-Success (RUS) circuit implementing the V gate, according to Paetznick & Svore.
    /// </summary>
    /// <param name = "qubit"> A single qubit to which the RUS protocol is applied that implements the V gate. </param>
    /// <remarks>  The circuit first creates two ancillas and initializes them both in the |+> state. Then a circuit that involves 4 T gates 
    ///     is applied and the ancillas are measured in the Z basis. If the result of both ancillas is Zero, the V gate has been applied 
    ///     to the input data. For any other result, the identity has been applied, in which case the procedure is repeated. 
    ///     [ Paetznick & Svore, Quantum Information & Computation 14(15 & 16): 1277-1301 (2014), https://arxiv.org/abs/1311.1074 ]
    /// </remarks>

    operation RUScircuitV2 (qubit : Qubit) : () {
        body {
            using(ancillas = Qubit[2]) { 
                ApplyToEachA(H, ancillas);
                mutable finished = false;
                repeat { 
                    (Adjoint T)(ancillas[1]);
                    T(qubit);
                    (Controlled X)([ancillas[0]], ancillas[1]);
                    Z(qubit);
                    T(ancillas[1]);
                    (Controlled X)([qubit], ancillas[0]);
                    T(ancillas[0]);
                }
                until(finished)
                fixup {
                    AssertProb([PauliX], [ancillas[0]], Zero, 0.75, "Error: the probability to measure Zero in the first ancilla must be 3/4", 1e-10);
                    // note that conditioned on the first ancilla measurement being Zero, the probability of the second being Zero becomes 5/6
                    // but when measured individuall, the probabilities to be Zero are the same and are equal to 3/4
                    AssertProb([PauliX], [ancillas[1]], Zero, 0.75, "Error: the probability to measure Zero in the second ancilla must be 3/4", 1e-10);
                    if AllMeasurementsZero(ancillas, PauliX) {
                        set finished = true;
                    }
                }
            }
        }
    }

    operation RUSTestExFail () : () {
        body {
            // Testing the Nielsen & Chuang circuit for the V gate
            using (qubits = Qubit[1]) {
                // create a |+> state 
                H(qubits[0]);
                RUScircuitV1(qubits[0]);
                AssertProb([PauliZ], [qubits[0]], Zero, 0.5, "Error: state after applying the Z-rotation must give Zero state with probability 0.5", 1e-10);
            }
            using (qubits2 = Qubit[1]) {
                // create a |-> state 
                X(qubits2[0]);
                H(qubits2[0]);
                RUScircuitV1(qubits2[0]);
                AssertProb([PauliZ], [qubits2[0]], Zero,  0.5, "Error: state after applying the Z-rotation must give Zero state with probability 0.5", 1e-10);
            }
            // Testing the Paetznick & Svore circuit for the V gate
            using (qubits3 = Qubit[1]) {
                // create a |+> state 
                H(qubits3[0]);
                RUScircuitV2(qubits3[0]);
                AssertProb([PauliZ], [qubits3[0]], Zero, 0.5, "Error: state after applying the Z-rotation must give Zero state with probability 0.5", 1e-10);
            }
            using (qubits4 = Qubit[1]) {
                // create a |-> state 
                X(qubits4[0]);
                H(qubits4[0]);
                RUScircuitV2(qubits4[0]);
                AssertProb([PauliZ], [qubits4[0]], Zero, 0.5, "Error: state after applying the Z-rotation must give Zero state with probability 0.5", 1e-10);
            }
        }
    }
}