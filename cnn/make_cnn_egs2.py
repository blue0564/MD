"""
    Copyright 2018.4. Byeong-Yong Jang
    byjang@cbnu.ac.kr
    This code is for creating CNN input.
    Extract spectrogram and detect voice activity.
    If do you want check result and log, then change the log_level to 3.

    Usage
    -----
    python make_cnn_egs.py --sample-frequency=16000 --frame-length=25 \
                           --frame-shift=10 --fft-size=512 \
                           --vad-agressive=3 --vad-frame-size=10 \
                           --vad-medfilter-size=5 --target-label=speech
                           test.wav  test.bin

    Input
    -----
    wav-file : path of wave file
    out-file : path of output file (pickle format)
               out_data = (spec_data, vad_data, label)


    Options
    -------
    --sample-frequency (int) : sample rate of wav (Hz) [default: 16000]
    --frame-length (int) : frame size (ms) [default: 25 ms]
    --frame-shift (int) : frame shift size (ms) [default: 10 ms]
    --fft-size (int) : FFT window size (sample) [default: frame_size*sample_frequency]

    --vad-aggressive (int) : aggressive number for VAD (0~3 / least ~ most) [default: 3]
    --vad-frame-size (int) : frame size (only 10 or 20 or 30 ms) for VAD [default: 10]
    --vad-medfilter-size (int) : median filter size for VAD [default: 5 frame]

    --target-label (string) : target label [default: None]

"""

import os
import sys
from optparse import OptionParser

import matplotlib.pyplot as plt
import numpy as np
from numpy import matlib

sys.path.append(os.path.dirname(os.path.abspath(os.path.dirname(__file__))))
from deeputils.deepio import array_io
from deeputils.vad import vadwav
from deeputils.feature import extract_spec


### hyper parameters ###
log_level = 0
# 0 : default. do not print log message
# 1 : print log message, but do not plot results
# 2 : plot results

fignum = 1
### end of hyper parameter ###


def spec_zm(spec_data):
    ntime = spec_data.shape[1]
    mean_data = np.matlib.repmat(np.mean(spec_data,axis=1),ntime,1)
    zm_data = spec_data - np.transpose(mean_data)
    return zm_data


