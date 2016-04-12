package diagrams;

import static java.util.stream.Collectors.joining;

import java.util.List;

import lombok.Obj;

@Obj
interface XML {
    String tag();
    List<Attr> attrs();
    List<XML> xmls();

    default String show() {
        String attrs = " " + attrs().stream().map(Attr::show).collect(joining(" "));
        if (xmls().size() == 0)
            return "<" + tag() + attrs + "/>";
        else
            return "<" + tag() + attrs + ">\n" + xmls().stream().map(XML::show).collect(joining("\n")) + "\n</" + tag() + ">";
    }
}