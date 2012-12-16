#!/usr/bin/env python
import unittest

class TestFail(unittest.TestCase):
    def testBasic(self):
        import time
        time.sleep(2)

if __name__ == '__main__':
    unittest.main()
