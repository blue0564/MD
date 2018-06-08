#!/usr/bin/env python

import tensorflow as tf
import numpy as np
import sys
import os
import logging
sys.path.append(os.path.dirname(os.path.abspath(os.path.dirname(__file__))))
from deeputils.deepio import array_io
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'


def main():
  gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=0.2)

  # sess = tf.InteractiveSession(config=tf.ConfigProto(gpu_options=gpu_options))
  sess = tf.InteractiveSession()

  ###
  ### Parse options
  ###
  from optparse import OptionParser
  usage = "%prog [options] <test-data-file> <test-pos-label-file> <directory of model> <convout-data-file> <convout-pos-file> <log-file>"
  parser = OptionParser(usage)

  parser.add_option('--checkpoint', dest='checkpoint',
                    help='Checkpoint number to use DNN model [default: last checkpoint]',
                    default=0, type='int')

  print '######### Extract conv-net output with DNN-model #########'

  (o, args) = parser.parse_args()
  (datfile, posfile, mdldir, outdatafile, outposfile, logfile) = args

  ## set the log
  mylogger = logging.getLogger("extract conv-output of CNN")
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

  if len(args) != 6:
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
    keepProb = graph.get_tensor_by_name("keepProb:0")
    bool_dropout = graph.get_tensor_by_name("bool_dropout:0")
    convout = graph.get_tensor_by_name("Layer_4_Fully_Connected/conv_flat:0")

    # mylogger.info("Read data")
    pos_lab_list = array_io.read_pos_lab_file(posfile)
    niter = int(len(pos_lab_list)/500) + 1

    begi = 0
    for i in xrange(niter):
        endi = begi + 500
        if endi > len(pos_lab_list):
            endi = len(pos_lab_list)

        ipos = pos_lab_list[begi:endi]
        data_, lab_list_ = array_io.fast_load_array_from_pos_lab_list(datfile,ipos)
    # mylogger.info("End of reading data")

        conv_out = sess.run(convout,feed_dict={x:data_, keepProb:1.0, bool_dropout: False})
        for i in xrange(conv_out.shape[0]):
            posi = array_io.save_append_array(outdatafile,conv_out[i])
            with open(outposfile,'a') as f:
                f.write("%i %s\n"%(posi,lab_list_[i]))


        begi += 500







if __name__=="__main__":
    main()
