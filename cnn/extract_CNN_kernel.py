#!/usr/bin/env python

import tensorflow as tf
import numpy as np
import sys
import os
import matplotlib.pyplot as plt
sys.path.append(os.path.dirname(os.path.abspath(os.path.dirname(__file__))))
from deeputils.feature import extract_spec

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'


def main():
  gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=0.2)

  # sess = tf.InteractiveSession(config=tf.ConfigProto(gpu_options=gpu_options))
  sess = tf.InteractiveSession()

  mdldir = '../exp/cnn_drama_6class_melcnn_init_tanh/1'
  ckpt = 50000


  with tf.device('/cpu:0'):
    # load meta graph and restore weights
    graph = tf.get_default_graph()
    saver = tf.train.import_meta_graph(mdldir+'/mdl.meta')
    checkpoint = '%s/mdl-%d' %(mdldir,ckpt)

    saver.restore(sess, checkpoint)

    melinx, meldim, melfilt = extract_spec.mel_scale_range(2048, 16000, 64)

    cnnfilt = np.zeros(melfilt.shape)

    plt.figure(1)
    for imel in xrange(64):
        kername = "conv_%d/kernel:0" %(imel)
        kernel = tf.squeeze(graph.get_tensor_by_name(kername))
        out_ker = sess.run(kernel)
        cnnfilt[imel,melinx[imel]] = out_ker
        plt.plot(cnnfilt[imel])
        # plt.plot(melfilt[imel])


    plt.show()








if __name__=="__main__":
    main()
