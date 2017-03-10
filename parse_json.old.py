import json
import re
import sys
#print sys.argv[1]
file =  open(sys.argv[1],"r")
data = {}
tmp_iteration = {}
tmp_downtime = {}
tmp_packetloss = {}
environment = {}
iteration_started = False
iteration_number = 1
reset = False
for line in file:

  # match =  re.search(r"flavor",line)
 #  if match:
#         import pdb;pdb.set_trace();

   #Look for tunneling


   match = re.search((r"number of parallel migrations at once",line)
   if match:
      if reset:
 #        import pdb;pdb.set_trace();
         data["ITERATION"] = tmp_iteration
         data["DOWNTIME"] = tmp_downtime
         data["PACKETLOSS"] = tmp_packetloss
#         print(json.dumps(data, indent=2))
         #print data
         iteration_number = 1
         reset = False
         environment[data["flavor"]] = data
         data = {}
         tmp_iteration = {}
         tmp_downtime = {}
         tmp_packetloss = {}
      result = match.group(1)
      data["tunneling"] = result
      reset = True
      continue


   match = re.search(r"Tunneling:\s(.*)", line)
   if match:
      if reset:
 #        import pdb;pdb.set_trace();
         data["ITERATION"] = tmp_iteration
         data["DOWNTIME"] = tmp_downtime
         data["PACKETLOSS"] = tmp_packetloss
#         print(json.dumps(data, indent=2))
         #print data
         iteration_number = 1
         reset = False
         environment[data["flavor"]] = data
         data = {}
         tmp_iteration = {}
         tmp_downtime = {}
         tmp_packetloss = {}
      result = match.group(1)
      data["tunneling"] = result
      reset = True
      continue

   # Look for flavor type
   match = re.search(r"flavor of workloads used is:\s(.*)", line)
   if match:
      result = match.group(1)
      data["flavor"] = result
      continue

   # Look for the iteration
   match = re.search(r"starting lvm at:\s(.*)", line)
   if match:
      tmp_vm={}
    #  tmp_iteration={}
      data["ITERATION"] = tmp_iteration
      iteration_started = True
      continue

   # Look for VM Downtime
   match = re.search(r"downtime for instance with ip\s(.*)", line)
   if match:
      result = match.group(1)
      key,value = result.split(":")
      key = key.strip()
      value = value.strip()
      tmp_downtime[key] = value
      continue

   # Look for packet loss
   match = re.search(r"TCP\s(.*)", line)
   if match:
      ip_candidates = re.findall(r"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b", line)
      tmp_packetloss[ip_candidates[0]] = line
      continue

   # Look for the VMs info for each iteration
   if iteration_started == True:
      match = re.search(r"live migration duration for\s(.*)", line)
      if match:
         result = match.group(1)
         key,value = result.replace(" ", "").split(":")
         tmp_vm[key] = value
#         tmp_vm ={}
#         break
         continue
      match = re.search(r"live migration duration:\s(.*)", line)
      if match:
         result = match.group(1)
         #tmp_vm["duration"] = result
#         import pdb;pdb.set_trace();
         tmp_iteration[iteration_number] = tmp_vm
         iteration_number = iteration_number + 1
         iteration_started = False
         continue
data["ITERATION"] = tmp_iteration
data["DOWNTIME"] = tmp_downtime
data["PACKETLOSS"] = tmp_packetloss
#import pdb ; pdb.set_trace();
environment[data["flavor"]] = data
print(json.dumps(environment, indent=2))
#print data
#print tmp_vm
#print tmp_iteration
