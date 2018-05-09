"""
    Copyright 2018.4. Byeong-Yong Jang
    byjang@cbnu.ac.kr
    This code is for training CNN.


    Input
    -----



    Options
    -------


"""
 

import logging
import os
import random
import sys
from optparse import OptionParser

import numpy
import tensorflow as tf

sys.path.append(os.path.dirname(os.path.abspath(os.path.dirname(__file__))))
from deeputils.deepio import array_io
from deeputils.deepio import common_io


os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

### Define function ###
def convert_class_from_list_to_array(lablist, classdict):
    lenlab = len(lablist)
    _lab_array = numpy.zeros(lenlab,dtype=int)
    i = 0
    for key in lablist:
        _lab_array[i] = int(classdict[key])
        i += 1
    return _lab_array

### End define function ###

def main():
    usage = "%prog [options] <train-data-file> <train-pos-file> <class-dict-file> <directory-for-save-model> <log-file>"
    parser = OptionParser(usage)

    # parser.add_option('--input-dim', dest='inDim',
    #                   help='Input dimension [default: The number of columns in the input data]',
    #                   default=0, type='int')
    # parser.add_option('--num-class', dest='numClass',
    #                   help='The number of classes [default: %default]',
    #                   default=5, type='int')
    # parser.add_option('--splice-size', dest='splice_size', help='left-right splice size [default: 5 ]',
    #                   default=5, type='int')
    # parser.add_option('--spec-stride', dest='spec_stride', help='interval between extracted spectrograms [default: 5 ]',
    #                   default=5, type='int')
    parser.add_option('--num-epoch', dest='num_epoch',
                      help='The number of epoch [default: %default]',
                      default=10, type='int')
    parser.add_option('--minibatch', dest='mini_batch',
                      help='mini-batch size [default: %default]',
                      default=10, type='int')
    parser.add_option('--lr', dest='lr',
                      help='learning rate [default: %default]',
                      default=0.0001, type='float')
    parser.add_option('--keep-prob', dest='keep_prob',
                      help='The probability that each element is kept in dropout [default: %default]',
                      default=0.6, type='float')
    parser.add_option('--val-rate', dest='val_rate',
                      help='validation data rate (%) [default: %default]',
                      default=10, type='int')
    parser.add_option('--val-iter', dest='val_iter',
                      help='Number of iterations to validate the trained model using validation data and recently trained mini-batch data[default: %default]',
                      default=100, type='int')
    parser.add_option('--shuff-epoch', dest='shuff_epoch',
                      help='Number of epochs to shuffle data [default: %default]',
                      default=1, type='int')
    parser.add_option('--save-iter', dest='save_iter',
                      help='Number of iterations to save the training model [default: %default]',
                      default=100, type='int')
    parser.add_option('--mdl-dir', dest='premdl',
                      help='Directory path of pre-model for training',
                      default='', type='string')
    parser.add_option('--active-function', dest='act_func',
                      help='active function relu or sigmoid [default: %default]',
                      default='relu', type='string')

    (o, args) = parser.parse_args()
    (datfile, posfile, classfile, expdir, logfile) = args

    print "Developing CNN script############"


    ## set the log 
    mylogger = logging.getLogger("trainDNN")
    mylogger.setLevel(logging.INFO)  # level: debug<info<warning<error<critical, default:warning

    # set print format. In this script: time, message
    formatter = logging.Formatter('Time: %(asctime)s,\nMessage: %(message)s')

    stream_handler = logging.StreamHandler()  # set handler, print to terminal window
    # stream_handler.setFormatter(formatter)
    mylogger.addHandler(stream_handler)

    file_handler = logging.FileHandler(logfile)  # set handler, print to log file
    file_handler.setFormatter(formatter)
    mylogger.addHandler(file_handler)
    ## The end of log setting

    # print command
    # mylogger.info(sys.argv)

    # don't print like format setted in formatter
    file_handler.setFormatter("")
    mylogger.addHandler(file_handler)

    # check the number of input argument
    if len(args) != 5:
        mylogger.info(parser.print_help())
        sys.exit(1)

    save_path = expdir + "/mdl"
    mini_batch = o.mini_batch
    nepoch = o.num_epoch
    lr = o.lr
    val_rate = o.val_rate  # validation data rate (valRate %)
    val_iter = o.val_iter
    save_iter = o.save_iter
    # splice_size = o.splice_size
    # spec_stride = o.spec_stride # the smaller value, the larger the number of spectrograms extracted from a wavfile
    keep_prob = o.keep_prob

    # filt_1 = [32, 5, 2]  # configuration for conv1 in [num_filt,kern_size,pool_stride]
    # filt_2 = [20, 5, 2]
    # num_fc_1 = 1024

    ### End parse options 
    
    ### Read file of train data and label
    # create dict using 'class-dict-file' for converting label(string) to label(int)
    class_dict = {}
    class_info = []
    with open(classfile) as f:
        classlist = f.readlines()

    for line in classlist:
        (labnum, labstr) = line.split()
        class_dict[labstr] = int(labnum)
        class_info.append(int(labnum))
    class_info = numpy.array(class_info)
    nclasses = len(class_info)

    # read scpfile
    pos_lab_list = array_io.read_pos_lab_file(posfile)

    random.shuffle(pos_lab_list)

    mylogger.info("Read validation data")
    val_inx = int(len(pos_lab_list)/100.0*val_rate)
    # val_inx = 5
    val_pos_lab_list = pos_lab_list[0:val_inx]

    val_data, val_lab_list = array_io.fast_load_array_from_pos_lab_list(datfile,val_pos_lab_list)
    val_lab = convert_class_from_list_to_array(val_lab_list, class_dict)

    val_lab_oh = common_io.dense_to_one_hot_from_range(val_lab, class_info)

    fdim = val_data[0].shape[0]
    tdim = val_data[0].shape[1]

    tr_pos_lab_list = pos_lab_list[val_inx:len(pos_lab_list)]
    total_batch = int(len(tr_pos_lab_list)/mini_batch)


    ### Main script ###
    mylogger.info('######### Configuration of CNN-model #########')
    mylogger.info('# Dimension of input data = [%d, %d], # of classes = %d' %(fdim,tdim,nclasses))
    mylogger.info('# Mini-batch size = %d, # of epoch = %d' %(mini_batch,nepoch))
    mylogger.info('# Learning rate = %f, probability of keeping in dropout = %0.1f' %(lr,keep_prob))
    mylogger.info('LOG : train data size = %d, # of iterations = %d'%(len(tr_pos_lab_list),total_batch))
    mylogger.info('LOG : validation data size is %d' % (val_data.shape[0]))
    # with tf.device('/gpu:0'):
    gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=0.8)
    sess = tf.InteractiveSession(config=tf.ConfigProto(gpu_options=gpu_options))
    #sess = tf.InteractiveSession()

    # make model #
    # x = tf.placeholder("float", [None, o.inDim], name="x")
    x = tf.placeholder("float",[None,fdim,tdim], name='x')
    lab_y = tf.placeholder("float", [None, nclasses], name="lab_y")
    keepProb = tf.placeholder("float", name="keepProb")
    bool_dropout = tf.placeholder(tf.bool, name="bool_dropout")
    # bool_batchnorm = tf.placeholder(tf.bool, name="bn_train")
    #
    with tf.name_scope("Reshaping_data") as scope:
        x_img = tf.reshape(x, [-1,fdim,tdim,1])
        img_size = numpy.array([fdim,tdim])

    with tf.name_scope("Layer 1: Conv_maxpool_dropout") as scope:
        conv1 = tf.layers.conv2d(inputs=x_img, filters=32, kernel_size=[3, 3],
                                 padding="SAME", activation=tf.nn.relu)
        pool1 = tf.layers.max_pooling2d(inputs=conv1, pool_size=[2,2],
                                        padding="SAME", strides=2)
        dropout1 = tf.layers.dropout(inputs=pool1, rate=keepProb, training=bool_dropout)
        img_size = numpy.floor(img_size/2.0)

    with tf.name_scope("Layer 2: Conv_maxpool_dropout") as scope:
        conv2 = tf.layers.conv2d(inputs=dropout1, filters=64, kernel_size=[3, 3],
                                 padding="SAME", activation=tf.nn.relu)
        pool2 = tf.layers.max_pooling2d(inputs=conv2, pool_size=[2,2],
                                        padding="SAME", strides=2)
        dropout2 = tf.layers.dropout(inputs=pool2, rate=keepProb, training=bool_dropout)
        img_size = numpy.floor(img_size/2.0)

    with tf.name_scope("Layer 3: Conv_maxpool_dropout") as scope:
        conv3 = tf.layers.conv2d(inputs=dropout2, filters=128, kernel_size=[3, 3],
                                 padding="SAME", activation=tf.nn.relu)
        pool3 = tf.layers.max_pooling2d(inputs=conv3, pool_size=[2, 2],
                                        padding="SAME", strides=2)
        dropout3 = tf.layers.dropout(inputs=pool3, rate=keepProb, training=bool_dropout)
        img_size = numpy.floor(img_size / 2.0)

    with tf.name_scope("Layer 4: Fully_Connected") as scope:
        flat_size = img_size[0]*img_size[1]*128
        flat4 = tf.reshape(dropout3, [-1, flat_size])
        fc4 = tf.layers.dense(inputs=flat4, units=2048, activation=tf.nn.relu)
        dropout4 = tf.layers.dropout(inputs=fc4, rate=keepProb, training=bool_dropout)

    with tf.name_scope("Layer 5: Fully_Connected") as scope:
        fc5 = tf.layers.dense(inputs=dropout4, units=1028, activation=tf.nn.relu)
        dropout5 = tf.layers.dropout(inputs=fc5, rate=keepProb, training=bool_dropout)

    with tf.name_scope("Output_layer") as scope:
        out_y = tf.layers.dense(inputs=dropout5, units=nclasses, name="out_y")

    with tf.name_scope("SoftMax") as scope:
        cross_entropy = tf.reduce_mean(tf.nn.softmax_cross_entropy_with_logits(logits=out_y,labels=lab_y),name="ce")

        #loss_summ = tf.scalar_summary("cross entropy_loss", cost)

    train_step = tf.train.AdamOptimizer(lr).minimize(cross_entropy)

    # begin training

    init = tf.global_variables_initializer()
    sess.run(init)

    correct_prediction = tf.equal(tf.argmax(out_y,1),tf.argmax(lab_y,1))
    accuracy = tf.reduce_mean(tf.cast(correct_prediction, "float"), name="acc")


    if o.premdl != "":
        mylogger.info('LOG : train using pre-model -> %s' %(o.premdl) )
        graph = tf.get_default_graph()
        saver = tf.train.Saver(max_to_keep=None)
        saver.restore(sess, tf.train.latest_checkpoint(o.premdl))
    else:
        saver = tf.train.Saver(max_to_keep=None)

    saver.save(sess, save_path) # save meta-graph
    mylogger.info("LOG : initial model save with meta-graph -> %s" % save_path)

    epoch=0
    iter=0
    while(epoch<nepoch):
        epoch=epoch+1
        if epoch%o.shuff_epoch==0:
            mylogger.info("LOG : shuffling train data")

        begi = 0
        endi = begi + mini_batch
        for imbatch in xrange(total_batch):
            batch_data, batch_lab = array_io.fast_load_array_from_pos_lab_list(datfile,tr_pos_lab_list[begi:endi])
            batch_lab_oh = common_io.dense_to_one_hot_from_range(convert_class_from_list_to_array(batch_lab,class_dict),class_info)

            feed_dict = {x: batch_data, lab_y: batch_lab_oh, keepProb: keep_prob, bool_dropout: True}
            sess.run(train_step, feed_dict)
            iter = iter + 1

            if (iter%val_iter==0) | (iter==1): # print state of training for validation data and mini-batch
                val_acc = []
                val_ce = []
                for i in range(int(val_data.shape[0]/mini_batch+1)):
                    begi = i*mini_batch
                    endi = (i+1)*mini_batch
                    if begi >= val_data.shape[0]:
                        break
                    if endi > val_data.shape[0]:
                        endi = val_data.shape[0]
                    ipred_val = sess.run(out_y, feed_dict={x: val_data[begi:endi],
                                                           keepProb: 1.0, bool_dropout: False})
                    ival_acc = sess.run(accuracy, feed_dict={out_y: ipred_val, lab_y: val_lab_oh[begi:endi]})
                    ival_ce = sess.run(cross_entropy, feed_dict={out_y: ipred_val, lab_y: val_lab_oh[begi:endi]})
                    val_acc.append(ival_acc)
                    val_ce.append(ival_ce)
                val_acc = numpy.mean(numpy.array(val_acc))
                val_ce = numpy.mean(numpy.array(val_ce))

                pred_tr = sess.run(out_y, feed_dict={x: batch_data, keepProb: 1.0, bool_dropout: False})
                tr_acc = sess.run(accuracy, feed_dict={out_y: pred_tr, lab_y: batch_lab_oh})
                tr_ce = sess.run(cross_entropy, feed_dict={out_y: pred_tr, lab_y: batch_lab_oh})

                # set formatter format(time, message)
                file_handler.setFormatter(formatter)
                mylogger.addHandler(file_handler)
                mylogger.info('%d epoch, %d iter (tr/va ce acc) | %f %2.1f%% %f %2.1f%%'
                              %(epoch, iter,tr_ce, (tr_acc*100), val_ce,(val_acc*100)))

                if (iter%save_iter==0) | (iter==1): # save parameter
                    saver.save(sess, save_path, global_step=iter, write_meta_graph=False)


    saver.save(sess, save_path, global_step=iter, write_meta_graph=False) # last model save
    mylogger.info("### done \n")

if __name__=="__main__":
    main()



