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

def processDSV(file: String, extSchema: Option[Schema], c: Char)(yld: Record => Unit) {
  val in = new Scanner(file)
  val schema = extSchema.getOrElse(Schema(in.next('\n').split(c): _*))
  val nextRecord = Record(schema.map(n=> in.next(if(n==schema.last)'\n' else c)), schema)
  if (extSchema.isEmpty) nextRecord // ignore
  while (in.hasNext) yld(nextRecord)
  in.close
}
def processCSV(file: String) = processDSV(file, None, ',')_

def printFields(fields: Fields) = 
  printf(fields.map{_ => "%s"}.mkString("", ",", "\n"), fields: _*)
def printSchema(schema: Schema) = println(schema.mkString(","))
def Schema(schema: String*): Schema = schema.toVector
case class Record(fields: Fields, schema: Schema) {
  def apply(key: String): String = fields(schema.indexOf(key))
  def apply(keys: Schema): Fields = keys.map(apply(_))
}
}