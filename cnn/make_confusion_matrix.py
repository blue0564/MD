

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
    confmat2 = np.zeros((2,2),dtype=int)
    music_str = ('music', 'mu_no', 'mixed')
    class_dict2 = {0:'music', 1:'others'}

    with open(pred_lab_file,'r') as f:
        pred_lab_list = f.readlines()

    for pred_lab in pred_lab_list:
        pred = int(pred_lab.split()[0])
        lab = int(pred_lab.split()[1])
        confmat[pred,lab] += 1

        pred_str = class_dict[pred]
        lab_str = class_dict[lab]
        pred2 = 0 if pred_str in music_str else 1
        lab2 = 0 if lab_str in music_str else 1
        confmat2[pred2,lab2] += 1

    ncorrect = 0.0
    totaln = 0.0
    for i in xrange(nclasses):
        totaln += np.sum(confmat[:,i])
        ncorrect += confmat[i,i]
    acc = (ncorrect/totaln)*100.0

    with open(confmat_file,'w') as f:
        f.write("Total number : %d\n"%(len(pred_lab_list)))
        f.write("Accuracy : %0.2f\n"%(acc))
        f.write("pred\\refs :")
        for cls in xrange(nclasses):
            f.write("\t%s"%class_dict[cls])
        f.write("\n")
        for i in range(nclasses):
            f.write("%s\t"%class_dict[i])
            for j in range(nclasses):
                f.write("\t%d"%(confmat[i,j]))
            f.write("\n")

    recall = float(confmat2[0,0]) / float(confmat2[0,0] + confmat2[1,0])
    precision = float(confmat2[0,0]) / float(confmat2[0,0] + confmat2[0,1])
    accuracy = float(confmat2[0,0] + confmat2[1,1]) / totaln
    f1score = 2.0/(1.0/recall + 1.0/precision)

    with open(confmat_file,'a') as f:
        f.write("==========================\n")
        f.write("F1 score : %0.3f\n"%(f1score))
        f.write("Accuracy : %0.3f\n"%(accuracy))
        f.write("Recall : %0.3f\n" % (recall))
        f.write("Precision : %0.3f\n" % (precision))
        f.write("pred\\refs :")
        for cls in xrange(2):
            f.write("\t%s"%class_dict2[cls])
        f.write("\n")
        for i in range(2):
            f.write("%s\t"%class_dict2[i])
            for j in range(2):
                f.write("\t%d"%(confmat2[i,j]))
            f.write("\n")


if __name__=="__main__":
    main()
