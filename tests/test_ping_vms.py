from credentials import get_keystone_creds
from novaclient import client
from keystoneclient import session
from keystoneclient.auth import identity
import subprocess
import threading
import time
import re
import sys
import os
import socket

interval = 0.5

def downtime_info(downtime_servers, filename):
  info = ''
  for dt in downtime_servers.items():
    info += 'downtime for instance with ip ' + dt[0] + ' : ' + str (dt[1]) + ' seconds \n'
  with open(filename,'wb+') as f:
    f.write(info)
  return info

def test_ping(servers, filename):
    downtime_servers = {}
    for server in servers.items():
      downtime_servers[server[0]] = 0
    print downtime_info(downtime_servers, filename)
    #print 'downtime for instance with ip ' + server[0] + ' : ' + str (downtime_servers[server[0]])
    while True:
      for server in servers.items():
        args = ["ping", "-c", "1", "-l", "1", "-s", "1", "-W", "1", server[0]]
        ping = subprocess.Popen(
            args, stdout = subprocess.PIPE, stderr = subprocess.PIPE
        )
        out, error = ping.communicate()
        res = re.findall(r'\d+%', out)
        if res[0] != '0%':
          downtime_servers[server[0]] += interval
      print downtime_info(downtime_servers, filename)
      print '---------------'
      time.sleep(interval)
    

def test_packetloss_all(servers, lvm_results_filename):
    jobs = []
    for server in servers.items():
       ip = server[0]
       test_packetloss(ip, lvm_results_filename)

def test_packetloss(ip, lvm_results_filename):
    os.system("./test_packetloss.sh " + ip + " " + lvm_results_filename + " " + str(interval))

def send_to_all(servers):
    for server in servers.items():
      try:
        ip = server[0]
        print "Sending packets to " + ip
        t = threading.Thread(target=send_packets, args=(ip,))
        t.start()
        print 'thread started'
      except (KeyboardInterrupt, SystemExit):
        t.kill()
        sys.exit()

def send_packets(ip):
      while True:
         try:
            s = socket.socket( socket.AF_INET, socket.SOCK_STREAM )
            s.connect( ( ip, 2392 ) )
            counter=0
            break
         except:
            continue 
      while True:
         print "Sending "+str(counter) +" to ip " +ip
         s.send(str(counter) + "\n")
         time.sleep( interval )
         counter=counter + 1

def start_tests(servers, filename):
    send_to_all(servers)
    test_ping(servers, filename)

def get_servers(host):
  creds = get_keystone_creds()
  auth = identity.v3.Password(**creds)
  sess = session.Session(auth=auth)
  nova = client.Client('2',session=sess)
  servers = {}
  for server in nova.servers.list():
    try:
      if server.to_dict()['OS-EXT-SRV-ATTR:host'] == host:
        # NOTE: network name should not be statically assigned
        servers[server.to_dict()['addresses']['external-flat'][0]['addr']] = server.name
    except Exception as e:
      print 'problem with getting info for server: ' + str(server.to_dict()['id'])
      print str(e)
      pass
  return servers

if __name__ == '__main__':
  host = sys.argv[1]
  tmp_filename = sys.argv[2]
  lvm_results_filename = sys.argv[3]
  action = sys.argv[4]

  servers = get_servers(host)

  if action == 'test_packet_loss':
    test_packetloss_all(servers, lvm_results_filename)
  elif action == 'start_tests':
    start_tests(servers, tmp_filename)
  elif action == 'get_servers':
    print get_servers(host)
