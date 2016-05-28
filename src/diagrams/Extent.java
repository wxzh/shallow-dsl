package diagrams;

import diagrams.Family.Transform;
import lombok.Obj;

@Obj
interface Extent {
    Pos _p1();
    Pos _p2();
    default Extent union(Extent e) {
        return Extent.of(Pos.of(Math.min(_p1()._1(), e._p1()._1()), Math.min(_p1()._2(), e._p1()._2())),
                Pos.of(Math.max(_p2()._1(), e._p2()._1()), Math.max(_p2()._2(), e._p2()._2())));
    }
    default Extent transform(Transform t) {
        return Extent.of(t.transform(_p1()), t.transform(_p2()));
    }
    default String show() {
        return "(" + _p1().show() + "," + _p2().show() + ")";
    }
}