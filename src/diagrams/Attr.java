package diagrams;

import lombok.Obj;

@Obj
interface Attr {
    String _name();
    String _value();
    default String show() {
        return _name() + "=\"" + _value() + "\"";
    }
}