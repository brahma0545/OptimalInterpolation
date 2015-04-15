#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <cstdlib>
#include <cmath>
#include <stdio.h>
int main(){
	std::ifstream fp1;
	std::ifstream fp2;
	std::ifstream fp_temp;

	std::ofstream fp3;

	fp2.open("output.dat");
	fp3.open("sum.dat");

	std::string line;
	std::string line1;
	std::string line2;
	std::string field;
	std::string feild1;
	std::string feild2;
	long long i=0;
	long long q;
	long double a,b,c,x,y,z,sum,temp;

	long long row,col;
	row=-1;
	while(std::getline(fp2,line)){
		std::istringstream str(line);
		i=0;
		while(std::getline(str,field,' ')){
			if(i==0)
				a=std::stold(field);
			else if(i==1)
				b=std::stold(field);
			else{
				c=std::stold(field);
				//printf("%Lf\n",a);
				if(row<a){
					if(row!=-1)
						fp3 << row <<" "<< sum <<"\n";
					sum=c;
					row=a;
				}else if(row==a){
					sum+=c;
				}
			}
			i++;
		}
	}
	fp3 << row <<" "<< sum <<"\n";
	fp2.close();
	fp3.close();

	system("cp output.dat output_dup.dat");

	fp1.open("output.dat");
	fp2.open("sum.dat");
	fp3.open("final.dat");
	fp_temp.open("output_dup.dat");
	bool flag_2;
	bool flag_1;
	std::getline(fp_temp,line2);
	while(std::getline(fp2,line)){
		std::istringstream str(line);
		i=0;
		while(std::getline(str,field,' ')){
			if(i==0)
				a=std::stold(field);
			else{
				c=std::stold(field);
				flag_2=false;
				while(std::getline(fp1,line1)){
					std::istringstream str1(line1);
					q=0;
					while(std::getline(str1,feild1,' ')){
						if(q==0)
							x=std::stold(feild1);
						else if(q==1)
							y=std::stold(feild1);
						else{
							z=std::stold(feild1);
							if(a==x)
								fp3 << x <<" "<<y<<" "<< z/c <<"\n";
						}
						q++;
					}
					std::getline(fp_temp,line2);
					std::istringstream str2(line2);
					std::getline(str2,feild2,' ');
					if(feild2!="")
						temp=std::stold(feild2);
					//printf("%Lf\t%Lf\n", temp,a);
					if(temp!=a)
						break;
				}
			}
			i++;
		}
	}
	fp1.close();
	fp2.close();
	fp3.close();
	fp_temp.close();
	system("rm output_dup.dat");
	system("rm sum.dat");
}
