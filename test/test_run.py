import unittest
import sys
import os
import run
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
run.DataCaching.server_no = inputArgs['server_no']
run.DataCaching.memory = inputArgs['memory']
run.DataCaching.object_size = inputArgs['object_size']
run.DataCaching.client_threats = inputArgs['client_threats']
run.DataCaching.interval = inputArgs['interval']
run.DataCaching.server_memory = inputArgs['server_memory']
run.DataCaching.scaling_factor = inputArgs['scaling_factor']
run.DataCaching.duration = inputArgs['duration']
run.DataCaching.fraction = inputArgs['fraction']
run.DataCaching.connection = inputArgs['connection']


class CloudSuiteTest(unittest.TestCase):

    @mock.patch('argparse.ArgumentParser.parse_args', return_value=argparse.Namespace(**inputArgs))
    @mock.patch('asset.resource_deployment.HeatStack.delete')
    @mock.patch('asset.resource_deployment.HeatStack.create')
    @mock.patch('run.DataCaching.metadata')
    @mock.patch('run.DataCaching.ssh_to')
    def test_deploy_benchmark(self, ssh_to, metadata, create, delete, args):
        actions = {'create', 'delete'}
        self.assertIn(args.return_value.action, {"create", "delete"})
        with mock.patch.object(sys, 'argv', args):
            environ_mock = {
                'OS_AUTH_URL': 'OS_AUTH_URL',
                'OS_USERNAME': 'OS_USERNAME',
                'OS_PASSWORD': 'OS_PASSWORD',
                'OS_TENANT_NAME': 'OS_TENANT_NAME',
                'OS_PROJECT_NAME': 'OS_PROJECT_NAME',
            }
            with mock.patch.dict(os.environ, environ_mock):
                run.DataCaching().deploy_benchmark(
                    args.return_value.name, args.return_value.action)
                self.assertTrue(metadata.called)
                self.assertTrue(create.called or delete.called)
                self.assertTrue(ssh_to.called)

    def test_metadata(self):
        run.DataCaching().metadata()

    @mock.patch('run.DataCaching.ssh_to')
    def test_ssh_to(self, ssh_to):
        root_path = os.getcwd()
        config_path = root_path + "/asset/"
        run.DataCaching().ssh_to(config_path, '1.1.1.1')
        self.assertTrue(ssh_to.called)
