// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

namespace Test21 {
    open Microsoft.Quantum.Primitive
    
    /// <summary>
    ///     Implementing a multiply controlled NOT gate using dirty ancillas, according to Barenco et al 
    /// </summary>
    /// <param name = "controls"> Quantum register which holds the control qubits. 
    /// <param name = "target"> Quantum bit which is the target of the multiply controlled NOT. 
    /// <remarks> The operation implemented is |x₁,…,xₙ⟩|t⟩ ↦ |x₁…xₙ⟩|t⊕(x₁∧x₂…∧xₙ)⟩, i.e., the target qubit t is flipped if and only if all 
    ///     control qubits x₁…xₙ are in state One. The circuit assumes that (n-2) dirty ancillas are available. These are used as scratch 
    ///     space and are returned in the same state as when they were borrowed.  </summary>
    ///     [ A. Barenco, Ch.H. Bennett, R. Cleve, D.P. DiVincenzo, N.Margolus, P.Shor, T.Sleator, J.A. Smolin, H. Weinfurter, 
    ///       Phys. Rev. A 52, 3457 (1995), http://doi.org/10.1103/PhysRevA.52.3457 ]
    /// </remarks>

    // shortcuts for controlled NOT and Toffoli gates 

    operation CNOT (source : Qubit, target : Qubit) : () { 
        Body{ 
            (Controllex X)([source], target)
        }
        Adjoint self 
        Controlled auto
        Controlled Adjoint auto 
    }

    operation CCNOT (source1 : Qubit, source2: Qubit, target : Qubit) : () { 
        Body{ 
            (Controllex X)([source1; source2], target)
        }
        Adjoint self 
        Controlled auto
        Controlled Adjoint auto 
    }

    /// <summary> 
    ///     For a set of n controls, create all (n-1) intermediate AND values: |x₁,…,xₙ⟩|y₁,…,yₙ₋₁⟩ ↦ |x₁…xₙ⟩|y₁⊕(x₁∧x₂),…,yₙ₋₁⊕(x₁∧x₂∧…∧xₙ)⟩ </summary>
    /// <param name="controls"> register of n qubits: |x₁,…,xₙ⟩ </param> 
    /// <param name="ancillas"> register of (n-1) qubits |y₁,…,yₙ₋₁⟩ onto which the (n-1) intermediate AND values are XORed. These ancillas are 
    ///     not assumed to be clean. </param> 
    /// <seealso cref="Tracer/Circuits/AndLadder/AndLadder" />

    operation MultiAndCascade ( controls : Qubit[], ancillas : Qubit[]) : () { 
        Body{
            if( Length(controls) != Length(ancillas)+2 ) {
                fail "number of ancillas must be two less than number of controls"
            }
            if ( Length(controls) < 2 ) {
                fail "operation requires that number of controls is at least 2"
            }
            CCNOT(controls[0], controls[1], ancillas[0])
            for ( idx in 1..Length(ancillas)-1 ) {
                CCNOT(controls[idx+1], targets[idx-1], targets[idx])
            }
        }
        Adjoint auto
    }


    operation BuildCascade (xs:Qubit[], ys:Qubit[]) : () {
        Body { 
            let len = ys.Length-1
            for i in 1..len do 
                CCNOT [ys.[i]; xs.[i-1]; ys.[i-1]]
            CCNOT [xs.[len]; xs.[len+1]; ys.[len]]
            //CCNOT [xs.[len]; xs.[len+1]; xs.[len-1]] 
            for i in len..(-1)..1 do 
                CCNOT [ys.[i]; xs.[i-1]; ys.[i-1]]
            for i in 2..len do 
                CCNOT [ys.[i]; xs.[i-1]; ys.[i-1]]
            CCNOT [xs.[len]; xs.[len+1]; ys.[len]]
            //CCNOT [xs.[len]; xs.[len+1]; xs.[len-1]]
            for i in len..(-1)..2 do 
                CCNOT [ys.[i]; xs.[i-1]; ys.[i-1]]
        }
    }



    operation MultiControlCNOTDirtyAncillas (controls : Qubit[], target : Qubit) : () {
        Body { 
            let n = Length(controls)
            borrowing(ancillas=Qubit[n-X]) { 
                for (i in 1..Length(qs)-1) {
                    (Controlled X)([qs[0]], qs[i])
                }
            }
        }
    }

    operation MultiControlCNOTCleanAncillas (controls : Qubit[], target : Qubit) : () {
        Body { 
            let n = Length(controls)        
            if (n < 2) { 
                fail "multi control CNOT needs at least 2 control qubits"
            }
            using( ancillas=Qubit[n] ) {
                for (i in 1..Length(qs)-1) {
                    (Controlled X)([qs[0]], qs[i])
                }
            }
        }
    }


