package circuit;

import java.util.List;

import lombok.Obj;

// wrapper for List<Integer>
// the inner type (Integer) will be lost in the sub-family
@Obj
public interface IntList {
    List<Integer> _out();
}
