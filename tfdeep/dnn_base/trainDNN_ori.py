#!/usr/bin/env python

import tensorflow as tf
import numpy 
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(os.path.dirname(__file__))))
from common import common_io as myio
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

gpu_options = tf.GPUOptions(per_process_gpu_memory_fraction=1)
sess = tf.InteractiveSession(config=tf.ConfigProto(gpu_options=gpu_options))

###
### Parse options
###
from optparse import OptionParser
usage="%prog [options] <train-data-file> <train-label-file> <directory-for-save-model>"
parser = OptionParser(usage)

parser.add_option('--feat-dim', dest='featDim', 
                   help='Feature dimension [default: %default]', 
                   default=0, type='int');

parser.add_option('--num-class', dest='numClass', 
                   help='The number of classes [default: %default]', 
                   default=5, type='int');

parser.add_option('--num-epoch', dest='numEpoch', 
                   help='The number of epoch [default: %default]', 
                   default=10, type='int');

parser.add_option('--minibatch', dest='mBatch', 
                   help='mini-batch size [default: %default]', 
                   default=10, type='int');

parser.add_option('--lr', dest='lr', 
                   help='learning rate [default: %default]', 
                   default=0.0001, type='float');

parser.add_option('--keep-prob', dest='kProb', 
                   help='The probability that each element is kept in dropout [default: %default]', 
                   default=0.6, type='float');
parser.add_option('--valRate', dest='valRate', 
                   help='validation data rate (%) [default: %default]', 
                   default=10, type='int');

parser.add_option('--valEpoch', dest='valEpoch', 
                   help='Number of epochs to validate the trained model [default: %default]', 
                   default=100, type='int');

parser.add_option('--shuff-epoch', dest='shuffEpoch', 
                   help='Number of epochs to shuffle data [default: %default]', 
                   default=100, type='int');

parser.add_option('--save-epoch', dest='saveEpoch', 
                   help='Number of epochs to save the training model [default: %default]', 
                   default=100, type='int');

parser.add_option('--last-layer', dest='last_layer', 
                   help='set last layer of 5 layers ', 
                   default='hid5', type='string');

parser.add_option('--mdl-dir', dest='premdl', 
                   help='Directory path of pre-model for training', 
                   default='', type='string');


(o,args) = parser.parse_args()
if len(args) != 3 : 
  parser.print_help()
  sys.exit(1)
  
#(trDataFile, trLabelFile, tsDataFile, tsLabelFile) = map(int,args);
(trDataFile, trLabelFile, expdir) = args

save_path = expdir + "/dnnmdl"
miniBatch = o.mBatch
nEpoch = o.numEpoch
lr = o.lr
valRate = o.valRate # validation data rate (valRate %) 

hidNode_map = {
  'hid1':1000,
  'hid2':1000,
  'hid3':1000,
  'hid4':1000,
  'hid5':1000
}
lastLayer = o.last_layer
hidNode1 = hidNode_map['hid1']
hidNode2 = hidNode_map['hid2']
hidNode3 = hidNode_map['hid3']
hidNode4 = hidNode_map['hid4']
hidNode5 = hidNode_map['hid5']
lastNode = hidNode_map[lastLayer]

### End parse options 

print '######### Train DNN-model #########'
print 'Stats : numFeat = %d, numClass = %d' %(o.featDim,o.numClass)
print 'Stats : miniBatch = %d, nEpoch = %d, lr = %f' %(miniBatch,nEpoch,lr)
print 'Stats : # of hidden node - hid1 : %d, hid2 : %d, hid3 : %d, hid4 : %d, hid5 : %d' %(hidNode1,hidNode2,hidNode3,hidNode4,hidNode5)
print 'Stats : last layer = %s' %(lastLayer)


### Define function ###
def weight_variable(shape,name=""):
  initial = tf.truncated_normal(shape, stddev=0.1)
  if name == "":
    return tf.Variable(initial)
  else:
    return tf.Variable(initial, name=name)

def bias_variable(shape,name=""):
  initial = tf.constant(0.1, shape=shape)
  if name == "":
    return tf.Variable(initial)
  else:
    return tf.Variable(initial, name=name)

def trainShuff(trainData,trainLabel):
    
    length=trainData.shape[0]
    rng=numpy.random.RandomState(0517)
    train_ind=range(0,length)
    rng.shuffle(train_ind)

    RanTrainData=trainData[train_ind,]
    RanTrainLabel=trainLabel[train_ind,]

    return RanTrainData,RanTrainLabel

def next_batch(pre_index, batch_size, data_size):
  """Return the next `batch_size` examples from this data set."""
# Usage
#pre_index = 0
#for i in range(100000):
#  beg_index, end_index = next_batch(pre_index, miniBatch, len(trData))
#  pre_index = end_index
#  feed_dict = {x: trData[beg_index:end_index], y_: trLabel[beg_index:end_index]}
  #print(beg_index,end_index)
#  sess.run(train_step, feed_dict)

  start = pre_index
  check_index = start + batch_size
  if  check_index > data_size:
    # Start next epoch
    start = 0

  end = start + batch_size
  return start, end
### End define function ###


### Read file of train/test data and label

oriTrData, o.featDim = myio.read_data_file(trDataFile,o.featDim)
oriTrLabel_tmp = myio.read_label_file(trLabelFile)
oriTrLabel = myio.dense_to_one_hot(oriTrLabel_tmp,o.numClass)


# for check one-hot label
#trOnehotLabFile = "%s_oh" %(trLabelFile)
#wl1 = open(trOnehotLabFile,'w')

