#!/usr/bin/env python
import unittest

class TestFail(unittest.TestCase):
    def testBasic(self):
        self.fail("Failed")
    def testBasic2(self):
        self.fail("Failed 2")
    def testBasic3(self):
        self.assertTrue(True)
    def testBasic4(self):
        pass

if __name__ == '__main__':
    unittest.main()
