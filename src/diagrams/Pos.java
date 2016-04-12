package diagrams;

import static java.util.Arrays.asList;

import java.util.List;

import lombok.Obj;

@Obj
interface Pos {
    double x();
    double y();
    default Pos add(Pos other) {
        return Pos.of(x() + other.x(), y() + other.y());
    }
    default Pos resize(double scale) {
        return Pos.of(scale*x(), scale*y());
    }
    default String show() {
        return x() + "," + y();
    }
    default List<Attr> toAttrs(String x, String y) {
        return asList(Attr.of(x, ""+x()), Attr.of(y, ""+y()));
    }
    default Pos conjugate() {
        return Pos.of(x(), -y());
    }
}