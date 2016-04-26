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
        int _n();
    }
    interface Fan extends Circuit {
        int _n();
    }
    interface Above extends Circuit {
        Circuit _c1();
        Circuit _c2();
    }
    interface Beside extends Circuit {
        Circuit _c1();
        Circuit _c2();
    }
    interface Stretch extends Circuit {
        List<Integer> _ns();
        Circuit _c();
    }
}

@Obj
interface DepthFeature extends AST {
    interface Circuit {
        int depth();
    }
    interface Identity{
        default int depth() {
            return 0;
        }
    }
    interface Fan {
        default int depth() {
            return 1;
        }
    }
    interface Above {
        default int depth() {
            return _c1().depth() + _c2().depth();
        }
    }
    interface Beside {
        default int depth() {
            return Math.max(_c1().depth(), _c2().depth());
        }
    }
    interface Stretch {
        default int depth() {
            return _c().depth();
        }
    }
}

@Obj
interface WidthFeature extends AST {
    interface Circuit {
        int width();
    }
    interface Identity {
        default int width() {
            return _n();
        }
    }
    interface Fan {
        default int width() {
            return _n();
        }
    }
    interface Above {
        default int width() {
            return _c1().width();
        }
    }
    interface Beside {
        default int width() {
            return _c1().width() + _c2().width();
        }
    }
    interface Stretch {
        default int width() {
            return _ns().stream().reduce(0, (a, b) -> a + b);
        }
    }
}


@Obj
interface WellSizeFeature extends WidthFeature, DepthFeature {
    interface Circuit {
        boolean wellSize();
    }
    interface Identity {
        default boolean wellSize() {
            return true;
        }
    }
    interface Fan {
        default boolean wellSize() {
            return true;
        }
    }
    interface Above {
        default boolean wellSize() {
            return _c1().wellSize() && _c2().wellSize() && _c1().width() == _c2().width();
        }
    }
    interface Beside {
        default boolean wellSize() {
            return _c1().wellSize() && _c2().wellSize();
        }
    }
    interface Stretch {
        default boolean wellSize() {
            return _c().wellSize() && _ns().size() == _c().width();
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
        Layout layout();
    }
    interface Identity {
        default Layout layout() {
            return Layout.of(emptyList());
        }
    }
    interface Fan {
        default Layout layout() {
            return Layout.of(singletonList(IntStream.range(1, _n()).mapToObj(i -> IntPair.of(0, i)).collect(toList())));
        }
    }
    interface Above {
        default Layout layout() {
            return Layout.of(concat(_c1().layout()._layout(), _c2().layout()._layout()));
        }
    }
    interface Beside {
        default Layout layout() {
            return Layout.of(lzw(_c1().layout()._layout(), _c2().layout().map(i -> i + _c1().width())._layout(), LayoutFeature::concat));
        }
    }
    interface Stretch {
        default Layout layout() {
            int acc = 0;
            List<Integer> _ns = new ArrayList<>();
            for (int n : _ns()) {
                _ns.add(n + acc - 1);
                acc += n;
            }
            return _c().layout().map(i -> _ns.get(i));
        }
    }
    interface RStretch {
        default Layout _layout() {
            int acc = _ns().size();
            List<Integer> _ns = new ArrayList<>();
            for (int n : _ns()) {
                _ns.add(acc - 1);
                acc += n;
            }
            return _c().layout().map(i -> _ns.get(i));
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
        Layout tlayout(IntUnaryOperator f);
    }
    interface Identity {
        default Layout tlayout(IntUnaryOperator f) {
            return Layout.of(emptyList());
        }
    }
    interface Fan {
        default Layout tlayout(IntUnaryOperator f) {
            return Layout.of(singletonList(IntStream.range(1, _n()).mapToObj(j -> IntPair.of(0, j).map(f)).collect(toList())));
        }
    }
    interface Above {
        default Layout tlayout(IntUnaryOperator f) {
            return Layout.of(LayoutFeature.concat(_c1().tlayout(f)._layout(), _c2().tlayout(f)._layout()));
        }
    }
    interface Beside {
        default Layout tlayout(IntUnaryOperator f) {
            return Layout.of(
                    LayoutFeature.lzw(_c1().tlayout(f)._layout(),
                            _c2().tlayout(f).map(f.andThen(i -> i + _c1().width())::applyAsInt)._layout(),
                            LayoutFeature::concat));
        }
    }
    interface Stretch {
        default Layout tlayout(IntUnaryOperator f) {
            int acc = 0;
            List<Integer> _ns = new ArrayList<>();
            for (int n : _ns()) {
                _ns.add(n + acc - 1);
                acc += n;
            }
            return _c().tlayout(f).map(f.andThen(_ns::get));
        }
    }
    interface RStretch {
        default Layout tlayout(IntUnaryOperator f) {
            int acc = _ns().size();
            List<Integer> _ns = new ArrayList<>();
            for (int n : _ns()) {
                _ns.add(acc - 1);
                acc += n;
            }
            return _c().tlayout(f).map(_ns::get);
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
        default Circuit stretch(Integer... _ns) {
            return Stretch.of(this, Arrays.asList(_ns));
        }
        default Circuit rStretch(Integer... _ns) {
            return RStretch.of(this, Arrays.asList(_ns));
        }
        default void draw() {
            SwingUtilities.invokeLater(
                () -> {
                    JFrame frame = new JFrame();
                    frame.setTitle("Draw Circuit");
                    frame.setResizable(false);
                    frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
                    frame.getContentPane().add(new DrawCircuit(Circuit.this.tlayout(i -> i)));
                    frame.pack();
                    frame.setVisible(true);
                }
            );
        }
    }
    static Circuit identity(int n) {
        return Identity.of(n);
    }
    static Circuit fan(int n) {
        return Fan.of(n);
    }
}