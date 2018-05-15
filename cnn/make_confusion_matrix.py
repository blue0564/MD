

import numpy as np
from optparse import OptionParser




def main():
    usage = "%prog [options] <pred-lab-file> <confusion-matrix-file>"
    parser = OptionParser(usage)

    parser.add_option('--num-classes', dest='nclasses',
                      help='Number of classes [default: %default]',
                      default=5, type='int')

    (o, args) = parser.parse_args()
    (pred_lab_file, confmat_file) = args

    nclasses = o.nclasses

    confmat = np.zeros((nclasses,nclasses),dtype=int)

    with open(pred_lab_file,'r') as f:
        pred_lab_list = f.readlines()

    for pred_lab in pred_lab_list:
        pred = int(pred_lab.split()[0])
        lab = int(pred_lab.split()[1])
        confmat[pred,lab] += 1

    with open(confmat_file,'w') as f:
        f.write("Total number : %d\n"%(len(pred_lab_list)))
        f.write("pred\\refs :\t0\t1\t2\t3\t4\n")
        for i in range(nclasses):
            f.write("\t")
            for j in range(nclasses):
                f.write("\t%d"%(confmat[i,j]))
            f.write("\n")



if __name__=="__main__":
    main()