package circuit;

import java.util.function.IntUnaryOperator;

import lombok.Obj;

@Obj
public interface IntPair {
    int x();
    int y();

    default String show() {
        return "(" + x() + "," + y() + ")";
    }
    default IntPair map(IntUnaryOperator f) {
        return IntPair.of(f.applyAsInt(x()), f.applyAsInt(y()));
    }
}