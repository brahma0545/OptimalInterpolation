import org.apache.spark.SparkContext
import org.apache.spark.SparkConf
import org.apache.spark.SparkContext._

import breeze.linalg.DenseVector
import org.apache.spark.mllib.linalg.{Vector, Vectors, Matrices}
import org.apache.spark.mllib.linalg.distributed.RowMatrix
import org.apache.spark.mllib.linalg.SingularValueDecomposition
import org.apache.spark.rdd.RDD
import org.apache.spark.mllib.linalg.DenseMatrix
import scala.collection.mutable.ListBuffer

 
object InterPolation{
 
     def Transpose(m: Array[Array[Double]]): Array[Array[Double]] = {(for {c <- m(0).indices} yield m.map(_(c)) ).toArray}


     def Multiply(a:RowMatrix,b:RDD[Vector]):RDD[Vector]={
          val ma = b.map(_.toArray).take(b.count.toInt)
          val localMat = Matrices.dense( b.count.toInt,b.take(1)(0).size,Transpose(ma).flatten)
          a.multiply(localMat).rows
     }
     def add_them(a:Vector, b:Vector):Vector={
          val bv1=new DenseVector(a.toArray)
          val bv2=new DenseVector(b.toArray)
          Vectors.dense((bv1+bv2).toArray)
     }
     def sub_them(a:Vector, b:Vector):Vector={
          val bv1=new DenseVector(a.toArray)
          val bv2=new DenseVector(b.toArray)
          Vectors.dense((bv1-bv2).toArray)
     }
     def convert_to_inv(a:Vector):Vector={
          val temp=new DenseVector(a.toArray)
          Vectors.dense((temp.map(e => 1/e)).toArray)
     }
     def zipFun(l:Iterator[Vector],r:Iterator[Vector]):Iterator[(Vector,Vector)]={
          val res=new ListBuffer[(Vector,Vector)]
          while(l.hasNext && r.hasNext){
               res+=((l.next(),r.next()))
          }
          res.iterator
     }
     def main(args: Array[String]){
          val spConfig = (new SparkConf).setAppName("SparkLA")
          val sc = new SparkContext(spConfig)
     //------------------------------------------->reading h.txt file and finding H matrix<-----------------------------------//
          //val rows = sc.textFile("/home/brahma/data/h.txt").map { line => val values = line.split(',').map(_.toDouble) 
          val rows = sc.textFile("hdfs://10.5.23.249:9000/user/hadoop-user/big/a.txt").map { line => val values = line.split(',').map(_.toDouble) 
               Vectors.sparse(values.length,values.zipWithIndex.map(e => (e._2, e._1)).filter(_._2 != 0.0))
          }
          val rmat = new RowMatrix(rows)


     //------------------------------------------->reading xt file and finding yt matrix<-----------------------------------//
          //val xt = sc.textFile("/home/brahma/data/xt.txt").map { line => val values = line.split(' ').map(_.toDouble)
          val xt = sc.textFile("hdfs://10.5.23.249:9000/user/hadoop-user/dir/xt.txt").map { line => val values = line.split(' ').map(_.toDouble)
               Vectors.dense(values)
          }
          val yt=Multiply(rmat,xt)
     //------------------------------------------->reading xb file and finding yb matrix<-----------------------------------//
          //val xb = sc.textFile("/home/brahma/data/xb.txt").map { line => val values = line.split(' ').map(_.toDouble)
          val xb = sc.textFile("hdfs://10.5.23.249:9000/user/hadoop-user/dir/xb.txt").map { line => val values = line.split(' ').map(_.toDouble)
               Vectors.dense(values)
          }
          val yb=Multiply(rmat,xb)
          val eb=xb.coalesce(1).zip(xt.coalesce(1)).map{ e => sub_them(e._1,e._2)}
          //eb.coalesce(1).saveAsTextFile("eb")
          val A=Multiply(rmat, eb)

     //--------------------->reading xo file and finding  error matrcies eb,eo matrix<-----------------------------------//
          //val rows_xo = sc.textFile("/prjct/xo.txt").map { line => val values = line.split(' ').map(_.toDouble) 
          val rows_xo = sc.textFile("hdfs://10.5.23.249:9000/user/hadoop-user/dir/xo.txt").map { line => val values = line.split(' ').map(_.toDouble) 
               Vectors.sparse(values.length,values.zipWithIndex.map(e => (e._2, e._1)).filter(_._2 != 0.0))
          }
          val rmat_xo = new RowMatrix(rows_xo)
          //val xo = sc.textFile("/prjct/xo_temp.txt").map { line => val values = line.split(' ').map(_.toDouble)
          val xo = sc.textFile("hdfs://10.5.23.249:9000/user/hadoop-user/dir/xo_temp.txt").map { line => val values = line.split(' ').map(_.toDouble)
               Vectors.dense(values)
          }
          val yo=Multiply(rmat_xo,xo)  

         
          //val eo=yo.zipPartitions(yt,true)(zipFun).map{ e => sub_them(e._1,e._2)}
          val eo=yo.coalesce(1).zip(yt.coalesce(1)).map{ e => sub_them(e._1,e._2)}
          //eo.coalesce(1).saveAsTextFile("eo")
          val N=eo.count.toInt
     //------------------------------------------->Computation of B and R matrices<-----------------------------------//

          val rmat_eo=new RowMatrix(eo)
          val ma = eo.map(_.toArray).take(N)
          val tran=sc.parallelize(Transpose(ma).map(e=>Vectors.dense(e)))
          val R=Multiply(rmat_eo,tran)

          val rmat_ADD=new RowMatrix(A)
          val ma_ADD=A.map(_.toArray).take(A.count.toInt)
          val tran_ADD=sc.parallelize(Transpose(ma_ADD).map(e=>Vectors.dense(e)))
          val R_ADD=Multiply(rmat_ADD,tran_ADD)


          val ForSvd=R.coalesce(1).zip(R_ADD.coalesce(1)).map{e => add_them(e._1, e._2)}
          //val ForSvd=R.zipPartitions(R_ADD.coalesce(1),true)(zipFun).map{ e => add_them(e._1,e._2)}
     //--------------------------------->Computation of SVD of inversion matrix<-----------------------------------//
          val ForSvdRmat=new RowMatrix(ForSvd)
          val svd=ForSvdRmat.computeSVD(20,computeU=true)
          val s=svd.s

          val U=svd.U              //RowMatrix we can convert into RDD[]
          val V=svd.V              //Matrix local matrix
          val S=convert_to_inv(s)  //Vector

     //---------------------------->Computation of W=eb*tran(A)*tran(V)*S*tran(U)<--------------------------------//

          //---------->for O=eb*tran(A)<----------//    
               val Eb=new RowMatrix(eb)
               val Ebma= A.map(_.toArray).take(A.count.toInt)
               val Ebtran=sc.parallelize(Transpose(Ebma).map(e=>Vectors.dense(e)))
               val O=Multiply(Eb,Ebtran)
          //---------->for P=O*V<----------//
               val Ormat=new RowMatrix(O)
               val P=Ormat.multiply(V)
          //---------->for Q=P*(1/S)<----------//
               val Q=P.multiply(Matrices.diag(S))
               val Utran=U.rows.map(_.toArray).take(U.rows.count.toInt)
               val UMult=sc.parallelize(Transpose(Utran).map(e => Vectors.dense(e)))
               val W=Multiply(Q, UMult)
                  
     //---------------------------->Computation of Xa=Xb+W*(Yo-Yb)<---------------------------------------//
          val Wmul = yo.coalesce(1).zip(yb.coalesce(1)).map(e => sub_them(e._1, e._2))
          val WmulInt=Wmul.map(e => Vectors.dense(e.toArray.map(e=>e.toInt.toDouble)))
          //val Wmul=yo.zipPartitions(yb,true)(zipFun).map{ e => sub_them(e._1,e._2)}
          val Wramt=new RowMatrix(W)
          val Xbadd=Multiply(Wramt, WmulInt)
          
          val rmat_xb = new RowMatrix(xb)
          val Xb=Multiply(rmat_xb,xo)  
          val Xa=Xb.coalesce(1).zip(Xbadd.coalesce(1)).map(e => add_them(e._1, e._2))
          //val Xa=Xb.zipPartitions(Xbadd,true)(zipFun).map{ e => add_them(e._1,e._2)}
          Xa.saveAsTextFile("ouput")
     //---------------------------->Computing the error<---------------------------------------//
          //val Xtrmt=new RowMatrix(xt)
          //val Xt=Multiply(Xtrmt, xo)
          //val ea=Xa.coalesce(1).zip(Xt.coalesce(1)).map{ e => sub_them(e._1,e._2)}
          //val ea=Xa.zipPartitions(Xt,true)(zipFun).map{ e => sub_them(e._1,e._2)}
          //ea.coalesce(1).saveAsTextFile("ea")
     }

}
