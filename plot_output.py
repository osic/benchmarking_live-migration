import json
import numpy as np
import matplotlib
#matplotlib.use('Agg')
import matplotlib.pyplot as plt
#matplotlib.pyplot.ioff()
import sys
from operator import sub

flavors = ['small', 'medium', 'large']

def calculate_average_std(filename):
        av = {}
        std = {}
        with open(filename,'rwb') as f:
          data = f.read()

        d = json.loads(data)
        #print d.keys()
        #flavors = d.keys()
	#print d[flavors[0]]['tunneling']
	print flavors
        for i in flavors:
          l = []
          for iter in d[i]['ITERATION'].keys():
            l.extend(d[i]['ITERATION'][iter].values())
          l = map (lambda x : float(x),l)
          av[i] = np.mean(l)
          std[i] = np.std(l)

        av_list = list((av[key] for key in flavors))
        std_list = list((std[key] for key in flavors))
	return (av_list,std_list)

if __name__ == "__main__":
	bresults1 = sys.argv[1]
        bresults2 = sys.argv[2]
	(av_list1,std_list1) = calculate_average_std(bresults1)
	print av_list1
	print std_list1
	double_std_list1 = [x * 2 for x in std_list1]
	bottom_std_list1 = map(sub, av_list1, std_list1)
        (av_list2,std_list2) = calculate_average_std(bresults2)
        print av_list2
        print std_list2
	double_std_list2 = [x * 2 for x in std_list2]
	bottom_std_list2 = map(sub, av_list2, std_list2)
	width = 0.02
	plt.plot(range(len(av_list1)), av_list1,'r', label="average-shared_storage")
	plt.bar(range(len(std_list1)), double_std_list1, width=width, align='center', bottom=bottom_std_list1, alpha=0.9, color='r', label='standard_deviation-shared_storage')
	#plt.plot(range(len(std_list1)), std_list1,'r--', label="standard_deviation-shared_storage")
	plt.plot(range(len(av_list2)), av_list2,'g', label="average-block_storage")
	plt.bar(range(len(std_list2)), double_std_list2, width=width, align='center', bottom=bottom_std_list2, alpha=0.9, color='g', label='standard_deviation-block_storage')
	#plt.plot(range(len(std_list2)), std_list2,'g--', label="standard_deviation-block_storage")
	plt.xticks(range(len(flavors)), flavors)
	plt.xlabel('flavors')
	plt.ylabel('time')
	plt.title('LVM average and std time (tunneling off)')
	plt.legend()
	plt.grid(linestyle='--')
	plt.show()
