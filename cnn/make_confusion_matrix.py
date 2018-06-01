

import numpy as np
from optparse import OptionParser

def main():
    usage = "%prog [options] <pred-lab-file> <confusion-matrix-file>"
    parser = OptionParser(usage)

    parser.add_option('--num-classes', dest='nclasses',
                      help='Number of classes [default: %default]',
                      default=5, type='int')
    parser.add_option("--class-file", dest="classfile", help="class map file",
                      default='', type='string')



    (o, args) = parser.parse_args()
    (pred_lab_file, confmat_file) = args

    nclasses = o.nclasses
    classfile = o.classfile

    if classfile != '':
        # create dict using 'class-dict-file' for converting label(string) to label(int)
        class_dict = {}
        class_info = []
        with open(classfile) as f:
            classlist = f.readlines()

        for line in classlist:
            (labnum, labstr) = line.split()
            class_dict[int(labnum)] = labstr.strip()
            class_info.append(labstr.strip())
        nclasses = len(class_info)
    else:
        class_dict = [str(i) for i in range(nclasses)]

    confmat = np.zeros((nclasses,nclasses),dtype=int)

    with open(pred_lab_file,'r') as f:
        pred_lab_list = f.readlines()

    for pred_lab in pred_lab_list:
        pred = int(pred_lab.split()[0])
        lab = int(pred_lab.split()[1])
        confmat[pred,lab] += 1

    with open(confmat_file,'w') as f:
        f.write("Total number : %d\n"%(len(pred_lab_list)))
        f.write("pred\\refs :\t")
        for cls in xrange(nclasses):
            f.write("\t%s"%class_dict[cls])
        f.write("\n")
        for i in range(nclasses):
            f.write("%s\t"%class_dict[i])
            for j in range(nclasses):
                f.write("\t%d"%(confmat[i,j]))
            f.write("\n")



if __name__=="__main__":
    main()