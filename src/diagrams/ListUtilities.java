package diagrams;

import java.util.ArrayList;
import java.util.List;

public interface ListUtilities {
    static <E> List<? extends E> concat(List<? extends E> xs, List<? extends E> ys) {
        List<E> tmp = new ArrayList<>(xs);
        tmp.addAll(ys);
        return tmp;
    }
}