#for l in range(len(oriTrLabel)):
#  for m in range(o.numClass):
#    buf1 = "%f " %(oriTrLabel[l][m]) 
#    wl1.write(buf1)
#  wl1.write('\n')
#wl1.close()
# end of check


oriTrData, oriTrLabel=trainShuff(oriTrData, oriTrLabel) # shuffling

valInx = oriTrData.shape[0]/100*valRate
valData = oriTrData[0:valInx]
valLabel = oriTrLabel[0:valInx]

trData = oriTrData[valInx+1:oriTrData.shape[0]]
trLabel = oriTrLabel[valInx+1:oriTrLabel.shape[0]]
print "featdim : %d" %(trData.shape[1])

print 'LOG : validation data is %d (%d%%) of %d training data' %(valInx,valRate,(oriTrData.shape[0]+1))

totalBatch = trData.shape[0]/miniBatch
print 'LOG : train data size = %d, # of iterations = %d' %(trData.shape[0],totalBatch)

### Main script ###

# make model #
x = tf.placeholder("float", [None, o.featDim], name="x")
y_ = tf.placeholder("float", [None, o.numClass], name="y_")
keepProb = tf.placeholder("float", name="keepProb")

# tf.sigmoid / tf.nn.relu

W1 = weight_variable([o.featDim, hidNode1])
b1 = bias_variable([hidNode1],"b1")
#h1 = tf.nn.relu(tf.matmul(x,W1) + b1)
h1 = tf.sigmoid(tf.matmul(x,W1) + b1)

h1Drop = tf.nn.dropout(h1, keepProb)

W2 = weight_variable([hidNode1, hidNode2])
b2 = bias_variable([hidNode2])
#h2 = tf.nn.relu(tf.matmul(h1,W2) + b2)
h2 = tf.sigmoid(tf.matmul(h1Drop,W2) + b2)

h2Drop = tf.nn.dropout(h2, keepProb)

W3 = weight_variable([hidNode2, hidNode3])
b3 = bias_variable([hidNode3])
#h3 = tf.nn.relu(tf.matmul(h2,W3) + b3)
h3 = tf.sigmoid(tf.matmul(h2Drop,W3) + b3)

h3Drop = tf.nn.dropout(h3, keepProb)

W4 = weight_variable([hidNode3, hidNode4])
b4 = bias_variable([hidNode4])
#h4 = tf.nn.relu(tf.matmul(h3,W4) + b4)
h4 = tf.sigmoid(tf.matmul(h3Drop,W4) + b4)

h4Drop = tf.nn.dropout(h4, keepProb)

W5 = weight_variable([hidNode4, hidNode5])
b5 = bias_variable([hidNode5])
#h5 = tf.nn.relu(tf.matmul(h4,W5) + b5)
h5 = tf.sigmoid(tf.matmul(h4Drop,W5) + b5)

h5Drop = tf.nn.dropout(h5, keepProb)

hidLayer_map = {
  'hid1':h1Drop,
  'hid2':h2Drop,
  'hid3':h3Drop,
  'hid4':h4Drop,
  'hid5':h5Drop
}

W_last = weight_variable([lastNode, o.numClass],"w_last")
b_last = bias_variable([o.numClass],"b_last")

op_last = tf.matmul(hidLayer_map[lastLayer],W_last,name="op_last")
y = tf.nn.softmax(op_last + b_last, name="oper")

cross_entropy = -tf.reduce_sum(y_*tf.log(y), name="ce")
train_step = tf.train.AdamOptimizer(lr).minimize(cross_entropy)

# begin training

init = tf.global_variables_initializer()
sess.run(init)

correct_prediction = tf.equal(tf.argmax(y,1),tf.argmax(y_,1))
accuracy = tf.reduce_mean(tf.cast(correct_prediction, "float"), name="acc")


if o.premdl != "":
  print 'LOG : train using pre-model -> %s' %(o.premdl) 
  graph = tf.get_default_graph()
  saver = tf.train.Saver(max_to_keep=None)
  #saver = tf.train.import_meta_graph(o.premdl+"/dnnmdl.meta")
  saver.restore(sess, tf.train.latest_checkpoint(o.premdl))
else:
  saver = tf.train.Saver(max_to_keep=None)

saver.save(sess, save_path) # save meta-graph
print("LOG : initial model save with meta-graph -> %s" % save_path)

epoch=0
while(epoch<nEpoch):
  epoch=epoch+1
  if epoch%o.shuffEpoch==0:	
    trData, trLabel=trainShuff(trData, trLabel)
    #print 'LOG : data shuffling'

  for train_index in xrange(totalBatch):
    feed_dict={
      x: trData[train_index*miniBatch: (train_index+1)*miniBatch],
      y_: trLabel[train_index*miniBatch: (train_index+1)*miniBatch],
      keepProb: o.kProb
      }

    sess.run(train_step,feed_dict)

  if epoch%o.valEpoch==0: # print state of training for validation data
    pred_val = sess.run(y,feed_dict={x: valData, y_:valLabel, keepProb:1.0})
    val_acc = sess.run(accuracy, feed_dict={y: pred_val, y_: valLabel})
    val_ce = sess.run(cross_entropy, feed_dict={y: pred_val, y_: valLabel})
    print 'Training %d epoch : ce = %f, acc = %2.1f%% ' %(epoch,(val_ce/valData.shape[0]),(val_acc*100))

  if epoch%o.saveEpoch==0: # save parameter
    saver.save(sess, save_path, global_step=epoch,write_meta_graph=False)

saver.save(sess, save_path, global_step=epoch,write_meta_graph=False) # last model save
print "### done \n"




