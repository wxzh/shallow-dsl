package diagrams;

import static diagrams.ListUtilities.concat;
import static java.util.Arrays.asList;
import static java.util.Collections.emptyList;
import static java.util.Collections.singletonList;
import static java.util.stream.Collectors.joining;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.util.stream.Stream;

import diagrams.Debug.Above;
import diagrams.Debug.Beside;
import diagrams.Debug.Bisque;
import diagrams.Debug.Black;
import diagrams.Debug.Blue;
import diagrams.Debug.Col;
import diagrams.Debug.Ellipse;
import diagrams.Debug.FillColor;
import diagrams.Debug.Green;
import diagrams.Debug.Picture;
import diagrams.Debug.Place;
import diagrams.Debug.Rectangle;
import diagrams.Debug.Red;
import diagrams.Debug.Shape;
import diagrams.Debug.StrokeColor;
import diagrams.Debug.StrokeWidth;
import diagrams.Debug.StyleSheet;
import diagrams.Debug.Styling;
import diagrams.Debug.Triangle;
import lombok.Obj;


interface Show {
    String show();
    static String showList(List<? extends Show> xs) {
        return xs.stream().map(x -> x.show()).collect(Collectors.joining(",", "[", "]"));
    }
}

@Obj
interface Attr extends Show {
    String _name();
    String _value();
    default String show() {
        return _name() + "=\"" + _value() + "\"";
    }
}

@Obj
interface Extent extends Show {
    Pos _p1();
    Pos _p2();
    default Extent union(Extent e) {
        return Extent.of(Pos.of(Math.min(_p1()._1(), e._p1()._1()), Math.min(_p1()._2(), e._p1()._2())),
                Pos.of(Math.max(_p2()._1(), e._p2()._1()), Math.max(_p2()._2(), e._p2()._2())));
    }
    default String show() {
        return "(" + _p1().show() + "," + _p2().show() + ")";
    }
}

@Obj
interface XML extends Show {
    String _tag();
    List<Attr> _attrs();
    List<XML> _xmls();

    default String show() {
        String attrs = " " + _attrs().stream().map(Attr::show).collect(joining(" "));
        if (_xmls().size() == 0)
            return "<" + _tag() + attrs + "/>";
        else
            return "<" + _tag() + attrs + ">\n" +
                _xmls().stream().map(XML::show).collect(joining("\n")) + "\n</" + _tag() + ">";
    }
}

@Obj
interface Pos extends Show {
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
@Obj
interface Family {
    /**
     * Shape
     */
    interface Shape {
        Extent toExtent();
        XML toXML(List<Attr> styleAttrs, Transform trans);
    }

    interface Rectangle extends Shape {
        double _x();
        double _y();
        @Override default Extent toExtent() {
            return Extent.of(Pos.of(_x(), _y()).resize(-0.5), Pos.of(_x(), _y()).resize(0.5));
        }
        @Override default XML toXML(List<Attr> styleAttrs, Transform trans) {
            List<Attr> attrs = new ArrayList<>(trans.transform(Pos.of(_x(), _y()).resize(-0.5)).toAttrs("x", "y"));
            attrs.addAll(Pos.of(_x(), _y()).toAttrs("width", "height"));
            attrs.addAll(styleAttrs);
            return XML.of(attrs, "rect", emptyList());
        }
    }

    interface Ellipse extends Shape {
        double _rx();
        double _ry();
        @Override
        default Extent toExtent() {
            return Extent.of(Pos.of(-_rx(), -_ry()), Pos.of(_rx(), _ry()));
        }
        @Override default XML toXML(List<Attr> styleAttrs, Transform trans) {
            List<Attr> attrs = new ArrayList<>(trans.transform(Pos.of(0, 0)).toAttrs("cx", "cy"));
            attrs.addAll(Pos.of(_rx(), _ry()).toAttrs("rx", "ry"));
            attrs.addAll(styleAttrs);
            return XML.of(attrs, "ellipse", emptyList());
        }
    }

    interface Triangle extends Shape {
        double _l();
        @Override default Extent toExtent() {
            double y = Math.sqrt(3)/4 * _l();
            return Extent.of(Pos.of(-_l()/2, -y), Pos.of(_l()/2, y));
        }
        @Override default XML toXML(List<Attr> styleAttrs, Transform trans) {
            double h = Math.sqrt(3)/4 * _l();
            List<Attr> attrs = new ArrayList<>();
            attrs.add(Attr.of("points", Stream.of(Pos.of(-_l()/2, -h), Pos.of(_l()/2, -h), Pos.of(0, h))
                    .map(pos -> trans.transform(pos).show())
                    .reduce("", (s1, s2) -> s1 + " " + s2)));
            attrs.addAll(styleAttrs);
            return XML.of(attrs, "polygon", emptyList());
        }
    }

