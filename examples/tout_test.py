#!/usr/bin/env python
# tester_timeout_ms = 100 #
import unittest

class TestFail(unittest.TestCase):
    def testBasic(self):
        import time
        time.sleep(0.5)

if __name__ == '__main__':
    unittest.main()
