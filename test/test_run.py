import unittest
import sys
import os
import run as main
import mock
import argparse
import asset.resource_deployment


inputArgs = {

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
main.DataCaching.server_no = inputArgs['server_no']
main.DataCaching.memory = inputArgs['memory']
main.DataCaching.object_size = inputArgs['object_size']
main.DataCaching.client_threats = inputArgs['client_threats']
main.DataCaching.interval = inputArgs['interval']
main.DataCaching.server_memory = inputArgs['server_memory']
main.DataCaching.scaling_factor = inputArgs['scaling_factor']
main.DataCaching.duration = inputArgs['duration']
main.DataCaching.fraction = inputArgs['fraction']
main.DataCaching.connection = inputArgs['connection']


class CloudSuiteTest(unittest.TestCase):

    @mock.patch('argparse.ArgumentParser.parse_args', return_value=argparse.Namespace(**inputArgs))
    @mock.patch('asset.resource_deployment.HeatStack.delete')
    @mock.patch('asset.resource_deployment.HeatStack.create')
    @mock.patch('run.DataCaching.ssh_to')
    def test_deploy_benchmark(self, ssh_to, create, delete, args):
        actions = {'create', 'delete'}
        self.assertEqual(args.return_value.action, "create")
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
