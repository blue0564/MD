#!/usr/bin/env python

import tensorflow as tf
import numpy as np
import sys
import os
import logging
sys.path.append(os.path.dirname(os.path.abspath(os.path.dirname(__file__))))
from deeputils.deepio import array_io
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

def convert_class_from_list_to_array(lablist, classdict):
    lenlab = len(lablist)
    _lab_array = np.zeros(lenlab,dtype=int)
    i = 0
    for key in lablist:
        _lab_array[i] = int(classdict[key])
        i += 1
    return _lab_array

def make_label_with_mixed(prob_):
    sp_inx = 1
    mu_inx = 2
    mx_inx = 4

    _lab = np.zeros(prob_.shape[0],dtype=int)
    i = 0
    for pr in prob_:
        if (pr[sp_inx] > 0.35) & (pr[mu_inx] > 0.35):
            ilab = mx_inx
        else:
            ilab = np.argmax(pr)

        _lab[i] = ilab
        i +=1
    return _lab

def main():
  gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=0.2)

  # sess = tf.InteractiveSession(config=tf.ConfigProto(gpu_options=gpu_options))
  sess = tf.InteractiveSession()

  ###
  ### Parse options
  ###
  from optparse import OptionParser
  usage = "%prog [options] <test-data-file> <test-pos-label-file> <directory of model> <class-dict-file> <log-file>"
  parser = OptionParser(usage)

  parser.add_option('--out-predprob', dest='predprob',
                    help='Output file of predicted probability',
                    default='', type='string')

  parser.add_option('--out-predlab', dest='predlab',
                    help='Output file of predicted label',
                    default='', type='string')

  parser.add_option('--min-predlab', dest='minpredlab',
                    help='Minimum value of predicted label [default: %default]',
                    default=0, type='int')

  parser.add_option('--checkpoint', dest='checkpoint',
                    help='Checkpoint number to use DNN model [default: last checkpoint]',
                    default=0, type='int')

  print '######### Predict data with DNN-model #########'

  (o, args) = parser.parse_args()
  (datfile, posfile, mdldir, classfile, logfile) = args

  ## set the log
  mylogger = logging.getLogger("predict CNN")
  mylogger.setLevel(logging.INFO)  # level: debug<info<warning<error<critical, default:warning

  # set print format. In this script: time, message
  formatter = logging.Formatter('%(message)s | %(asctime)s')

  stream_handler = logging.StreamHandler()  # set handler, print to terminal window
  # stream_handler.setFormatter(formatter)
  mylogger.addHandler(stream_handler)

  file_handler = logging.FileHandler(logfile)  # set handler, print to log file
  file_handler.setFormatter(formatter)
  mylogger.addHandler(file_handler)
  ## The end of log setting

  # don't print like format setted in formatter
  file_handler.setFormatter("")
  mylogger.addHandler(file_handler)

  if len(args) != 5:
    mylogger.info(parser.print_help())
    sys.exit(1)

  file_handler.setFormatter(formatter)
  mylogger.addHandler(file_handler)
  mylogger.info("Start predict cnn")

  with tf.device('/cpu:0'):
    # load meta graph and restore weights
    mylogger.info('LOG : load model -> %s' %(mdldir+'/mdl.meta'))
    graph = tf.get_default_graph()
    saver = tf.train.import_meta_graph(mdldir+'/mdl.meta')
    if o.checkpoint > 0 :
      checkpoint = '%s/mdl-%d' %(mdldir,o.checkpoint)
    else :
      checkpoint = tf.train.latest_checkpoint(mdldir)

    saver.restore(sess, checkpoint)
    mylogger.info('LOG : checkpoint -> %s ' %(checkpoint))

    x = graph.get_tensor_by_name("x:0")
    lab_y = graph.get_tensor_by_name("lab_y:0")
    out_y_softmax = graph.get_tensor_by_name("SoftMax/out_y_softmax:0")
    keepProb = graph.get_tensor_by_name("keepProb:0")
    bool_dropout = graph.get_tensor_by_name("bool_dropout:0")
    # ce = graph.get_tensor_by_name("SoftMax/ce:0")
    # acc = graph.get_tensor_by_name("acc:0")

    a = tf.placeholder(tf.int16)
    b = tf.placeholder(tf.int16)
    correct_prediction = tf.equal(a,b)
    accuracy = tf.reduce_mean(tf.cast(correct_prediction, "float"))

    class_dict = {}
    class_info = []
    with open(classfile) as f:
        classlist = f.readlines()

    for line in classlist:
        (labnum, labstr) = line.split()
        class_dict[labstr] = int(labnum)
        class_info.append(int(labnum))
    class_info = np.array(class_info)
    nclasses = len(class_info)

    # mylogger.info("Read data")
    pos_lab_list = array_io.read_pos_lab_file(posfile)
    niter = int(len(pos_lab_list)/500) + 1

    acclist = []
    begi = 0
    for i in xrange(niter):
        endi = begi + 500
        if endi > len(pos_lab_list):
            endi = len(pos_lab_list)

        ipos = pos_lab_list[begi:endi]
        data_, lab_list_ = array_io.fast_load_array_from_pos_lab_list(datfile,ipos)
    # mylogger.info("End of reading data")

        ref_lab = convert_class_from_list_to_array(lab_list_, class_dict)
        pred_prob = sess.run(out_y_softmax,feed_dict={x:data_, keepProb:1.0, bool_dropout: False})
        pred_label = make_label_with_mixed(pred_prob)
        iacc = sess.run(accuracy, feed_dict={a: pred_label, b: ref_lab})
        acclist.append(iacc)
        mylogger.info("%d - %d : %0.2f"%(begi,endi,iacc))
        if o.predlab != '':
            with open(o.predlab,'a') as f:
                for j in xrange(pred_label.shape[0]):
                    f.write("%d %d\n"%(pred_label[j],ref_lab[j]))

        begi += 500

    acc_result = np.mean(np.array(acclist))

    mylogger.info("Total accuracy : %0.3f" % (acc_result))



    # pred_prob  = sess.run(out_y,feed_dict)
  #
  #   pred_data =  sess.run(out_y,feed_dict ={x:test_data, keepProb:1.0})
  #
  # if in_lab:
  #   test_lab = myio.read_label_file(label_file)
  #   test_lab_ot = myio.dense_to_one_hot(test_lab,2)
  #
  #   # The 'pred_acc', 'pred_ce' is modified by WoonHaeng, Heo in 2018.03.21.0919
  #   # The 'keepProb:1.0' command is added
  #   pred_acc = sess.run(acc, feed_dict={out_y: pred_data, lab_y: test_lab_ot, keepProb:1.0})
  #   pred_ce = sess.run(ce, feed_dict={out_y: pred_data, lab_y: test_lab_ot, keepProb:1.0})
  #   print 'Results : '
  #   print '  # of data = %d' %(pred_data.shape[0])
  #   print '  average of cross entropy = %f' %(pred_ce)
  #   print '  accuracy = %2.1f%%' %(pred_acc*100)
  #   print '### done\n'
  #
  # if o.predprob != '':
  #   print 'LOG : write predicted probability -> %s' %(o.predprob)
  #   myio.write_predicted_prob(pred_data,o.predprob)
  #
  # if o.predlab != '':
  #   print 'LOG : write predicted label -> %s' %(o.predlab)
  #   pred_lab = numpy.argmax(pred_data, axis=1) + o.minpredlab
  #   myio.write_predicted_lab(pred_lab,o.predlab)


if __name__=="__main__":
    main()