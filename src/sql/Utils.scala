package sql

object Utils {
  
import java.io.{FileReader,BufferedReader}

type Schema = Vector[String]
type Fields = Vector[String]

class Scanner(filename: String) {
  val br = new BufferedReader(new FileReader(filename))
  private[this] var pending: String = br.readLine()
  def next(delim: Char): String = {
    if (delim == '\n' ) {
      val field = pending
      pending = br.readLine()
      field
    } else {
      val i = pending.indexOf(delim)
      val field = pending.substring(0,i)
      pending = pending.substring(i+1)
      field
    }
  }
  def hasNext = pending ne null
  def close = br.close
}

def processDSV(file: String, c: Char)(yld: Record => Unit) {
  val in = new Scanner(file)
  val schema = in.next('\n').split(c).toVector
  while (in.hasNext) {
    val fields = schema.map(n=> in.next(if(n==schema.last)'\n' else c))
    yld(Record(fields, schema))
  }
}
def processCSV(file: String) = processDSV(file, ',')_

def printFields(fields: Fields) = 
  printf(fields.map{_ => "%s"}.mkString("", ",", "\n"), fields: _*)
def printSchema(schema: Schema) = println(schema.mkString(","))
def Schema(schema: String*): Schema = schema.toVector
case class Record(fields: Fields, schema: Schema) {
  def apply(key: String): String = fields(schema indexOf key)
  def apply(keys: Schema): Fields = keys map (apply _)
}
}