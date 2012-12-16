#!python_tester.sh
import unittest

class TestFail(unittest.TestCase):
    def testBasic(self):
        self.assertTrue(True)

if __name__ == '__main__':
    unittest.main()
