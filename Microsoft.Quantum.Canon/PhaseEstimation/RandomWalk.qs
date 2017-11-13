// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

namespace Microsoft.Quantum.Canon {
    open Microsoft.Quantum.Primitive;
    open Microsoft.Quantum.Extensions.Math;

    // NB: we take std.dev instead of variance here to avoid having to take a square root.
    // FIXME: this currently passes a double to the oracle, as is only appropriate for
    //        continuous-time oracles.
    /// <summary>
    ///     Performs iterative phase estimation using a random walk to approximate
    ///     Bayesian inference on the classical measurement results from a given
    ///     oracle and eigenstate.
    /// </summary>
    /// <param name="oracle">
    ///     An operation representing a unitary $U$ such that $U(t)\ket{\phi} = e^{i t \phi}\ket{\phi}$
    ///     for a known eigenstate $\ket{\phi}$ and an unknown phase $\phi \in \mathbb{R}^+$.
    /// </param>
    /// <param name="eigenstate">A register in the state $\ket{\phi}$</param>.
    /// <param name="controlQubit">A single qubit initially in $\ket{0}$, suitale for controlling $U$.</param>
    /// <param name="initialMean">Mean of the initial normal prior distribution over $\phi$.</param>
    /// <param name="initialStdDev">Standard deviation of the initial normal prior distribution over $\phi$.</param>
    /// <param name="nMeasurements">Number of measurements to be accepted into the final posterior estimate.</param>
    /// <param name="maxMeasurements">Total number of measurements than can be taken before the operation is considered to have failed.</param>
    /// <param name="unwind">Number of results to forget when consistency checks fail.</param>
    // TODO: document return type.
    operation RandomWalkPhaseEstimation( oracle : ContinuousOracle, eigenstate : Qubit[], controlQubit : Qubit, initialMean : Double, initialStdDev : Double, nMeasurements : Int, maxMeasurements : Int, unwind : Int)  : Double
    {
        body {
            let PREFACTOR = 0.79506009762065011;
            let INV_SQRT_E = 0.60653065971263342;

            let sampleOp = PrepAndMeasurePhaseEstImpl(_, _, ContinuousPhaseEstimationIteration(oracle, _, _, eigenstate, _));

            mutable dataRecord = StackNew(nMeasurements);

            mutable mu = 0.1;
            mutable sigma = 1.1;
            mutable datum = Zero;
            mutable nTotalMeasurements = 0;
            mutable nAcceptedMeasurements = 0;

            set mu = 0.0;
            set sigma = 1.0;

            repeat {
                if (nTotalMeasurements >= maxMeasurements) {
                    return mu;
                }

                let wInv = mu - PI() * sigma / 2.0;
                let t = 1.0 / sigma;

                set datum = sampleOp(wInv, t);
                set nTotalMeasurements = nTotalMeasurements + 1;

                if (datum == Zero) {
                    set mu = mu - sigma * INV_SQRT_E;
                } else {
                    set mu = mu + sigma * INV_SQRT_E;
                }
                set sigma = sigma * PREFACTOR;

                set dataRecord = StackPush(dataRecord, datum);

                // Perform consistency check.
                if (nTotalMeasurements >= maxMeasurements) {
                    return mu;
                }
                mutable checkDatum = sampleOp(mu, 1.0 / sigma);
                set nTotalMeasurements = nTotalMeasurements + 1;

                if (checkDatum == One) {
                    repeat {
                        for (idxUnwind in 0..(unwind - 1)) {

                            set sigma = sigma / PREFACTOR;

                            if (StackLength(dataRecord) > 0) {
                                let unwoundDatum = StackPeek(dataRecord);
                                set dataRecord = StackPop(dataRecord);

                                if (unwoundDatum == Zero) {
                                    set mu = mu + sigma * INV_SQRT_E;
                                } else {
                                    set mu = mu - sigma * INV_SQRT_E;
                                }
                            }
                        }

                        if (nTotalMeasurements >= maxMeasurements) {
                            return mu;
                        }
                        set checkDatum = sampleOp(mu, 1.0 / sigma);
                        set nTotalMeasurements = nTotalMeasurements + 1;

                    } until (checkDatum == Zero) fixup {
                    }
                }

                set nAcceptedMeasurements = nAcceptedMeasurements + 1;
            } until (nAcceptedMeasurements >= nMeasurements) fixup {}

            return mu;
        }
    }

}