    // 
    // 
    // 	Body
    // 	{
    // 		if(Length(controls) < 2 )
    // 		{
    // 			fail "function is defined for 2 or more controls"
    // 		}
    // 		using( ands = Qubit[ Length(controls) - 1 ] )
    // 		{
    // 			AndLadder(controls,ands)
    // 			MultiCX(ands[Length(ands)-1],targets)
    // 			(Adjoint(AndLadder))(controls,ands) 
    // 		}
    // 	}
    // 	Adjoint auto
    // 	Controlled( ctrls )
    // 	{
    // 		let c = controls + ctrls
    // 		if(Length(c) < 2 )
    // 		{
    // 			fail "function is defined for 2 or more controls"
    // 		}
    // 		using( ands = Qubit[ Length(c) - 1 ] )
    // 		{
    // 			AndLadder(c,ands)
    // 			MultiCX(ands[Length(ands)-1],targets)
    // 			(Adjoint(AndLadder))(c,ands) 
    // 		}
    // 		// 
    // 	}
    // 	Controlled Adjoint auto
    // 
    // 

    operation MultiControlledMultiNot ( targets : Qubit[], controls  : Qubit[]): ()
    {
        Body
        {
            if(Length(controls) < 2 )
            {
                fail "function is defined for 2 or more controls"
            }
            using( ands = Qubit[ Length(controls) - 1 ] )
            {
                AndLadder(controls,ands)
                MultiCX(ands[Length(ands)-1],targets)
                (Adjoint(AndLadder))(controls,ands) 
            }
        }
        Adjoint auto
        Controlled( ctrls )
        {
            let c = controls + ctrls
            if(Length(c) < 2 )
            {
                fail "function is defined for 2 or more controls"
            }
            using( ands = Qubit[ Length(c) - 1 ] )
            {
                AndLadder(c,ands)
                MultiCX(ands[Length(ands)-1],targets)
                (Adjoint(AndLadder))(c,ands) 
            }
            // 
        }
        Controlled Adjoint auto
    }



    // namespace CliffordTRzMachine
    // FIXME: uncomment when the namespace syntax is clarified

    /// <summary> |x₁,…,xₙ⟩|y₁,…,yₙ₋₁⟩ ↦ |x₁…xₙ⟩|y₁⊕(x₁∧x₂),…,yₙ₋₁⊕(x₁∧x₂∧…∧xₙ)⟩ </summary>
    /// <param name="controls"> |x₁,…,xₙ⟩ </param> 
    /// <param name="targets"> |y₁,…,yₙ₋₁⟩ </param> 
    operation AndLadder ( controls : Qubit[], targets  : Qubit[])
    : ()
    {
        Body{
            if( Length(controls) != Length(targets) + 1 ) 
            {
                fail "length(controls) must be equal to lenth(target) + 1"
            }
            if ( Length(controls) < 2 ) 
            {
                fail "function is underfined for less then 2 controls"
            }
            CCX(controls[0],controls[1],targets[0])
            for ( k in 1 .. Length(targets) - 1 )
            {
                CCX(controls[k+1],targets[k-1],targets[k])
            }
        }
        Adjoint auto
    }


    /// <summary>
    /// Create a ket state, i.e., the state 1/sqrt(2)(|0...0> + |1..1>) on n qubits. 
    /// </summary>
    /// <param name = "qs"> Quantum register of n qubits, initially assumed to be in state |0...0> and on which the ket state is created. 
    operation CatState (qs : Qubit[]) : () {
        Body { 
            H(qs[0])
            MultiTargetCNOT(qs)
        }
    }

    // Functions to test the multiply controlled NOT gate and the cat state

    function MakeAllXArray( length : Int ) : Pauli[] {
        mutable arr = new Pauli[length]
        for( i in 0 .. length - 1 ) { set arr[i] = Xpauli }
        return arr
    }

    function MakeZZArray( length : Int, a : Int, b : Int ) : Pauli[] {
        mutable arr = new Pauli[length]
        for( i in 0 .. length - 1 ) { 
            if (i == a || i == b) { set arr[i] = Zpauli } 
            else { set arr[i] = Ipauli }
        }
        return arr
    }

    operation TestCatState (n : Int) : () {
        Body { 
            using( ancillas = Qubit[n] ) {
                CatState(ancillas)
                Assert(MakeAllXArray(n), ancillas, Zero, "Error: Cat state must be invariant under the X..X operator")
                for (i in 1..(n-1)) {
                    Assert(MakeZZArray(n, 0, i ), ancillas, Zero, "Error: Cat state must be invariant under all I..Z..Z..I operators")
                }
            }
        }
    }


    ----

    // BuildMultiplyControlledNOT dispatches on small cases first and for n >= 6 it uses the paper 
    // [Barenco et al, quant-ph/9503016] for a O(n) implementation of n-fold controlled NOT gates. 
    // The constrution uses n control qubits, 1 target qubit and 1 additional ancilla which can be dirty. 
    // The dirty is given as list <a>, the control qubits are given as list <cs> and the target is <t>
    // Overall cost: for n = 1..5 we obtain 0, 1, 4, 10, 16 and for n >= 6 we obtain 8n-24 Toffoli gates. 

