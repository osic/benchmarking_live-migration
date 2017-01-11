#!/usr/bin/env python
import os, sys
 
def get_keystone_creds():
	try:
		d = {}
		d['project_domain_name'] = os.environ['OS_PROJECT_DOMAIN_NAME']
		d['user_domain_name'] = os.environ['OS_USER_DOMAIN_NAME']
		d['project_name'] = os.environ['OS_PROJECT_NAME']
		#    d['tenant_name'] = os.environ['OS_TENANT_NAME']
		d['username'] = os.environ['OS_USERNAME']
		d['password'] = os.environ['OS_PASSWORD']
		d['auth_url'] = os.environ['OS_AUTH_URL']
		#    d['os_identity_api_version'] = os.environ['OS_IDENTITY_API_VERSION']
		return d
	except KeyError as k:
		print "some creds were missing please source your openrc file"
		sys.exit(0)

