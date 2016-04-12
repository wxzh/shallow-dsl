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
        Extent _toExtent();
        XML _toXML(List<Attr> styleAttrs, Function<Pos, Pos> trans);
        String _show();
        default Drawing draw(Styling... styles) {
            return draw(StyleSheet.of(asList(styles)));
        }
        default Drawing draw(StyleSheet sheet) {
            return Drawing.of(singletonList(this), singletonList(sheet), singletonList(p -> p));
        }
    }

    interface Rectangle extends Shape {
        double width();
        double height();
        default Extent _toExtent() {
            return Extent.of(Pos.of(width(), height()).resize(-0.5), Pos.of(width(), height()).resize(0.5));
        }
        default XML _toXML(List<Attr> styleAttrs, Function<Pos, Pos> trans) {
            List<Attr> attrs = new ArrayList<>(trans.apply(Pos.of(width(), height()).resize(-0.5)).toAttrs("x", "y"));
            attrs.addAll(Pos.of(width(), height()).toAttrs("width", "height"));
            attrs.addAll(styleAttrs);
            return XML.of(attrs, "rect", emptyList());
        }
        default String _show() {
            return "Rectangle " + width() + " " + height();
        }
    }

    interface Ellipse extends Shape {
        double rx();
        double ry();
        @Override
        default Extent _toExtent() {
            return Extent.of(Pos.of(-rx(), -ry()), Pos.of(rx(), ry()));
        }
        default XML _toXML(List<Attr> styleAttrs, Function<Pos, Pos> trans) {
            List<Attr> attrs = new ArrayList<>(trans.apply(Pos.of(0, 0)).toAttrs("cx", "cy"));
            attrs.addAll(Pos.of(rx(), ry()).toAttrs("rx", "ry"));
            attrs.addAll(styleAttrs);
            return XML.of(attrs, "ellipse", emptyList());
        }
        @Override
        default String _show() {
            return "Ellipse " + rx() + " " + ry();
        }
    }
    interface Triangle extends Shape {
        double length();
        default Extent _toExtent() {
            double y = Math.sqrt(3)/4 * length();
            return Extent.of(Pos.of(-length()/2, -y), Pos.of(length()/2, y));
        }
        default XML _toXML(List<Attr> styleAttrs, Function<Pos, Pos> trans) {
            double h = Math.sqrt(3)/4 * length();
            List<Attr> attrs = new ArrayList<>();
            attrs.add(Attr.of("points", Stream.of(Pos.of(-length()/2, -h), Pos.of(length()/2, -h), Pos.of(0, h))
                    .map(pos -> trans.apply(pos).show())
                    .reduce("", (s1, s2) -> s1 + " " + s2)));
            attrs.addAll(styleAttrs);
            return XML.of(attrs, "polygon", emptyList());
        }
        default String _show() {
            return "Triangle " + length();
        }
    }

    interface StyleSheet {
        List<Styling> stylings();
        default List<Attr> toAttrs() {
            boolean hasFill = false;
            List<Attr> attrs = new ArrayList<>();
            for (Styling s : stylings()) {
                Attr attr = s._toAttr();
                if (attr.name().equals("fill")) hasFill = true;
                attrs.add(attr);
            }
            if (!hasFill) attrs.add(Attr.of("fill", "none"));
            return attrs;
        }
    }

    interface Styling {
        Attr _toAttr();
    }
    interface FillColor extends Styling {
        Col color();
        default Attr _toAttr() {
            return Attr.of("fill", color()._show());
        }
    }
    interface StrokeColor extends Styling {
        Col color();
        default Attr _toAttr() {
            return Attr.of("stroke", color()._show());
        }
    }
    interface StrokeWidth extends Styling {
        double width();
        default Attr _toAttr() {
            return Attr.of("stroke-width", ""+width());
        }
    }

    interface Col {
        String _show();
    }
    interface Red extends Col {
        default String _show() { return "red"; }
    }
    interface Blue extends Col {
        default String _show() { return "blue"; }
    }
    interface Green extends Col {
        default String _show() { return "green"; }
    }
    interface Yellow extends Col {
        default String _show() { return "yellow"; }
    }
    interface Bisque extends Col {
        default String _show() { return "bisque"; }
    }
    interface Black extends Col {
        default String _show() { return "black"; }
    }

    interface Drawing {
        List<Function<Pos, Pos>> transforms();
        List<Shape> shapes(); // wildcards could be used for extensibility of shapes?
        // List<? extends Shape> shapes();
        List<StyleSheet> styles();

        default Drawing above(Drawing other) {
            Extent e1 = toExtent();
            Extent e2 = other.toExtent();
            Drawing t1 = transform(Pos.of(0, e2.p2().y())::add);
            Drawing t2 = other.transform(Pos.of(0, e1.p1().y())::add);
            return t1.merge(t2);
        }

        default Drawing beside(Drawing other) {
            Drawing t1 = transform(Pos.of(other.toExtent().p1().x(), 0)::add);
            Drawing t2 = other.transform(Pos.of(toExtent().p2().x(), 0)::add);
            return t1.merge(t2);
        }

        default Drawing inFrontOf(Drawing other) {
            return other.merge(this);
        }

        default Drawing flip() {
            Extent e = toExtent();
            return Drawing.of(shapes(), styles(), transforms());
        }

        default Extent toExtent() {
            return IntStream.range(0, shapes().size())
                    .mapToObj(i -> shapes().get(i)._toExtent().transform(transforms().get(i)))
                    .reduce(Extent::union).get();
        }
        default Drawing transform(UnaryOperator<Pos> trans) {
            return Drawing.of(shapes(), styles(), transforms().stream().map(t1 -> t1.andThen(trans)).collect(toList()));
        }
        default Drawing merge(Drawing other) {
            return Drawing.of(concat(shapes(), other.shapes()), concat(styles(), other.styles()), concat(transforms(), other.transforms()));
        }
        default XML toXML() {
            int scale = 10;
            Extent e = toExtent();
            Pos p1 = e.p1();
            Pos p2 = e.p2();
            Pos p = Pos.of(p2.x()-p1.x(), p2.y()-p1.y()).resize(scale);
            List<Attr> svgAttrs = new ArrayList<>(p.toAttrs("width", "height"));
            svgAttrs.add(Attr.of("viewBox", p1.resize(scale).show() + "," + p.show()));
            svgAttrs.add(Attr.of("xmlns", "http://www.w3.org/2000/svg"));
            svgAttrs.add(Attr.of("version", "1.1"));

            List<XML> shapeXMLs = IntStream.range(0, shapes().size())
                            .mapToObj(i -> shapes().get(i)._toXML(styles().get(i).toAttrs(), transforms().get(i)))
                            .collect(toList());
            return XML.of(svgAttrs, "svg",
                    singletonList(XML.of(singletonList(Attr.of("transform", "scale(" + Pos.of(1,-1).resize(scale).show() + ")")), "g", shapeXMLs)));
        }
        default String show() {
            return IntStream.range(0, shapes().size()).mapToObj(i -> "(" + transforms().get(i).toString() + shapes().get(i)._show() + ")").collect(joining(",", "[", "]"));
        }
    }

    static <E> List<E> concat(List<E> xs, List<E> ys) {
        List<E> tmp = new ArrayList<>(xs);
        tmp.addAll(ys);
        return tmp;
    }

    static Rectangle rectangle(double x, double y) {
        return Rectangle.of(x, y);
    }

    static Ellipse ellipse(double rx, double ry) {
        return Ellipse.of(rx, ry);
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

    static Drawing chick() {
        Drawing eyeball = ellipse(0.25, 0.75).draw(fillColor(black));
        Drawing eye = ellipse(2, 1).draw(fillColor(green));
        return eyeball.inFrontOf(eye);
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