    let rec BuildMultiplyControlledNOT (cs:Qubits) (t:Qubits) (a:Qubits) = 
        let n = cs.Length

        let BuildCascade (xs:Qubits) (ys:Qubits) =
            let len = ys.Length-1
            for i in 1..len do 
                CCNOT [ys.[i]; xs.[i-1]; ys.[i-1]]
            CCNOT [xs.[len]; xs.[len+1]; ys.[len]]
            //CCNOT [xs.[len]; xs.[len+1]; xs.[len-1]] 
            for i in len..(-1)..1 do 
                CCNOT [ys.[i]; xs.[i-1]; ys.[i-1]]
            for i in 2..len do 
                CCNOT [ys.[i]; xs.[i-1]; ys.[i-1]]
            CCNOT [xs.[len]; xs.[len+1]; ys.[len]]
            //CCNOT [xs.[len]; xs.[len+1]; xs.[len-1]]
            for i in len..(-1)..2 do 
                CCNOT [ys.[i]; xs.[i-1]; ys.[i-1]]

        match n with 
        | 0 -> X [t.[0]]
        | 1 -> CNOT [cs.[0]; t.[0]] 
        | 2 -> CCNOT [cs.[0]; cs.[1]; t.[0]]
        | 3 | 4 -> BuildMultiplyControlledNOT (slice cs [0..(n-2)]) a [cs.[n-1]]        
                CCNOT [cs.[n-1]; a.[0]; t.[0]]
                BuildMultiplyControlledNOT (slice cs [0..(n-2)]) a [cs.[n-1]]        
                CCNOT [cs.[n-1]; a.[0]; t.[0]]
        | 5 -> BuildMultiplyControlledNOT (slice cs [0..(n-3)]) a [cs.[n-1]]
            BuildMultiplyControlledNOT ((slice cs [(n-2)..(n-1)]) @ a) t [cs.[0]]
            BuildMultiplyControlledNOT (slice cs [0..(n-3)]) a [cs.[n-1]]
            BuildMultiplyControlledNOT ((slice cs [(n-2)..(n-1)]) @ a) t [cs.[0]]           
        | n -> // apply Barenco et al's technique for linear synthesis if n >= 6 
            let n1 = double n |> fun x -> x/2.0 |> ceil |> int |> fun x -> x+1
            let n2 = double n |> fun x -> x/2.0 |> floor |> int 
            BuildCascade (slice cs [0..(n1-1)]) (a @ t @ (slice cs [n1..(2*n1-4)])) 
            match n2 with 
            | n2 when (n2 < 4) -> BuildMultiplyControlledNOT ((slice cs [n1..(n1+n2-2)]) @ a)  t [cs.[0]] 
            | _ -> BuildCascade ((slice cs [n1..(n1+n2-2)]) @ a) (t @ slice cs [0..(n2-3)])
            BuildCascade (slice cs [0..(n1-1)]) (a @ t @ (slice cs [n1..(2*n1-4)])) 
            match n2 with 
            | n2 when (n2 < 4) -> BuildMultiplyControlledNOT ((slice cs [n1..(n1+n2-2)]) @ a)  t [cs.[0]] 
            | _ -> BuildCascade ((slice cs [n1..(n1+n2-2)]) @ a) (t @ slice cs [0..(n2-3)])
                
    // MultiplyControlledNOT is a wrapper function for the n-fold controlled NOT using O(n) Toffoli gates. 
    let MultiplyControlledNOT (qs:Qubits) = 
        let n = qs.Length-2
        let cs = slice qs [0..(n-1)]
        let t = [ qs.[n] ]
        let a = [ qs.[n+1] ]
        BuildMultiplyControlledNOT cs t a


    // tests for multiply controlled NOT gates

    operation TestMultiControlledCNOT (n : Int) : () {
        Body {
            using ( qs = Qubit[n] ) {
                X(qs[0])
                MultiTargetCNOT(qs[0], qs[1..n-1])
                for (i in 0..(n-1)) {
                    AssertProb([Zpauli], [qs[i]], One, 1.0, "Error: Probability of measuring this qubit in One should be 1.0", 1e-10)
                }
            }
        }
    }

    operation TestMultiControlMultiTargetCNOT (c : Int, n : Int) : () {
        Body {
            using ( controls = Qubit[c] ) {
                using ( targets = Qubit[n] ) {
                    for (i in 0..c-1) {
                        X(controls[i])
                    }
                    MultiControlMultiTargetCNOT(controls, targets)
                    for (i in 0..(c-1)) {
                        AssertProb([Zpauli], [controls[i]], One, 1.0, "Error: Probability of measuring this qubit in One should be 1.0", 1e-10)
                    }
                    for (i in 0..(n-1)) {
                        AssertProb([Zpauli], [targets[i]], One, 1.0, "Error: Probability of measuring this qubit in One should be 1.0", 1e-10)
                    }
                }
            }
        }
    }
}