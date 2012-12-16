Tester
======

Description
-----------

Tester unifies output from *python unittest* scripts, and any *generic bash* script, so that both can be processed in a generic way.

For example, this bash script will produce a `..F` output line:

    #!/bin/bash
    true
    true
    false

...as will this script written in python:

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

None of those scripts have anything out of the ordinary, but Tester can run and output same test information for both.

Output format consists of a single line like this:
`status working_dir input_file output_file return_value failed_tests passed_tests total_tests`

For example:
 * All test passed: `PASS /home/foo/scripts foo.sh /tmp/xyzt.tmp 0 0 10 10`
 * Two tests failed: `FAIL /home/foo/scripts bar.sh /tmp/yztx.tmp 127 2 8 10`
 * No tests found (forgot to write them?): `NOOP /home/foo/scripts bar.sh /tmp/yztx.tmp 1 0 0 0`
 * Tests timed out (infinite loop?): `TOUT /home/foo/scripts bar.sh /tmp/yztx.tmp 143`
 * Unable to run any test (incorrect file?): `WHAT /home/foo/scripts bar.sh /tmp/yztx.tmp 127`


### Contributing

Contact info is at the bottom of this document.

### Disclaimer

Tester is in early stages, lacks documentation everywhere, needs refactoring, may set fire to your computer, take your jobs... the usual drill. Just don't blame me for any problem it causes.


Getting started
---------------

### Requisites

 * Python >= 2.6
 * Bash >= 4.0

### Running

Just pass the desired script as parameter to tester.sh, like this:
 * `./tester.sh my_python_test.py`
 * `./tester.sh my_bash_test.sh`

Contact
-------

You can notify me about problems and feature requests at the [issue tracker](https://github.com/stenyak/tester/issues)

Feel free to hack the code and send me GitHub pull requests, or traditional patches too; I'll be more than happy to merge them.

For personal praise and insults, the author Bruno Gonzalez can be reached at [stenyak@stenyak.com](mailto:stenyak@stenyak.com) and `/dev/null` respectively.

License
-------

This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)
