import unittest
import sys
import os
import run
import mock
import argparse
import asset.resource_deployment


namespace={

		'name': 'name',
		'action': 'create',
		'server_no': '2',
		'server_threads': '4',
		'memory': '4096',
		'object_size': '550',
		'client_threats':'4',
		'interval': '1',
		'server_memory': '4096',
		'scaling_factor': '2',
		'duration': '0',
		'fraction': '0.8',
		'connection': '220'
    }

class CloudSuiteTest(unittest.TestCase):

	@mock.patch('argparse.ArgumentParser.parse_args',return_value=argparse.Namespace(**namespace))
	@mock.patch('asset.resource_deployment.HeatStack.delete')
	@mock.patch('asset.resource_deployment.HeatStack.create')
	@mock.patch('run.ssh_to')
	def test_deploy_benchmark(self,ssh,create,delete,args):
		actions={'create','delete'}
		if not args.return_value.action in actions :
			raise(TypeError)
		with mock.patch.object(sys, 'argv',args):
		    environ_mock = {
				'OS_AUTH_URL': 'OS_AUTH_URL',
				'OS_USERNAME': 'OS_USERNAME',
				'OS_PASSWORD': 'OS_PASSWORD',
				'OS_TENANT_NAME' :'OS_TENANT_NAME',
				'OS_PROJECT_NAME':'OS_PROJECT_NAME',
		    }
		    with mock.patch.dict(os.environ, environ_mock):
		    	run.deploy_benchmark(args.return_value)