def main():

    usage = "%prog [options] <wav-file> <spec-file> <pos-file>"
    parser = OptionParser(usage)

    # parser.add_option('--spec-type', dest='spec_type', help='spectrogram type  [default: scispec ]',
    #                   default='scispec', type='string')
    parser.add_option('--sample-frequency', dest='sample_rate', help='sample rate of wav  [default: 16kHz ]',
                      default=16000, type='int')
    parser.add_option('--frame-length', dest='frame_size', help='frame size (ms)  [default: 25ms ]',
                      default=25, type='int')
    parser.add_option('--frame-shift', dest='frame_shift', help='frame shift size (ms)  [default: 10ms ]',
                      default=10, type='int')
    parser.add_option('--fft-size', dest='fft_size', help='fft size [default: frame size ]',
                      default=-1, type='int')

    parser.add_option('--vad-aggressive', dest='vad_agg', help='aggressive number for VAD (0~3 / least ~ most) [default: 3 ]',
                      default=3, type='int')
    parser.add_option('--vad-frame-size', dest='vad_frame_size',
                      help='frame size (10, 20, 30 ms) for VAD [default: 10ms ]',
                      default=10, type='int')
    parser.add_option('--vad-min-sil-frames', dest='vad_min_sil_frames',
                      help='minimum length of silence for VAD [default: 50 frames]',
                      default=50, type='int')

    parser.add_option('--splice-size', dest='splice_size', help='splice size [default: 5 frames ]',
                      default=5, type='int')
    parser.add_option('--spec-stride', dest='spec_stride', help='spectrogram stride [default: 5 frames ]',
                      default=5, type='int')

    parser.add_option('--target-label', dest='target_label', help='target label  [default: None ]',
                      default='None', type='string')

    (o, args) = parser.parse_args()
    (wav_path, spec_file, pos_file) = args

    sr_ = o.sample_rate
    frame_size_ = np.int(o.frame_size * sr_ * 0.001)
    frame_shift_ = np.int(o.frame_shift * sr_ * 0.001)
    vad_aggressive = o.vad_agg # 0 ~ 3 (least ~ most agrressive)
    vad_frame_size = o.vad_frame_size # only 10 or 20 or 30 (ms)
    vad_min_sil_len = o.vad_min_sil_frames
    splice_size = o.splice_size
    spec_stride = o.spec_stride
    target_label = o.target_label # speech / music / noise
    global fignum

    if o.fft_size == -1:
        fft_size_ = frame_size_
    else:
        fft_size_ = o.fft_size

    # segment_time is center of each frame / spec_data = [frequncy x time]
    if log_level > 0:
        print 'LOG: extract spectrogram data'
    sample_freq, segment_time, spec_data = extract_spec.log_spec_scipy(wav_path, sr_, frame_size_, frame_shift_, fft_size_)
    if log_level > 1:
        fig = plt.figure(fignum)
        fignum += 1
        fig.suptitle('Spectrogram')
        if spec_data.shape[1] > 500:
            endi = 500
        else:
            endi = spec_data.shape[1]

        plt.pcolormesh(segment_time[0:endi],sample_freq,spec_data[:,0:endi])
        plt.ylabel('Frequency [Hz]')
        plt.xlabel('Time [sec]')

    # normalize zero mean
    spec_data_zm = spec_zm(spec_data)
    if log_level > 1:
        fig = plt.figure(fignum)
        fignum += 1
        fig.suptitle('Spectrogram with zero mean')
        if spec_data.shape[1] > 500:
            endi = 500
        else:
            endi = spec_data.shape[1]

        plt.pcolormesh(segment_time[0:endi],sample_freq,spec_data_zm[:,0:endi])
        plt.ylabel('Frequency [Hz]')
        plt.xlabel('Time [sec]')

    # Padding copy to first and last frame ( if splice_size is 2, then [1,2,3] -> [1,1,1,2,3,3,3] )
    if log_level > 0:
        print 'LOG: padding spectrogram data for splicing with edge-mode'
    spec_data_zm_pad = np.pad(spec_data_zm,((0,0),(splice_size,splice_size)),'edge')

    # Voice activity detector using 'webrtcvad'
    if log_level > 0:
        print 'LOG: processing vad'
    vad_index, wav_data = vadwav.decision_vad_index(wav_path, vad_aggressive, vad_frame_size, vad_min_sil_len)

    if log_level > 1:
        fig = plt.figure(fignum)
        fignum += 1
        # convert to range : -32768 ~ 32767 -> -1 ~ 1
        wav_data = np.array(wav_data) / float(2 ** 15 - 1)
        check_time = 30 # sec
        if len(wav_data) > check_time*sr_:
            endi = check_time*sr_
        else:
            endi = len(wav_data)
        t = np.array(range(0,endi))/float(sr_)
        fig.suptitle('Check VAD result')
        plt.plot(t,wav_data[0:endi])
        plt.hold(True)
        plt.plot(t,vad_index[0:endi],'r')
        plt.hold(False)
        plt.axis([t[0],t[-1],-1,1.2])
        plt.xlabel('sec')
        plt.legend(['wav','vad'], loc=4)

    # make spec data file and pos file
    if log_level > 0:
        print 'LOG: match between spec_data and vad_index'
    vad_data = np.zeros(spec_data.shape[1])
    for i in range(len(segment_time)):
        center_sample = int(segment_time[i] * sr_)
        begi = center_sample-int(frame_size_/2)
        endi = center_sample+int(frame_size_/2)
        vadi = vad_index[begi:endi]
        vad_data[i] = (1 if vadwav.is_voice_frame(vadi) else 0)

    vad_data_pad = np.pad(vad_data,(splice_size,splice_size),'edge')

    if log_level > 1:
        fig = plt.figure(fignum)
        fignum += 1
        vad_data_pad_sc = vad_data_pad*(spec_data_zm_pad.shape[0]/2)

        if spec_data.shape[1] > 10000:
            endi = 10000
        else:
            endi = spec_data_zm_pad.shape[1]

        plt.pcolormesh(spec_data_zm_pad[:,0:endi])
        plt.ylabel('Frequency [Hz]')
        plt.xlabel('Time [sec]')
        plt.hold(True)
        plt.title("Check spec and vad")
        plt.plot(vad_data_pad_sc[0:endi])
        plt.hold(False)


    if log_level > 0:
        print 'LOG: output spec file and pos file'

    begi = 0
    endi = begi + splice_size*2 + 1
    while endi < vad_data_pad.shape[0]:
        speci = spec_data_zm_pad[:,begi:endi]
        posi = array_io.save_append_array(spec_file,speci)
        centeri = begi + splice_size
        labeli = (target_label if (vad_data_pad[centeri] == 1) else 'sil')

        with open(pos_file,'a') as f:
            f.write("%i %s\n"%(posi,labeli))

        begi += spec_stride
        endi = begi + splice_size*2 + 1

    if log_level > 1:
        plt.show()

if __name__=="__main__":
    main()
