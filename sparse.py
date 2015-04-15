import sys
import numpy as np
import scipy.io as sio
from scipy.sparse import coo_matrix
R=int(sys.argv[1])
C=int(sys.argv[2])
content =sio.loadmat('interploate.mat')
inter=content['final']
row=np.array(inter[0])
col=np.array(inter[1])
dat=np.array(inter[2])
final=coo_matrix((dat,(row,col)),shape=(R,C))
sio.savemat('final.mat',{'final':final})
