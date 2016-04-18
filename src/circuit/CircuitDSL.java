package circuit;
import static java.util.Collections.emptyList;
import static java.util.Collections.singletonList;
import static java.util.stream.Collectors.toList;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.function.BinaryOperator;
import java.util.function.IntUnaryOperator;
import java.util.stream.IntStream;
import java.util.stream.Stream;

import javax.swing.JFrame;
import javax.swing.SwingUtilities;

import lombok.Obj;

@Obj
interface AST {
    interface Circuit {
    }
    interface Identity extends Circuit {
        int n();
    }
    interface Fan extends Circuit {
        int n();
    }
    interface Above extends Circuit {
        Circuit c1();
        Circuit c2();
    }
    interface Beside extends Circuit {
        Circuit c1();
        Circuit c2();
    }
    interface Stretch extends Circuit {
        IntList ns();
        Circuit c();
    }
}

@Obj
interface DepthFeature extends AST {
    interface Circuit {
        int _depth();
    }
    interface Identity{
        default int _depth() {
            return 0;
        }
    }
    interface Fan {
        default int _depth() {
            return 1;
        }
    }
    interface Above {
        default int _depth() {
            return c1()._depth() + c2()._depth();
        }
    }
    interface Beside {
        default int _depth() {
            return Math.max(c1()._depth(), c2()._depth());
        }
    }
    interface Stretch {
        default int _depth() {
            return c()._depth();
        }
    }
}

@Obj
interface WidthFeature extends AST {
    interface Circuit {
        int _width();
    }
    interface Identity {
        default int _width() {
            return n();
        }
    }
    interface Fan {
        default int _width() {
            return n();
        }
    }
    interface Above {
        default int _width() {
            return c1()._width();
        }
    }
    interface Beside {
        default int _width() {
            return c1()._width() + c2()._width();
        }
    }
    interface Stretch {
        default int _width() {
            return ns().out().stream().reduce(0, (a, b) -> a + b); // bug: the inner type(Integer) is lost
        }
    }
}


@Obj
interface WellSizeFeature extends WidthFeature, DepthFeature {
    interface Circuit {
        boolean _wellSize();
    }
    interface Identity {
        default boolean _wellSize() {
            return true;
        }
    }
    interface Fan {
        default boolean _wellSize() {
            return true;
        }
    }
    interface Above {
        default boolean _wellSize() {
            return c1()._wellSize() && c2()._wellSize() && c1()._width() == c2()._width();
        }
    }
    interface Beside {
        default boolean _wellSize() {
            return c1()._wellSize() && c2()._wellSize();
        }
    }
    interface Stretch {
        default boolean _wellSize() {
            return c()._wellSize() && ns().out().size() == c()._width();
        }
    }
}

@Obj
interface ExtendedAST extends WellSizeFeature {
    interface RStretch extends Stretch {}
}

@Obj
interface LayoutFeature extends ExtendedAST {
    interface Circuit {
        Layout _layout();
    }
    interface Identity {
        default Layout _layout() {
            return Layout.of(emptyList());
        }
    }
    interface Fan {
        default Layout _layout() {
            return Layout.of(singletonList(IntStream.range(1, n()).mapToObj(j -> IntPair.of(0, j)).collect(toList())));
        }
    }
    interface Above {
        default Layout _layout() {
            return Layout.of(concat(c1()._layout().layout(), c2()._layout().layout()));
        }
    }
    interface Beside {
        default Layout _layout() {
            return Layout.of(lzw(c1()._layout().layout(), c2()._layout().map(i -> i + c1()._width()).layout(), LayoutFeature::concat));
        }
    }
    interface Stretch {
        default Layout _layout() {
            int acc = 0;
            List<Integer> ns = new ArrayList<>();
            for (int n : ns().out()) {
                ns.add(n + acc - 1);
                acc += n;
            }
            return c()._layout().map(i -> ns.get(i));
        }
    }
    interface RStretch {
        default Layout _layout() {
            int acc = ns().out().size();
            List<Integer> ns = new ArrayList<>();
            for (int n : ns().out()) {
                ns.add(acc - 1);
                acc += n;
            }
            return c()._layout().map(i -> ns.get(i));
        }
    }
    static <E> List<E> concat(List<E> xs, List<E> ys) {
        return Stream.concat(xs.stream(), ys.stream()).collect(toList());
    }

    // long zip with
    static <A> List<A> lzw(List<A> l1, List<A> l2, BinaryOperator<A> f) {
        int n = Math.min(l1.size(), l2.size());
        List<A> tail = l1.size() == n ? l2.subList(n, l2.size()) : l1.subList(n, l1.size());
        return concat(IntStream.range(0, n).mapToObj(i -> f.apply(l1.get(i), l2.get(i))).collect(toList()), tail);
    }
}

@Obj
interface TlayoutFeature extends LayoutFeature {
    interface Circuit {
        Layout _tlayout(IntUnaryOperator f);
    }
    interface Identity {
        default Layout _tlayout(IntUnaryOperator f) {
            return Layout.of(emptyList());
        }
    }
    interface Fan {
        default Layout _tlayout(IntUnaryOperator f) {
            return Layout.of(singletonList(IntStream.range(1, n()).mapToObj(j -> IntPair.of(0, j).map(f)).collect(toList())));
        }
    }
    interface Above {
        default Layout _tlayout(IntUnaryOperator f) {
            return Layout.of(LayoutFeature.concat(c1()._tlayout(f).layout(), c2()._tlayout(f).layout()));
        }
    }
    interface Beside {
        default Layout _tlayout(IntUnaryOperator f) {
            return Layout.of(
                    LayoutFeature.lzw(c1()._tlayout(f).layout(),
                            c2()._tlayout(f).map(f.andThen(i -> i + c1()._width())::applyAsInt).layout(),
                            LayoutFeature::concat));
        }
    }
    interface Stretch {
        default Layout _tlayout(IntUnaryOperator f) {
            int acc = 0;
            List<Integer> ns = new ArrayList<>();
            for (int n : ns().out()) {
                ns.add(n + acc - 1);
                acc += n;
            }
            return c()._tlayout(f).map(f.andThen(ns::get));
        }
    }
    interface RStretch {
        default Layout _tlayout(IntUnaryOperator f) {
            int acc = ns().out().size();
            List<Integer> ns = new ArrayList<>();
            for (int n : ns().out()) {
                ns.add(acc - 1);
                acc += n;
            }
            return c()._tlayout(f).map(ns::get);
        }
    }
}

@Obj
public interface CircuitDSL extends TlayoutFeature {
    interface Circuit {
        default Circuit beside(Circuit that) {
            return Beside.of(this, that);
        }
        default Circuit above(Circuit that) {
            return Above.of(this, that);
        }
        default Circuit stretch(Integer... ns) {
            return Stretch.of(this, IntList.of(Arrays.asList(ns)));
        }
        default Circuit rStretch(Integer... ns) {
            return RStretch.of(this, IntList.of(Arrays.asList(ns)));
        }
        default void draw() {
            SwingUtilities.invokeLater(new Runnable() {
                @Override
                public void run() {
                    JFrame frame = new JFrame();
                    frame.setTitle("Draw Circuit");
                    frame.setResizable(false);
                    frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
                    frame.getContentPane().add(new DrawCircuit(Circuit.this._tlayout(i -> i)));
                    frame.pack();
                    frame.setVisible(true);
                }
            });
        }
    }
    static Circuit identity(int n) {
        return Identity.of(n);
    }
    static Circuit fan(int n) {
        return Fan.of(n);
    }
}