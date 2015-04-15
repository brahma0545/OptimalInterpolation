#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <cstdlib>
#include <cmath>
#include <stdio.h>
#define R 10
int main(){
	std::ifstream fp1;
	std::ifstream fp2;
	
	std::ofstream fp3;
	std::ofstream fp4;

	fp1.open("lld_true.dat");
	fp2.open("lld_obs.dat");
	fp3.open("output.dat");
	
	std::string line;
	std::string line1;
	std::string field;
	std::string feild1;
	long long i=0;
	long long p=0;
	long q=0;
	long double a,b,c,x,y,z;
	double dist;
	double w;
	long long row,col;
	bool flag_1;
	bool flag_2;
	long count;
	row=-1;
	while(std::getline(fp2,line)){
		std::istringstream str(line);
		i=0;
		while(std::getline(str,field,',')){
			if(i==0)
				a=std::stold(field);
			else if(i==1)
				b=std::stold(field);
			else{
				c=std::stold(field);
				if(c==std::stold("1000000.00")){
					break;
				}
				row++;
				printf("%lld\n",row);
				col=0;
				fp1.open("lld_true.dat");
				flag_2=false;
				flag_1=false;
				while(std::getline(fp1,line1)){
					std::istringstream str1(line1);
					q=0;
					while(std::getline(str1,feild1,',')){
						if(q==0)
							x=std::stold(feild1);
						else if(q==1)
							y=std::stold(feild1);
						else{
							z=std::stold(feild1);
							dist=std::sqrt((a-x)*(a-x)+(b-y)*(b-y)+(c-z)*(c-z));
							if(dist<=R){
								//w=std::exp((-(dist*dist)/(2*R)));		//barnes
								//w=(std::pow(R,2)-std::pow(dist,2))/(std::pow(R,2)+std::pow(dist,2)); //cressman
								count=0;
								flag_1=true;
								fp3 << row <<" "<< col <<" "<<dist <<"\n";
							}else{
								count++;
								if(count>1500 && flag_1){
									flag_2=true;
									break;
								}
							}
							col++;
						}
						q++;
					}
					if(flag_2)
						break;
				}
				fp1.close();
				
			}
			i++;
		}
	}
	fp2.close();
	fp3.close();
}
