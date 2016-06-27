package object desugar {
//BEGIN_COMPANION
def Fan(x: Int): Circuit = new Fan { val n = x }
def Beside(x: Circuit, y: Circuit): Circuit = 
    new Beside { val c1 = x; val c2 = y}
//END_COMPANION
}