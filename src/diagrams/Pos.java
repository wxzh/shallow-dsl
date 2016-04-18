package diagrams;

import java.util.Arrays;
import java.util.List;

import lombok.Obj;

@Obj
interface Pos {
    double _1();
    double _2();
    default Pos add(Pos other) {
        return Pos.of(_1() + other._1(), _2() + other._2());
    }
    default Pos resize(double scale) {
        return Pos.of(scale*_1(), scale*_2());
    }
    default String show() {
        return _1() + "," + _2();
    }
    default List<Attr> toAttrs(String x, String y) {
        return Arrays.asList(Attr.of(x, ""+_1()), Attr.of(y, ""+_2()));
    }
    default Pos conjugate() {
        return Pos.of(_1(), -_2());
    }
}