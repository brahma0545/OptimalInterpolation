import org.apache.spark.SparkContext
import org.apache.spark.SparkConf
import org.apache.spark.SparkContext._
 
import org.apache.spark.mllib.linalg.{Vector, Vectors, Matrices}
import org.apache.spark.mllib.linalg.distributed.{RowMatrix, MatrixEntry, CoordinateMatrix}
 
object CoordinateMatrixTest extends App {
 
  val spConfig = (new SparkConf).setMaster("local").setAppName("Spark COO Sparse Matrix")
  val sc = new SparkContext(spConfig)
 
  // Load and parse Coordinate(COO) Sparse Matrix
  val coo_matrix_input = sc.textFile("hdfs://cse-hadoop-109:8020/user/breddy/31_3_15/h.txt", 3).map(line =>  line.split(' ')).flatMap(_.zipWithIndex).groupBy(_._2).sortByKey().map(_._2.map(_._1).toSeq).map{e => (e(0).toLong, e(1).toLong, e(2).toDouble)}
 
  // Build CoordinateMatrix
  val coo_matrix_matrixEntry = coo_matrix_input.map(e => MatrixEntry(e._1, e._2, e._3))
  val coo_matrix = new CoordinateMatrix(coo_matrix_matrixEntry)
 
  // Convert to a distributed RowMatrix
  val rmat = coo_matrix.toRowMatrix
 
  // Build a local DenseMatrix
  val dm = sc.textFile("hdfs://cse-hadoop-109:8020/user/breddy/31_3_15/xt.txt").map { line =>
    val values = line.split(' ').map(_.toDouble)
    Vectors.dense(values)
  }
  val ma = dm.map(_.toArray).take(dm.count.toInt)
  val localMat = Matrices.dense( dm.count.toInt, dm.take(1)(0).size, ma.transpose.flatten )  
 
  // Multiply two matrices
  rmat.multiply(localMat).rows.zipWithIndex.map(
      e => e._2 -> e._1).sortByKey(true).foreach(e => println(e._2))
 
}
