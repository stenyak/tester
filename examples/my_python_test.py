#!/usr/bin/env python
import unittest
class Test(unittest.TestCase):
    def testA(self):
        self.assertTrue(True)
    def testB(self):
        self.assertTrue(True)
    def testC(self):
        self.assertTrue(False)
if __name__ == '__main__':
    unittest.main()
