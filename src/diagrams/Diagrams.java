package diagrams;

import static java.util.Arrays.asList;
import static java.util.Collections.emptyList;
import static java.util.Collections.singletonList;
import static java.util.stream.Collectors.joining;
import static java.util.stream.Collectors.toList;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;
import java.util.function.UnaryOperator;
import java.util.stream.IntStream;
import java.util.stream.Stream;

import lombok.Obj;

@Obj
interface Family {
    interface Shape {
        Extent toExtent();
        XML toXML(List<Attr> styleAttrs, Function<Pos, Pos> trans);
        String show();
        default Drawing draw(Styling... styles) {
            return draw(StyleSheet.of(asList(styles)));
        }
        default Drawing draw(StyleSheet sheet) {
            return Drawing.of(singletonList(this), singletonList(sheet), singletonList(p -> p));
        }
    }

    interface Rectangle extends Shape {
        double _width();
        double _height();
        default Extent toExtent() {
            return Extent.of(Pos.of(_width(), _height()).resize(-0.5), Pos.of(_width(), _height()).resize(0.5));
        }
        default XML toXML(List<Attr> styleAttrs, Function<Pos, Pos> trans) {
            List<Attr> attrs = new ArrayList<>(trans.apply(Pos.of(_width(), _height()).resize(-0.5)).toAttrs("x", "y"));
            attrs.addAll(Pos.of(_width(), _height()).toAttrs("width", "height"));
            attrs.addAll(styleAttrs);
            return XML.of(attrs, "rect", emptyList());
        }
        default String show() {
            return "Rectangle " + _width() + " " + _height();
        }
    }

    interface Ellipse extends Shape {
        double _rx();
        double _ry();
        @Override
        default Extent toExtent() {
            return Extent.of(Pos.of(-_rx(), -_ry()), Pos.of(_rx(), _ry()));
        }
        default XML toXML(List<Attr> styleAttrs, Function<Pos, Pos> trans) {
            List<Attr> attrs = new ArrayList<>(trans.apply(Pos.of(0, 0)).toAttrs("cx", "cy"));
            attrs.addAll(Pos.of(_rx(), _ry()).toAttrs("rx", "ry"));
            attrs.addAll(styleAttrs);
            return XML.of(attrs, "ellipse", emptyList());
        }
        @Override
        default String show() {
            return "Ellipse " + _rx() + " " + _ry();
        }
    }
    interface Triangle extends Shape {
        double _length();
        default Extent toExtent() {
            double y = Math.sqrt(3)/4 * _length();
            return Extent.of(Pos.of(-_length()/2, -y), Pos.of(_length()/2, y));
        }
        default XML toXML(List<Attr> styleAttrs, Function<Pos, Pos> trans) {
            double h = Math.sqrt(3)/4 * _length();
            List<Attr> attrs = new ArrayList<>();
            attrs.add(Attr.of("points", Stream.of(Pos.of(-_length()/2, -h), Pos.of(_length()/2, -h), Pos.of(0, h))
                    .map(pos -> trans.apply(pos).show())
                    .reduce("", (s1, s2) -> s1 + " " + s2)));
            attrs.addAll(styleAttrs);
            return XML.of(attrs, "polygon", emptyList());
        }
        default String show() {
            return "Triangle " + _length();
        }
    }

    interface StyleSheet {
        List<Styling> _stylings();
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

    interface Col {
        String show();
    }
    interface Red extends Col {
        default String show() { return "red"; }
    }
    interface Blue extends Col {
        default String show() { return "blue"; }
    }
    interface Green extends Col {
        default String show() { return "green"; }
    }
    interface Yellow extends Col {
        default String show() { return "yellow"; }
    }
    interface Bisque extends Col {
        default String show() { return "bisque"; }
    }
    interface Black extends Col {
        default String show() { return "black"; }
    }

    interface Drawing {
        List<Function<Pos, Pos>> _transforms();
        List<Shape> _shapes(); // wildcards could be used for extensibility of shapes?
        // List<? extends Shape> shapes();
        List<StyleSheet> _styles();

        default Drawing above(Drawing other) {
            Extent e1 = toExtent();
            Extent e2 = other.toExtent();
            Drawing t1 = transform(Pos.of(0, e2._p2()._2())::add);
            Drawing t2 = other.transform(Pos.of(0, e1._p1()._2())::add);
            return t1.merge(t2);
        }

        default Drawing beside(Drawing other) {
            Drawing t1 = transform(Pos.of(other.toExtent()._p1()._1(), 0)::add);
            Drawing t2 = other.transform(Pos.of(toExtent()._p2()._1(), 0)::add);
            return t1.merge(t2);
        }

        default Drawing inFrontOf(Drawing other) {
            return other.merge(this);
        }

        default Drawing flip() {
            Extent e = toExtent();
            return Drawing.of(_shapes(), _styles(), _transforms());
        }

        default Extent toExtent() {
            return IntStream.range(0, _shapes().size())
                    .mapToObj(i -> _shapes().get(i).toExtent().transform(_transforms().get(i)))
                    .reduce(Extent::union).get();
        }
        default Drawing transform(UnaryOperator<Pos> trans) {
            return Drawing.of(_shapes(), _styles(), _transforms().stream().map(t1 -> t1.andThen(trans)).collect(toList()));
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
                            .collect(toList());
            return XML.of(svgAttrs, "svg",
                    singletonList(XML.of(singletonList(Attr.of("transform", "scale(" + Pos.of(1,-1).resize(scale).show() + ")")), "g", shapeXMLs)));
        }
        default String show() {
            return IntStream.range(0, _shapes().size()).mapToObj(i -> "(" + _transforms().get(i).toString() + _shapes().get(i).show() + ")").collect(joining(",", "[", "]"));
        }
    }

    static <E> List<E> concat(List<E> xs, List<E> ys) {
        List<E> tmp = new ArrayList<>(xs);
        tmp.addAll(ys);
        return tmp;
    }

    static Rectangle rectangle(double x, double y) {
        return Rectangle.of(y, x);
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

    static Col blue = Blue.of();
    static Col black = Black.of();
    static Col bisque = Bisque.of();
    static Col red = Red.of();
    static Col green = Green.of();

    static Drawing human() {
        StyleSheet sheet = styleSheet(fillColor(blue), strokeWidth(0));
        Drawing head = ellipse(3, 3).draw(strokeWidth(0.1), strokeColor(black), fillColor(bisque));
        Drawing arms = rectangle(1, 10).draw(fillColor(red), strokeWidth(0));
        Drawing upper = triangle(10).draw(fillColor(red), strokeWidth(0));
        Drawing leg = rectangle(5, 1).draw(sheet);
        Drawing foot = rectangle(1, 2).draw(sheet);
        Drawing legs = leg.beside(rectangle(5, 2).draw(strokeWidth(0))).beside(leg);
        Drawing foots = foot.beside(rectangle(1, 2).draw(strokeWidth(0))).beside(foot);
        Drawing human = head.above(arms).above(upper).above(legs).above(foots);
        return human;
    }
}

public class Diagrams {
    public static void main(String[] args) {
        Path file = Paths.get("human.svg");
        Family.Drawing drawing = Family.human();
        XML xml = drawing.toXML();
        System.out.println(drawing.show());
        try {
            Files.write(file, asList(xml.show()));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}