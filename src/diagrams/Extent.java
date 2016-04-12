package diagrams;

import java.util.function.Function;

import lombok.Obj;

@Obj
interface Extent {
    Pos p1();
    Pos p2();
    default Extent union(Extent e) {
        return Extent.of(Pos.of(Math.min(p1().x(), e.p1().x()), Math.min(p1().y(), e.p1().y())),
                Pos.of(Math.max(p2().x(), e.p2().x()), Math.max(p2().y(), e.p2().y())));
    }
    default Extent transform(Function<Pos, Pos> t) {
        return Extent.of(t.apply(p1()), t.apply(p2()));
    }
    default String show() {
        return "(" + p1().show() + "," + p2().show() + ")";
    }
}