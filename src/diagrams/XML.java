package diagrams;

import static java.util.stream.Collectors.joining;

import java.util.List;

import lombok.Obj;

@Obj
interface XML {
    String _tag();
    List<Attr> _attrs();
    List<XML> _xmls();

    default String show() {
        String attrs = " " + _attrs().stream().map(Attr::show).collect(joining(" "));
        if (_xmls().size() == 0)
            return "<" + _tag() + attrs + "/>";
        else
            return "<" + _tag() + attrs + ">\n" + _xmls().stream().map(XML::show).collect(joining("\n")) + "\n</" + _tag() + ">";
    }
}