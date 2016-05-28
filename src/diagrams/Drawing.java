package diagrams;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import diagrams.Family.Compose;
import diagrams.Family.Shape;
import diagrams.Family.Transform;
import lombok.Obj;

@Obj
interface Drawing {
    List<Transform> _transforms();
    List<Shape> _shapes();
    List<StyleSheet> _styles();

    default Extent toExtent() {
        return IntStream.range(0, _shapes().size())
            .mapToObj(i -> _shapes().get(i).toExtent().transform(_transforms().get(i)))
            .reduce(Extent::union)
            .get();
    }
    default Drawing transform(Transform trans) {
        return Drawing.of(_shapes(), _styles(), _transforms().stream().map(t1 -> Compose.of(trans, t1)).collect(Collectors.toList()));
    }
    default Drawing merge(Drawing other) {
        return Drawing.of(concat(_shapes(), other._shapes()), concat(_styles(), other._styles()), concat(_transforms(), other._transforms()));
    }
    default XML toXML() {
        int scale = 10;
        Extent e = toExtent();
        Pos p1 = e._p1();
        Pos p2 = e._p2();
        Pos p = Pos.of(p2._1()-p1._1(), p2._2()-p1._2()).resize(scale);
        List<Attr> svgAttrs = new ArrayList<>(p.toAttrs("width", "height"));
        svgAttrs.add(Attr.of("viewBox", p1.resize(scale).show() + "," + p.show()));
        svgAttrs.add(Attr.of("xmlns", "http://www.w3.org/2000/svg"));
        svgAttrs.add(Attr.of("version", "1.1"));

        List<XML> shapeXMLs = IntStream.range(0, _shapes().size())
                .mapToObj(i -> _shapes().get(i).toXML(_styles().get(i)._toAttrs(), _transforms().get(i)))
                .collect(Collectors.toList());
        return XML.of(svgAttrs, "svg", Collections.singletonList(XML.of(Collections.singletonList(Attr.of("transform", "scale(" + Pos.of(1,-1).resize(scale).show() + ")")), "g", shapeXMLs)));
    }

    static <E> List<E> concat(List<E> xs, List<E> ys) {
        List<E> tmp = new ArrayList<>(xs);
        tmp.addAll(ys);
        return tmp;
    }
}