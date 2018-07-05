#!/bin/bash

cnn/train_spec_cnn3.sh


#cnn/test_spec_cnn2.sh


: << 'RESULTS'
## 2018.06.15 schedule ##
# melcnn1 - train / test 
Total number : 71067
Accuracy : 63.19
pred\refs :	noise	speech	music	mixed	mu_no	sil
noise		5552	1558	1020	260	1170	941
speech		300	5174	64	1002	102	65
music		1681	292	18449	1573	2466	61
mixed		403	2471	774	8088	1057	4
mu_no		1547	323	4148	1343	5535	2
sil		1000	427	104	4	0	2107
==========================
F1 score : 0.89
Accuracy : 0.85
Recall : 0.92
Precision : 0.86
pred\refs :	music	others
music		43433	6784
others		3726	17124


# melspec - train / test 
Total number : 71067
Accuracy : 67.36
pred\refs :	noise	speech	music	mixed	mu_no	sil
noise		5279	696	295	102	835	943
speech		768	7059	83	1986	232	103
music		1746	181	20350	1485	3174	121
mixed		272	1846	936	8003	917	3
mu_no		1657	131	2804	693	5172	2
sil		761	332	91	1	0	2008
==========================
F1 score : 0.90
Accuracy : 0.87
Recall : 0.92
Precision : 0.88
pred\refs :	music	others
music		43534	5959
others		3625	17949

# spec - train / test 
Total number : 71067
Accuracy : 66.36
pred\refs :	noise	speech	music	mixed	mu_no	sil
noise		4547	1076	566	274	904	710
speech		676	6416	61	1446	188	161
music		1484	191	20533	1709	2788	91
mixed		231	1940	495	7848	847	4
mu_no		2232	179	2700	989	5603	1
sil		1313	443	204	4	0	2213
==========================
F1 score : 0.90
Accuracy : 0.86
Recall : 0.92
Precision : 0.87
pred\refs :	music	others
music		43512	6353
others		3647	17555


# melcnn kernel ouput
# melcnn3 - train / test
# melcnn5 - train / test
# melcnn7 - train / test
# write paper

# common DB exp (22050Hz)
# create mixing data with vad
# drama_mask decoding 22050Hz
# best feat train / test (125/50)
# best feat train / test (25 or ?? /10)
# BLSTM exp
# chroma normalizing exp
# chromacnn - train / test
# melcnn + chromacnn - train / test
# event level evaluation
RESULTS
