import unittest
import sys
import os
import run as main
import mock
import argparse
import asset.resource_deployment


namespace = {

    'name': 'name',
    'action': 'create',
    'server_no': '2',
    'server_threads': '4',
    'memory': '4096',
    'object_size': '550',
    'client_threats': '4',
    'interval': '1',
                'server_memory': '4096',
                'scaling_factor': '2',
                'duration': '0',
                'fraction': '0.8',
                'connection': '220'
}
main.DataCaching.server_no = namespace['server_no']
main.DataCaching.memory = namespace['memory']
main.DataCaching.object_size = namespace['object_size']
main.DataCaching.client_threats = namespace['client_threats']
main.DataCaching.interval = namespace['interval']
main.DataCaching.server_memory = namespace['server_memory']
main.DataCaching.scaling_factor = namespace['scaling_factor']
main.DataCaching.duration = namespace['duration']
main.DataCaching.fraction = namespace['fraction']
main.DataCaching.connection = namespace['connection']


class CloudSuiteTest(unittest.TestCase):

    @mock.patch('argparse.ArgumentParser.parse_args', return_value=argparse.Namespace(**namespace))
    @mock.patch('asset.resource_deployment.HeatStack.delete')
    @mock.patch('asset.resource_deployment.HeatStack.create')
    @mock.patch('run.DataCaching.ssh_to')
    def test_deploy_benchmark(self, ssh_to, create, delete, args):
        actions = {'create', 'delete'}
        if not args.return_value.action in actions:
            raise(TypeError)
        with mock.patch.object(sys, 'argv', args):
            environ_mock = {
                'OS_AUTH_URL': 'OS_AUTH_URL',
                'OS_USERNAME': 'OS_USERNAME',
                'OS_PASSWORD': 'OS_PASSWORD',
                'OS_TENANT_NAME': 'OS_TENANT_NAME',
                'OS_PROJECT_NAME': 'OS_PROJECT_NAME',
            }
            with mock.patch.dict(os.environ, environ_mock):
                main.DataCaching().deploy_benchmark(
                    args.return_value.name, args.return_value.action)

    def test_metadata(self):
        main.DataCaching().metadata()

    @mock.patch('run.DataCaching.ssh_to')
    def test_ssh_to(self, ssh_to):
        main.DataCaching().ssh_to()
