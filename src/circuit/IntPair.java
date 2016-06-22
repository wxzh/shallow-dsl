package circuit;

import java.util.function.IntUnaryOperator;

import lombok.Obj;

@Obj
public interface IntPair {
    int _x();
    int _y();

    default String show() {
        return "(" + _x() + "," + _y() + ")";
    }
    default IntPair map(IntUnaryOperator f) {
        return IntPair.of(f.applyAsInt(_x()), f.applyAsInt(_y()));
    }
}