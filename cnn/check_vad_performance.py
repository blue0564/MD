
import sys
import os
import numpy as np
from optparse import OptionParser

sys.path.append(os.path.dirname(os.path.abspath(os.path.dirname(__file__))))
from deeputils.deepio import array_io

def main():
    usage = "%prog [options] <pos-lab-vad-file> <confusion-matrix-file>"
    parser = OptionParser(usage)

    # parser.add_option('--num-classes', dest='nclasses',
    #                   help='Number of classes [default: %default]',
    #                   default=5, type='int')
    # parser.add_option("--class-file", dest="classfile", help="class map file",
    #                   default='', type='string')
    parser.add_option("--class-file", dest="classfile", help="class map file",
                      default='', type='string')

    (o, args) = parser.parse_args()
    (pred_lab_vad_file, confmat_file) = args

    nclasses = 5
    confmat = np.zeros((2,nclasses),dtype=int)
    classfile = o.classfile

    class_dict = {}
    class_dict_rev = {}
    class_info = []
    with open(classfile) as f:
        classlist = f.readlines()

    for line in classlist:
        (labnum, labstr) = line.split()
        class_dict[labstr] = int(labnum)
        class_dict_rev[int(labnum)] = labstr.strip()
        class_info.append(int(labnum))
    class_info = np.array(class_info)
    nclasses = len(class_info)

    pred_lab_vad_list = array_io.read_pos_lab_vad_file(pred_lab_vad_file)

    for _, refs_, vad_ in pred_lab_vad_list:
        lab = int(class_dict[refs_])
        pred = int(vad_)
        confmat[pred,lab] += 1

    with open(confmat_file,'w') as f:
        f.write("Total number : %d\n"%(len(pred_lab_vad_list)))
        f.write("pred\\refs :")
        for cls in xrange(nclasses):
            f.write("\t%s"%class_dict_rev[cls])
        f.write("\n")
        for i in range(2):
            vad_str = ('nonsil' if i==1 else 'sil')
            f.write("%s\t"%vad_str)
            for j in range(nclasses):
                f.write("\t%d"%(confmat[i,j]))
            f.write("\n")



if __name__=="__main__":
    main()