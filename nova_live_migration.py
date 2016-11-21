# Copyright 2016: Intel Corporation.
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import jsonschema
import random
import json
from rally.common import logging
from rally import consts
from rally import exceptions as rally_exceptions
from rally.plugins.openstack import scenario
from rally.plugins.openstack.scenarios.cinder import utils as cinder_utils
from rally.plugins.openstack.scenarios.nova import utils
from rally.plugins.openstack.wrappers import network as network_wrapper
from rally.task import types
from rally.task import utils as task_utils
from rally.task import validation
from rally.task import atomic
import sys

class NovaLiveMigrations(utils.NovaScenario):
    """Plugin for Live Migration specific scenarios"""

    def _get_servers_from_compute(self, host_to_evacuate):
        """ Returns servers of a specific compute node """
#        import pdb; pdb.set_trace()
        servers = self._list_servers()
        servers_to_migrate = []
        for server in servers:
                if server.to_dict()['OS-EXT-SRV-ATTR:host'] == host_to_evacuate:
                        servers_to_migrate.append(server)
        return servers_to_migrate



    @types.convert(image={"type": "glance_image"},
                   flavor={"type": "nova_flavor"})
    @validation.image_valid_on_flavor("flavor", "image")
    @validation.required_services(consts.Service.NOVA)
    @validation.required_openstack(admin=True, users=True)
    @scenario.configure()
    @atomic.action_timer("live_migrate_servers_from_host")
    def live_migrate_servers_from_host(self, image, host_to_evacuate,
                                     flavor, block_migration=False, destination_host=None,
                                     disk_over_commit=False, **kwargs):
        """Live Migrate servers.
        This scenario migrates all the VM in the specified compute host to another
        compute node on the same availability zone.
        :param image: image to be used to boot an instance
        :param flavor: flavor to be used to boot an instance
        :param block_migration: Specifies the migration type
                                 on migrated instance or not
        """
        servers_to_migrate = self._get_servers_from_compute(host_to_evacuate)
        print "migrating servers: " + str(servers_to_migrate)
        for server in servers_to_migrate:
                if destination_host != 'nova':
                        new_host = destination_host
                else:
                        new_host = self._find_host_to_migrate(server)
                self._live_migrate(server, new_host,
                                  block_migration, disk_over_commit)
