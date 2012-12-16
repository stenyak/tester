#!/usr/bin/env python
import unittest

class TestFail(unittest.TestCase):
    def testBasic(self):
        self.assertTrue(True)

if __name__ == '__main__':
    unittest.main()
