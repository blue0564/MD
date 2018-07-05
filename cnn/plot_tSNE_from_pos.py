import os
import sys
from optparse import OptionParser

import random
import numpy as np
import matplotlib.pyplot as plt
from sklearn.manifold import TSNE

sys.path.append(os.path.dirname(os.path.abspath(os.path.dirname(__file__))))
from deeputils.deepio import array_io

def plot_tSNE(data_,lab_,fignum=1):
    target_data = data_[:]
    target_lab = lab_[:]
    tmdl = TSNE(learning_rate=100)

    spinx = []
    muinx = []
    mxinx = []
    noinx = []
    slinx = []

    i = 0
    for lab_ in target_lab:
        if lab_ == 'speech':
            spinx.append(int(i))
        elif (lab_ == 'music') | (lab_ == 'mu_no'):
            muinx.append(int(i))
        elif lab_ == 'mixed':
            mxinx.append(int(i))
        elif lab_ == 'noise':
            noinx.append(int(i))
        elif lab_ == 'sil':
            slinx.append(int(i))

        i += 1

    ndim = len(target_data.shape)
    if ndim > 2:
        if target_data.shape[2] == 1:
            target_data = np.squeeze(target_data, axis=2)
        else:
            (ndata, nrow, ncol) = target_data.shape
            print 'LOG: reshape data (%d, %d, %d) -> (%d, %d)' % (ndata, nrow, ncol, ndata, int(nrow * ncol))
            target_data = np.reshape(target_data, (ndata, nrow * ncol))
    elif ndim > 3:
        assert ('ERROR(t-SNE): wrong a dimemsion of data')

    emb = tmdl.fit_transform(target_data)
    symsize=10
    plt.figure(fignum)
    plt.scatter(emb[spinx, 0], emb[spinx, 1], c='r', s=symsize, label='speech')
    plt.scatter(emb[muinx, 0], emb[muinx, 1], c='b', s=symsize, label='music')
    plt.scatter(emb[mxinx, 0], emb[mxinx, 1], c='y', s=symsize, label='mixed')
    plt.scatter(emb[noinx, 0], emb[noinx, 1], c='g', marker='^', s=symsize, label='noise')
    plt.scatter(emb[slinx, 0], emb[slinx, 1], c='c', marker='s', s=symsize, label='sil')
    plt.legend()

    return plt


def main():

    usage = "%prog [options] <data-file> <pos-file> "
    parser = OptionParser(usage)

    parser.add_option("-t", "--timemode", action="store_true", dest="timemode",
                      help="time-axis based analysis mode", default=False)
    parser.add_option('--num-data', dest='num_data', help='number of data for plot [default: all ]',
                      default=-1, type='int')
    parser.add_option('--figure-file', dest='figure_file', help='figure file name to save',
                      default='', type='string')


    (o, args) = parser.parse_args()
    (datfile, posfile) = args

    pos_lab_list = array_io.read_pos_lab_file(posfile)


    if o.num_data == -1:
        target_list = pos_lab_list[:]
    else:
        random.shuffle(pos_lab_list)
        target_list = pos_lab_list[0:o.num_data]

    target_data, target_lab = array_io.fast_load_array_from_pos_lab_list(datfile,target_list)

    if o.timemode :
        (ndata, nfft, ntime) = target_data.shape
        # idata = np.zeros((ndata,ntime))
        for i in xrange(nfft):
            idata = target_data[:,i,:]
            fig_file = '%s%d'%(o.figure_file,i)
            plt = plot_tSNE(idata,target_lab,(i+1))
            if o.figure_file != '':
                plt.savefig(fig_file, dpi=500, format='png')
            else:
                plt.show()
            plt.close()
    else:
        plt = plot_tSNE(target_data, target_lab)
        if o.figure_file != '':
            plt.savefig(o.figure_file, dpi=500, format='png')
        else:
            plt.show()







if __name__ == "__main__":
    main()
