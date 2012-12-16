Tester
======

Description
-----------

Tester unifies output from *python unittest* scripts, and any *generic bash* script, so that both can be processed in a generic way.
Features:
 - Can handle python unit tests writen with the `unittest` python module, as well as any kind of bash script.
 - Adds *time-out functionality* (i.e. detect bash/python tests that run for too long, stop them, and report the issue).
 - Detects lack of tests (e.g. empty or *incorrectly written* test scripts).
 - Tested on *GNU/Linux* and *OS X*.
 - Short and verbose mode (for easier post-processing).

Sample demonstration:

    $ cat my_bash_test.sh
    #!/bin/bash
    true
    true
    false

    $ cat my_python_test.py
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

None of those scripts have anything out of the ordinary, but Tester can run and output same test information for both:

    $ ./tester.sh my_bash_test.sh
    FAIL /home/foo/tests my_bash_test.sh /tmp/output.jTBO2QzR 1 1 2 3

    $ ./tester.sh my_python_test.py
    FAIL /home/foo/tests my_python_test.py /tmp/output.HaFe9NaJ 1 1 2 3

You can also get more detailed execution information using the `-v` flag:

    $ ./tester.sh my_bash_test.sh -v
    my_bash_test.sh:4: error 1 returned by command: 'false'
    ..F
    FAIL /home/foo/tests my_bash_test.sh /tmp/output.jTBO2QzR 1 1 2 3

    $ ./tester.sh my_python_test.py -v
    ..F
    ======================================================================
    FAIL: testC (__main__.Test)
    ----------------------------------------------------------------------
    Traceback (most recent call last):
      File "my_python_test.py", line 9, in testC
        self.assertTrue(False)
    AssertionError
    ----------------------------------------------------------------------
    Ran 3 tests in 0.000s
    FAILED (failures=1)
    FAIL /home/foo/tests my_python_test.py /tmp/output.HaFe9NaJ 1 1 2 3


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

Use `-v` flag to output all text directly to stdout, instead of only storing it to the output_file. E.g:
 * `./tester.sh -v my_bash_test.sh`

Making sense of the output
--------------------------

Output format consists of a single line with the following space-separated fields:
`status working_dir input_file output_file return_value [ failed_tests passed_tests total_tests ]`

 * Status: can be any of these words:
   * PASS: all tests passed.
   * FAIL: at least one test failed.
   * NOOP: no tests were found.
   * TOUT: tests were taking too long to run.
   * WHAT: error while trying to run the tests.
 * Working_dir: where the script was run.
 * Input_file: unit test file that was run.
 * Output_file: stdout and stderr generated by the test run.
 * Failed/Passed/Total_tests: total is the sum of failed + passed tests.

The last 3 fields (failed, passed and total tests) are only present when status is either PASS, FAIL or NOOP.
The rest of fields are always present.


For example:
 * All ten tests passed: `PASS /home/foo/scripts foo.sh /tmp/xyzt.tmp 0 0 10 10`
 * Only eight tests passed: `FAIL /home/foo/scripts bar.sh /tmp/yztx.tmp 127 2 8 10`
 * There was an infinite loop: `TOUT /home/foo/scripts bar.sh /tmp/yztx.tmp 143`


Contact
-------

You can notify me about problems and feature requests at the [issue tracker](https://github.com/stenyak/tester/issues)

Feel free to hack the code and send me GitHub pull requests, or traditional patches too; I'll be more than happy to merge them.

For personal praise and insults, the author Bruno Gonzalez can be reached at [stenyak@stenyak.com](mailto:stenyak@stenyak.com) and `/dev/null` respectively.

License
-------

This software is released under the GNU GENERAL PUBLIC LICENSE (see gpl-3.0.txt or www.gnu.org/licenses/gpl-3.0.html)
