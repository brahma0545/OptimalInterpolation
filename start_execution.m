%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
clc;
disp('fill NaN true with barnes');
load true.mat
lat=squeeze(la(:,:,1));
lon=squeeze(lo(:,:,1));
[~,~,n3]=size(te);
data_filled_true=[];
for i=1:n3
    gg=[];
    gg=squeeze(te(:,:,i));
    f=[];
    f=find(isnan(gg));
    lat1=squeeze(la(:,:,1));
    lon1=squeeze(lo(:,:,1));
    gg(f)=[];
    lat1(f)=[];
    lon1(f)=[];
    data_filled_true(:,:,i)=barnes(lon1,lat1,gg,lon,lat,1,1);
end
te=data_filled_true;
save('truevalues.mat','te','lo','la','de');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
clc;
disp('fill the back_s NaN values with barnes');
load back.mat
lat=squeeze(la(:,:,1));
lon=squeeze(lo(:,:,1));
[~,~,n3]=size(te);
data_filled_back=[];
for i=1:n3
    gg=[];
    gg=squeeze(te(:,:,i));
    f=[];
    f=find(isnan(gg));
    lat1=squeeze(la(:,:,1));
    lon1=squeeze(lo(:,:,1));
    gg(f)=[];
    lat1(f)=[];
    lon1(f)=[];
    data_filled_back(:,:,i)=barnes(lon1,lat1,gg,lon,lat,1,1);
end
te= data_filled_back;
save('background.mat','te','lo','la','de');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
clc;
disp('converting truevalues to vectors');
load('truevalues.mat');

[size_tm,size_tn,size_tz]=size(te);

%PointToMat=matfile('vectors.mat','Writable',true);

row=size_tn*size_tm*size_tz;
final_tru(row,1)=0;
w=1;

for i=1:size_tm
    for j=1:size_tn
        for k=1:size_tz
            final_tru(w,1)=te(i,j,k);
            w=w+1;
        end
    end
end
save('vectors.mat','final_tru');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
clc;
disp('converting back to vectors');
%PointToMat=matfile('vectors.mat','Writable',true);
load('background.mat');
[size_bm,size_bn,size_bz]=size(te);

row=size_bm*size_bn*size_bz;
final_back(row,1)=0;
w=1;
for i=1:size_bm
    for j=1:size_bn
        for k=1:size_bz
            final_back(w,1)=te(i,j,k);
            w=w+1;
        end
    end
end
save('vectors.mat','final_back','-append');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