    /**
     * Styling
     */
    interface StyleSheet {
        List<? extends Styling> _stylings();
        default List<Attr> _toAttrs() {
            boolean hasFill = false;
            List<Attr> attrs = new ArrayList<>();
            for (Styling s : _stylings()) {
                Attr attr = s.toAttr();
                if (attr._name().equals("fill")) hasFill = true;
                attrs.add(attr);
            }
            if (!hasFill) attrs.add(Attr.of("fill", "none"));
            return attrs;
        }
    }

    interface Styling {
        Attr toAttr();
    }

    interface FillColor extends Styling {
        Col _color();
        default Attr toAttr() {
            return Attr.of("fill", _color().show());
        }
    }

    interface StrokeColor extends Styling {
        Col _color();
        default Attr toAttr() {
            return Attr.of("stroke", _color().show());
        }
    }

    interface StrokeWidth extends Styling {
        double _width();
        default Attr toAttr() {
            return Attr.of("stroke-width", ""+_width());
        }
    }

    /**
     * Color
     */
    interface Col {
        String show();
    }

    interface Red extends Col {
        @Override default String show() { return "red"; }
    }

    interface Blue extends Col {
        @Override default String show() { return "blue"; }
    }

    interface Green extends Col {
        @Override default String show() { return "green"; }
    }

    interface Yellow extends Col {
        @Override default String show() { return "yellow"; }
    }
    interface Bisque extends Col {
        @Override default String show() { return "bisque"; }
    }
    interface Black extends Col {
        @Override default String show() { return "black"; }
    }

    /**
     *  Picture
     */
    interface Picture {
        Drawing draw();
    }

    interface Place extends Picture {
        Shape _s();
        StyleSheet _ss();
        @Override default Drawing draw() {
          return Drawing.of(singletonList(_s()), singletonList(_ss()), singletonList(Identity.of()));
        }
    }

    interface Above extends Picture {
        Picture _p1();
        Picture _p2();
        @Override default Drawing draw() {
            Drawing d1 = _p1().draw();
            Drawing d2 = _p2().draw();
            Extent e1 = d1.toExtent();
            Extent e2 = d2.toExtent();
            Drawing t1 = d1.transform(Translate.of(Pos.of(0, e2._p2()._2())));
            Drawing t2 = d2.transform(Translate.of(Pos.of(0, e1._p1()._2())));
            return t1.merge(t2);
        }
    }

    interface Beside extends Picture {
        Picture _p1();
        Picture _p2();
        @Override default Drawing draw() {
            Drawing d1 = _p1().draw();
            Drawing d2 = _p2().draw();
            Drawing t1 = d1.transform(Translate.of(Pos.of(d2.toExtent()._p1()._1(), 0)));
            Drawing t2 = d2.transform(Translate.of(Pos.of(d1.toExtent()._p2()._1(), 0)));
            return t1.merge(t2);
        }
    }

    /**
     * Transform
     */
    interface Transform {
        Pos transform(Pos pos);
    }

    interface Identity extends Transform {
        @Override default Pos transform(Pos pos) {
            return pos;
        }
    }

    interface Translate extends Transform {
        Pos _pos();
        @Override default Pos transform(Pos pos) {
            return _pos().add(pos);
        }
    }

    interface Compose extends Transform {
        Transform _t1();
        Transform _t2();
        @Override default Pos transform(Pos pos) {
            return _t1().transform(_t2().transform(pos));
        }
    }

    interface Drawing {
        List<? extends Transform> _transforms();
        List<? extends Shape> _shapes();
        List<? extends StyleSheet> _styles();

        default Extent toExtent() {
            return IntStream.range(0, _shapes().size())
                .mapToObj(i -> {
                  Extent e = _shapes().get(i).toExtent();
                  Transform trans = _transforms().get(i);
                  return Extent.of(trans.transform(e._p1()), trans.transform(e._p2())); })
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
            return XML.of(svgAttrs, "svg", singletonList(XML.of(singletonList(Attr.of("transform", "scale(" + Pos.of(1,-1).resize(scale).show() + ")")), "g", shapeXMLs)));
        }

    }
}

@Obj interface Debug extends Family {
    interface Shape extends Show {}

    interface Rectangle {
        @Override default String show() {
            return "(rectangle " + _x() + " " + _y() + ")";
        }
    }
    interface Ellipse {
        @Override default String show() {
            return "(ellipse " + _rx() + " " + _ry() + ")";
        }
    }

    interface Triangle {
        @Override default String show() {
            return "(triangle " + _l() + ")";
        }
    }

    interface Picture extends Show {
        @Override Drawing draw(); // bug: no refinement
    }

    interface Place {
        @Override default String show() {
            return "(place " + _s().show() + " " + _ss().show() + ")";
        }
        @Override default Drawing draw() {
          return Drawing.of(singletonList(_s()), singletonList(_ss()), singletonList(Identity.of()));
        }
    }

