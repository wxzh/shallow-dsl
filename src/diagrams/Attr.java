package diagrams;

import lombok.Obj;

@Obj
interface Attr {
    String name();
    String value();
    default String show() {
        return name() + "=\"" + value() + "\"";
    }
}