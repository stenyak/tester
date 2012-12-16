#!python_tester.sh
import unittest

class TestFail(unittest.TestCase):
    def testBasic(self):
        import time
        time.sleep(10)

if __name__ == '__main__':
    unittest.main()
