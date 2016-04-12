package circuit;

import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.util.Arrays;
import java.util.List;

import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;

import circuit.TlayoutFeature.Above;
import circuit.TlayoutFeature.Beside;
import circuit.TlayoutFeature.Circuit;
import circuit.TlayoutFeature.Fan;
import circuit.TlayoutFeature.Identity;
import circuit.TlayoutFeature.RStretch;
import circuit.TlayoutFeature.Stretch;

class DrawCircuit extends JPanel {
    Layout layout;
    static int L = 30;
    static int W = 30;
    static int R = 6;

    public DrawCircuit(Layout layout) {
        this.layout = layout;
    }

    public IntPair toCoord(int c, int r) {
        return IntPair.of((c+1)*W, (r+1)*L);
    }

    public void drawDot(Graphics2D g, IntPair p) {
        int x = p.x() - (R/2);
        int y = p.y() - (R/2);
        g.fillOval(x, y, R, R);

    }

    public void drawLine(Graphics2D g, IntPair from, IntPair to) {
        g.drawLine(from.x(), from.y(), to.x(), to.y());
    }

    @Override
    public void paintComponent(Graphics g) {
        super.paintComponent(g);
        Graphics2D g2d = (Graphics2D) g;
        List<List<IntPair>> ll = layout.layout();
        int col = ll.stream().flatMap(l -> l.stream()).map(pr -> pr.y()).reduce(Integer::max).orElse(0);

        // draw vertical lines
        for (int c = 0; c <= col; c++)
            drawLine(g2d, toCoord(c, 0), toCoord(c, ll.size()));
        for (int r = 0; r < ll.size(); r++) {
            for (IntPair pr : ll.get(r)) {
                IntPair from = toCoord(pr.x(), r);
                IntPair to = toCoord(pr.y(), r+1);
                drawDot(g2d, from);
                drawDot(g2d, to);
                drawLine(g2d, from, to);
            }
        }
    }

    @Override
    public Dimension getPreferredSize() {
        return new Dimension(300, 300);
    }
}
public class Test {
    public static void main(String[] args) {
        // Figure 3
        Circuit c31 = Beside.of(Fan.of(2), Identity.of(1));
        Circuit c32 = Beside.of(Identity.of(1), Fan.of(2));
        Circuit c33 = Above.of(c31, c32);
        // Figure 4
        Circuit c4 = Stretch.of(Fan.of(3), IntList.of(Arrays.asList(3,2,3)));
        Circuit c4r = RStretch.of(Fan.of(3), IntList.of(Arrays.asList(2,3,1)));
        // Figure 1
        Circuit c1 =
                Above.of(
                        Above.of(
                                Beside.of(Fan.of(2), Fan.of(2)),
                                Stretch.of(Fan.of(2), IntList.of(Arrays.asList(2,2)))),
                        Beside.of(
                                Beside.of(
                                        Identity.of(1),
                                        Fan.of(2)),
                                Identity.of(1)));
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                JFrame frame = new JFrame();
                frame.setTitle("Draw Circuit");
                frame.setResizable(false);
                frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
                frame.getContentPane().add(new DrawCircuit(c1._tlayout(i -> i)));
                frame.pack();
                frame.setVisible(true);
            }
        });
    }
}
