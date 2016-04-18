package circuit;

import java.util.function.IntUnaryOperator;

import lombok.Obj;

@Obj
public interface IntPair {
    int _1();
    int _2();

    default String show() {
        return "(" + _1() + "," + _2() + ")";
    }
    default IntPair map(IntUnaryOperator f) {
        return IntPair.of(f.applyAsInt(_1()), f.applyAsInt(_2()));
    }
}