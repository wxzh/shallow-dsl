package multiple

//BEGIN_MULTIPLE_INHERITANCE
trait Circuit extends width.Circuit with wellsized.Circuit
trait Beside 
    extends Circuit with width.Beside with wellsized.Beside {
  val c1, c2: Circuit
}
//...
//END_MULTIPLE_INHERITANCE
trait Id extends Circuit with width.Id with wellsized.Id
trait Fan extends Circuit with width.Fan with wellsized.Fan