load('true.mat')
t1=lo(1,:,1)';
t2=la(:,1,1);
t3=de(1,1,:);
t3=squeeze(t3);
[x,y,z]=meshgrid(t2,t3,t1);
result=[z(:),x(:),y(:)];
csvwrite('lld_true.dat',result);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%Ea=[];
%rms_mat=[];
for z=2:10
    fl=['obse_jan_',num2str(z)];
    str=strcat('jan',num2str(z),'.nc');
    depth=ncread(str,'var1');
    temp=ncread(str,'var2');
    lon=ncread(str,'longitude');
    lat=ncread(str,'latitude');
    save(fl,'depth','temp','lon','lat');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    %load(fl);
    depth(isnan(depth))=999999;
    temp=depth';
    ll_obs=cat(2,lon,lat);
    lld_obs=cat(2,ll_obs,temp);
    csvwrite('lld_obs.dat',lld_obs);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    clc
    disp('calculating interploation matrix');
    system('c++ jeffa.cc -std=c++11');
    system('./a.out');
    system('c++ update.cc -std=c++11');
    system('./a.out');
    system('c++ number_of_obs.cc -std=c++11');
    system('./a.out >obs.dat');
    %%
    clc
    load final.dat
    final=final';
    save('interploate.mat','final');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    load true.mat;
    [p,q,r]=size(te);
    p=p*q*r;
    disp('exectuting python file');
    load obs.dat;
    q=obs;
    str1=strcat({' '},num2str(q) ,{' '},num2str(p));
    str=strcat('python sparse.py',char(str1));
    system(str);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    clc;
    disp('converting obse to vectors ');
    %PointToMat=matfile('vectors.mat','Writable',true);
    load(fl);
    load obs.dat;
    temp=temp';
    [size_om,size_on]=size(temp);
    row=obs;
    final_obs(row,1)=0;
    w=1;
    for i=1:size_om
    	for j=1:size_on
            if ~isnan(temp(i,j))
                final_obs(w,1)=temp(i,j);
                w=w+1;
            else
                break
            end
    	end
    end
    save('vectors.mat','final_obs','-append');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    clc;
    disp('calculations');
    load('vectors.mat');
    load('final.mat');

    final_yt=final*final_tru;
    final_yb=final*final_back;
    disp('error calculations');
    eb=final_back-final_tru;
    eo=final_obs-final_yt;
    etemp=round(final_obs-final_yb);

    disp('R matrix calculation');
    temp=final*eb;
    jeffa=temp*temp';
    R=eo*eo';


    jeffa=R+jeffa;
    jeffa1=eb*temp';
    disp('inverse calculation');
    jeffa2=pinv(jeffa);
    W=jeffa1*jeffa2;
    disp('final analysis');
    xa=final_back+W*etemp;
    ea=xa-final_tru;
    fl_1=['temp_jan_',num2str(z)];
    save(fl_1,'xa','W');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    clc;
    disp('final conversions');
    load('truevalues.mat');
    load(fl_1);

    [a,b,c]=size(te);
    w=1;
    for i=1:a
        for j=1:b
            for k=1:c
                analysed_temp(i,j,k)=xa(w);
                w=w+1;
            end
        end
    end
    fl_2=['for_ploting_jan_',num2str(z)];
    save(fl_2,'te','la','lo','de','analysed_temp','ea');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    clc;
    disp('ploting section');
    load(fl_2);
    load('true.mat','te');
    back=load('back.mat', 'te');
    teb=back.te;
    [n1,n2,n3]=size(analysed_temp);
    for l=1:n3
        figure(l)
        lon_back=squeeze(lo(:,:,1));
        lat_back=squeeze(la(:,:,1));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%
        subplot(2,2,1)
        final_ea=squeeze(te(:,:,l));
        m_proj('mercator','long',[76 100],'lat',[4 24])
        m_pcolor(lon_back,lat_back,final_ea)
        shading interp;
        caxis([min(min(squeeze(te(:,:,l)))) max(max(squeeze(te(:,:,l))))])
        m_grid('box','fancy','fontsize',6,'fontweight','bold','linestyle','none')
        m_coast('patch',[0.4 0.4 0.4]);
        title('true values');
        colorbar;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%  
        subplot(2,2,2)
        final_ea=squeeze(teb(:,:,l));
        m_proj('mercator','long',[76 100],'lat',[4 24])
        m_pcolor(lon_back,lat_back,final_ea)
        shading interp;
        caxis([min(min(squeeze(te(:,:,l)))) max(max(squeeze(te(:,:,l))))])
        m_grid('box','fancy','fontsize',6,'fontweight','bold','linestyle','none')
        m_coast('patch',[0.4 0.4 0.4]);
        title('background values');
        colorbar;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        %%  
        subplot(2,2,3)
        final_ea=squeeze(analysed_temp(:,:,l));
        m_proj('mercator','long',[76 100],'lat',[4 24])
        m_pcolor(lon_back,lat_back,final_ea)
        shading interp;
        caxis([min(min(squeeze(te(:,:,l)))) max(max(squeeze(te(:,:,l))))])
        m_grid('box','fancy','fontsize',6,'fontweight','bold','linestyle','none')
        m_coast('patch',[0.4 0.4 0.4]);
        title('analysis values');
        colorbar;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        %%
        subplot(2,2,4)
        final_ea=squeeze(analysed_temp(:,:,l))-squeeze(te(:,:,l));
        m_proj('mercator','long',[76 100],'lat',[4 24])
        m_pcolor(lon_back,lat_back,final_ea)
        shading interp;
        caxis([-0.5 0.5]);
        m_grid('box','fancy','fontsize',6,'fontweight','bold','linestyle','none')
        m_coast('patch',[0.4 0.4 0.4]);
        title('error in analysis');
        colorbar;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%
        str=strcat('analysis_error','_',num2str(z),'_',num2str(l),'.jpg');
        saveas(gcf,str,'jpg');
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    clc
    load(fl_2);
    [n1,n2,n3]=size(te);
    depth=squeeze(de(1,1,:));
    rmse_val=[];
    temp=[];
    for ib=1:n3
        temp(:,:,ib)=squeeze(analysed_temp(:,:,ib))-squeeze(te(:,:,ib));
        rmse_val(ib)=sqrt(mse(reshape(squeeze(temp(:,:,ib)),n1*n2,1)));
    end

    rms_mat=cat(1,rms_mat,rmse_val);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    clc
    load(fl_1);
    Ea=cat(2,Ea,ea);
    delete('obs.dat');
    delete('final.dat');
    delete('lld_obs.dat');
    delete('output.dat');
    delete('temp.mat');
    delete('obse.mat');
    delete('for_ploting.mat');
    delete('final.mat');
    delete('interploate.mat');
    final_obs=[];
    save('vectors.mat','final_obs','-append');
    clearvars -except z rms_mat Ea;
    clc
end
save('error.mat','Ea','rms_mat');
