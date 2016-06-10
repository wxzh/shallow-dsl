package circuit;

import static circuit.CircuitDSL.fan;
import static circuit.CircuitDSL.id;

import circuit.CircuitDSL.Circuit;

public class Test {
    public static void main(String[] args) {
        Circuit circuit =
            fan(2).beside(fan(2))
            .above(fan(2).stretch(2,2))
            .above(id(1).beside(fan(2)).beside(id(1)));
//        circuit.width();
//        circuit.depth();
//        circuit.layout();
//        circuit.tlayout(f)
        circuit.draw();
    }
}
