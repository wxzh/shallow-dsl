package object width {
def id(x: Int): Circuit = new Id { val n = x }
def fan(x: Int): Circuit = new Fan { val n = x }
def beside(x: Circuit, y: Circuit): Circuit = 
    new Beside { val c1 = x; val c2 = y}
}