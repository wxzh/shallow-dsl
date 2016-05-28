package diagrams;

import java.util.ArrayList;
import java.util.List;

import diagrams.Family.Styling;
import lombok.Obj;

@Obj
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
