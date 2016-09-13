# script to generate train and test fold files in the format situate uses

import random 
allinds = [x for x in range(1,501)]
inds = [x for x in range(1,401)]
random.shuffle(inds)
inds = ['dog-walking'+str(i)+'.labl' for i in inds]
allinds = ['dog-walking'+str(i)+'.labl' for i in allinds]
testfolds = [inds[:100],inds[100:200],inds[200:300],inds[300:]]
trainfolds = [list(set(allinds) - set(testfolds[x])) for x in range(len(testfolds))]
for ii in range(len(testfolds)):
	names = open('/stash/mm-group/evan/fnames/box_adjust_fnames_split_0'+str(ii+2)+'_test.txt','w') # set save location
	trainnames = open('/stash/mm-group/evan/fnames/box_adjust_fnames_split_0'+str(ii+2)+'_train.txt','w')
	for file in testfolds[ii]:
		print>>names,file
	names.close()
	for file in trainfolds[ii]:
		print>>trainnames,file
	trainnames.close()


