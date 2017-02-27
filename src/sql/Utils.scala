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


def processDSV(filename: String, schema: Schema, delim: Char, extSchema: Boolean)(yld: Record => Unit): Unit = {
    val s = new Scanner(filename)
    val last = schema.last
    def nextRecord = Record(schema.map{x => s.next(if (x==last) '\n' else delim)}, schema)
    if (!extSchema) {
      // the right thing would be to dynamically re-check the schema,
      // but it clutters the generated code
      // schema.foreach(f => if (s.next != f) println("ERROR: schema mismatch"))
       nextRecord // ignore csv header
    }
    while (s.hasNext) yld(nextRecord)
    s.close
}

def processCSV(file: String) = processDSV(file, loadSchema(file,','), ',', false)_

def loadSchema(filename: String, delim: Char): Schema = {
  val s = new Scanner(filename)
  val schema = Schema(s.next('\n').split(delim): _*)
  s.close
  schema
}

def printFields(fields: Fields) = 
  printf(fields.map{_ => "%s"}.mkString("", ",", "\n"), fields: _*)
def printSchema(schema: Schema) = println(schema.mkString(","))
def Schema(schema: String*): Schema = schema.toVector
case class Record(fields: Fields, schema: Schema) {
  def apply(key: String): String = fields(schema indexOf key)
  def apply(keys: Schema): Fields = keys map (apply _)
}
}