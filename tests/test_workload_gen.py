import unittest
import mock
from csdc.workload_gen import DataCaching

class WorkloadGenTest(unittest.TestCase):

	def setUp(self):
		self.benchmark = DataCaching(mock.Mock())


	def test_get_current_time(self):
		self.benchmark.get_current_time()