    interface Beside {
        Picture _p1();
        @Override default String show() {
            return "(beside " + _p1().show() + " " + _p2().show() + ")";
        }
        @Override default Drawing draw() {
            Drawing d1 = _p1().draw();
            Drawing d2 = _p2().draw();
            Drawing t1 = d1.transform(Translate.of(Pos.of(d2.toExtent()._p1()._1(), 0)));
            Drawing t2 = d2.transform(Translate.of(Pos.of(d1.toExtent()._p2()._1(), 0)));
            return t1.merge(t2);
        }
    }

    interface Above {
        @Override default String show() {
            return "(above " + _p1().show() + " " + _p2().show() + ")";
        }
        @Override default Drawing draw() {
            Drawing d1 = _p1().draw();
            Drawing d2 = _p2().draw();
            Extent e1 = d1.toExtent();
            Extent e2 = d2.toExtent();
            Drawing t1 = d1.transform(Translate.of(Pos.of(0, e2._p2()._2())));
            Drawing t2 = d2.transform(Translate.of(Pos.of(0, e1._p1()._2())));
            return t1.merge(t2);
        }
    }

    interface StyleSheet extends Show {
        @Override default String show() {
            return Show.showList(_stylings());
        }
    }

    interface Styling extends Show {}

    interface StrokeColor {
        @Override default String show() {
            return "StrokeColor " + _color().show();
        }
    }
    interface StrokeWidth {
        @Override default String show() {
            return "StrokeWidth " + _width();
        }
    }
    interface FillColor {
        @Override default String show() {
            return "FillColor " + _color().show();
        }
    }

    interface Transform extends Show {}
    interface Identity {
        @Override default String show() {
            return "identity";
        }
    }
    interface Compose {
        @Override default String show() {
            return "(" + _t1().show() + "," + _t2().show() + ")";
        }
    }
    interface Translate {
        @Override default String show() {
            return "translate " + _pos().show();
        }
    }

    interface Drawing extends Show {
        @Override default String show() {
            return "shapes: " + Show.showList(_shapes()) + "\n"
                    + "style sheets: " + Show.showList(_styles()) + "\n"
                    + "transforms: " + Show.showList(_transforms()) + "\n";
        }

        default Drawing transform(Transform trans) {
            return Drawing.of(_shapes(), _styles(), _transforms().stream().map(t1 -> Compose.of(trans, t1)).collect(Collectors.toList()));
        }
        default Drawing merge(Drawing other) {
            return Drawing.of(concat(_shapes(), other._shapes()), concat(_styles(), other._styles()), concat(_transforms(), other._transforms()));
        }
    }
}

public class Diagrams {
    /**
     * Wrappers
     */
    static Debug.Rectangle rectangle(double x, double y) {
        return Rectangle.of(x, y);
    }

    static Ellipse ellipse(double rx, double ry) {
        return Ellipse.of(rx, ry);
    }

    static Ellipse circle(double x) {
        return Ellipse.of(x, x);
    }

    static Triangle triangle(double length) {
        return Triangle.of(length);
    }

    static StyleSheet styleSheet(Styling... stylings) {
        return StyleSheet.of(asList(stylings));
    }

    static Styling fillColor(Col col) {
        return FillColor.of(col);
    }

    static Styling strokeWidth(double w) {
        return StrokeWidth.of(w);
    }

    static Styling strokeColor(Col col) {
        return StrokeColor.of(col);
    }

    static Picture place(Shape shape, Styling... styleSheet) {
        return Place.of(shape, styleSheet(styleSheet));
    }

    static Picture beside(Picture p1, Picture p2) {
        return Beside.of(p1, p2);
    }

    static Picture above(Picture p1, Picture p2) {
        return Above.of(p1, p2);
    }

    static Col blue = Blue.of();
    static Col black = Black.of();
    static Col bisque = Bisque.of();
    static Col red = Red.of();
    static Col green = Green.of();

    static Picture woman() {
        Picture head = place(ellipse(3,3), strokeWidth(0.1), strokeColor(black), fillColor(bisque));
        Picture arms = place(rectangle(10,1), fillColor(red), strokeWidth(0));
        Picture upper = place(triangle(10), fillColor(red), strokeWidth(0));
        Picture leg = place(rectangle(1,5), fillColor(blue), strokeWidth(0));
        Picture foot = place(rectangle(2,1), fillColor(blue), strokeWidth(0));
        return above(head, above(arms, above(upper,above(
                beside(leg, beside(place(rectangle(2,5), strokeWidth(0)), leg)),
                beside(foot, beside(place(rectangle(2,1), strokeWidth(0)), foot))))));

    }

    public static void main(String[] args) {
        Path file = Paths.get("woman.svg");
        System.out.println(woman().draw().show());
        XML xml = woman().draw().toXML();
        try {
            Files.write(file, asList(xml.show()));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}