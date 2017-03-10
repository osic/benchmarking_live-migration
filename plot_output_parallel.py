import json
import numpy as np
import matplotlib
#matplotlib.use('Agg')
import matplotlib.pyplot as plt
#matplotlib.pyplot.ioff()
import sys
from operator import sub
from operator import add

flavors = ['medium']
parallel_vms = ['parallel_1','parallel_2','parallel_3','parallel_4']
parallel_vmss = ['1','2','3','4']
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
          for p in parallel_vms: 
           l = []
           for iter in d[i][p]['ITERATION'].keys():
             l.extend(d[i][p]['ITERATION'][iter].values())
           l = map (lambda x : float(x),l)
           av[p] = np.mean(l)
           std[p] = np.std(l)

        av_list = list((av[key] for key in parallel_vms))
        std_list = list((std[key] for key in parallel_vms))
	return (av_list,std_list)

if __name__ == "__main__":
	bresults1 = sys.argv[1]
	(av_list1,std_list1) = calculate_average_std(bresults1)
	print av_list1
	print std_list1
	double_std_list1 = [x * 2 for x in std_list1]
	bottom_std_list1 = map(sub, av_list1, std_list1)
	upper_std_list1 = map(add, av_list1, std_list1)
	plt.plot(range(len(av_list1)), av_list1,'r', label="average non-block storage duration")
	#plt.bar(range(len(std_list1)), double_std_list1, width=width, align='center', bottom=bottom_std_list1, alpha=0.9, color='r', label='standard_deviation-shared_storage')
        plt.plot(range(len(bottom_std_list1)), bottom_std_list1, 'r--', label='min/max non-block storage duration')
        plt.plot(range(len(bottom_std_list1)), upper_std_list1, 'r--')
	#plt.plot(range(len(std_list1)), std_list1,'r--', label="standard_deviation-shared_storage")
	plt.xticks(range(len(parallel_vms)), parallel_vmss)
	plt.xlabel('number of parallel VMs migration at once')
	plt.ylabel('time (seconds)')
	plt.title('live migration duration (tunneling off)')
	plt.legend()
	plt.grid(linestyle='--')
	plt.show()

