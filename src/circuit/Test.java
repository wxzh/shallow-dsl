package circuit;

import static circuit.CircuitDSL.fan;
import static circuit.CircuitDSL.identity;

import java.util.Arrays;

import circuit.CircuitDSL.Above;
import circuit.CircuitDSL.Beside;
import circuit.CircuitDSL.Circuit;
import circuit.CircuitDSL.Fan;
import circuit.CircuitDSL.Identity;
import circuit.CircuitDSL.Stretch;

public class Test {
    public static void main(String[] args) {
        // Figure 3
        Circuit c3 = fan(2).beside(identity(1))
                .above(identity(1).beside(fan(2)));
        // Figure 4
        Circuit c4 = fan(3).stretch(3,2,3);
        Circuit c4r = fan(3).rStretch(2,3,1);
        // Figure 1
        Circuit c1 =
                Above.of(
                        Above.of(
                                Beside.of(fan(2), Fan.of(2)),
                                Stretch.of(Fan.of(2), IntList.of(Arrays.asList(2,2)))),
                        Beside.of(
                                Beside.of(
                                        Identity.of(1),
                                        Fan.of(2)),
                                Identity.of(1)));
        fan(2).beside(fan(2))
        .above(fan(2).stretch(2,2))
        .above(identity(1).beside(fan(2)).beside(identity(1)))
        .draw();
    }
}
