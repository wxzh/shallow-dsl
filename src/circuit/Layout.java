package circuit;

import static java.util.stream.Collectors.toList;

import java.util.List;
import java.util.function.IntUnaryOperator;
import java.util.stream.Collectors;

import lombok.Obj;

@Obj
public interface Layout {
    List<List<IntPair>> _layout();
    default Layout map(IntUnaryOperator f) {
            return Layout.of(_layout().stream()
                    .map(xs -> xs.stream()
                            .map(pr -> pr.map(f))
                            .collect(toList()))
                    .collect(toList()));
    }
    default String show() {
        return _layout().stream().map(xs -> xs.stream().map(p -> p.show()).collect(Collectors.joining(",", "[", "]"))).collect(Collectors.joining(",", "[", "]"));
    }
}