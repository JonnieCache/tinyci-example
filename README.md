     _____ _               _____  _____
    /__   (_)_ __  _   _  / ___/ /_  _/
       | || | '_ \| | | |/ /     / /
       | || | | | | |_| / /___/\/ /_  
       |_||_|_| |_|\__, \____/\____/
                   |___/

TinyCI Example Project
=======================

This is an example project for [TinyCI](https://github.com/JonnieCache/tinyci), a minimal Continuous Integration system, written in ruby, powered by git.

Various features are demonstrated:

### Hooks

Let us quote the order of execution from the [TinyCI README:](https://github.com/JonnieCache/tinyci)

```
  * clean
  * export

  before_build
  
  * build
  
  after_build_success
  after_build_failure
  after_build
  
  before_test
  
  * test
  
  after_test_success
  after_test_failure
  after_test
  
  after_all
```

Only the `build` and `test` stages, and the `after_build_success` and `after_test_success` hooks are implemented in this example.

* The build stage, `build.sh` simply echoes some text to a file, `baz.txt`.
* The `after_build_success.sh` hook echoes some more text to the same file.
* The test stage, defined in `test.sh` greps for the presence of both pieces of text.
* `after_test_success.sh` is a little more complex. It makes a symlink named `tinyci-example_production` in the parent directory of the repo, pointing to the exported commit that has just been successfully build and tested.

This is meant to demonstrate a potential strategy for automated continuous deployment: the symlink could represent the root directory of a web application server. With a line added to the `after_test_success` script to reload your server processes, your application will be automatically updated whenever a build passes testing. This setup will be familiar to anyone who has used capistrano, fabric or similar deployment scripting systems.

### Compactor

With continued use, the `builds` directory will grow ever larger. TinyCI provides the `compact` command to deal with this. It compresses old builds into `.tar.gz` files.

"old" in this context is defined using two options to the `tinyci compact` command:

* `--num-builds-to-leave` - How many build directories to leave in place, starting from the newest. Defaults to `1`.
* `--builds-to-leave` - A comma-separated list of specific build directories to leave in place.

The latter option is intended for use in an automated deployment system as described above in the hooks section, to allow the script to run without removing builds that are being used somewhere else in the system.

This will be shown in action below:

### Demonstration

First, create a directory to store both clones:

    $ mkdir tinyci-test
    $ cd tinyci-test

Clone the example project from github:

    $ git clone https://github.com/JonnieCache/tinyci-example.git
    
    Cloning into 'tinyci-example'...
    remote: Counting objects: 8, done.
    remote: Compressing objects: 100% (6/6), done.
    remote: Total 8 (delta 0), reused 8 (delta 0), pack-reused 0
    Unpacking objects: 100% (8/8), done.
    
Clone it again into a bare repository:

    $ git clone --bare tinyci-example tinyci-example-bare
    
    Cloning into bare repository 'tinyci-example-bare'...
    done.
    
Install tinyci:

    $ gem install tinyci
    
Install the tinyci hook into our bare clone:

    $ cd tinyci-example-bare
    $ tinyci install
    
    [09:48:42] tinyci post-update hook installed sucessfully
    
Go into our initial clone and make a change:

    $ cd ../tinyci-example
    $ echo "foo" > bar
    $ git add bar
    $ git commit -m 'foobar'
    
    [master cebb4ec] foobar
     1 file changed, 1 insertion(+)
     create mode 100644 bar
    
Add our bare repo as a remote:

    $ git remote add test ../tinyci-example-bare
    
Push the commit and watch tinyci in action:

    $ git push test master
    
    Enumerating objects: 4, done.
    Counting objects: 100% (4/4), done.
    Delta compression using up to 4 threads
    Compressing objects: 100% (2/2), done.
    Writing objects: 100% (3/3), 259 bytes | 259.00 KiB/s, done.
    Total 3 (delta 1), reused 0 (delta 0)
    remote: [12:56:39] Commit: f40785cbc4422f39c36118fbae071932774cb5b6
    remote: [12:56:39] Cleaning...
    remote: [12:56:39] Exporting...
    remote: [12:56:39] Building...
    remote: [12:56:39] build!
    remote: [12:56:39] executing after_build_success hook...
    remote: [12:56:39] after_build_success!
    remote: [12:56:39] Testing...
    remote: [12:56:39] test!
    remote: [12:56:39] foo bar
    remote: [12:56:39] abc
    remote: [12:56:39] executing after_test_success hook...
    remote: [12:56:39] updating symlink...
    remote: [12:56:39] Finished f40785cbc4422f39c36118fbae071932774cb5b6
    remote: [12:56:39] Commit: 343faed784ae86689e595c44747a2f3d8ae1117c
    remote: [12:56:39] Cleaning...
    remote: [12:56:39] Exporting...
    remote: [12:56:39] Building...
    remote: [12:56:39] build!
    remote: [12:56:39] executing after_build_success hook...
    remote: [12:56:39] after_build_success!
    remote: [12:56:39] Testing...
    remote: [12:56:39] test!
    remote: [12:56:39] test: `/bin/sh -c './test.sh'` failed with status 1
    remote: [12:56:39] Commit: <NEW COMMIT>
    remote: [12:56:39] Cleaning...
    remote: [12:56:39] Exporting...
    remote: [12:56:39] Building...
    remote: [12:56:39] build!
    remote: [12:56:39] executing after_build_success hook...
    remote: [12:56:39] after_build_success!
    remote: [12:56:39] Testing...
    remote: [12:56:39] test!
    remote: [12:56:39] test: `/bin/sh -c './test.sh'` failed with status 1
    To ../tinyci-example-bare
       343faed..<NEW>  master -> master
    
Let's break down whats happening here:

There are three commits in this repo, plus the one which we just added. All have the same basic content mentioned above, but they are modified such that the `test` stage passes or fails.

The first commit `f40785cbc4422f39c36118fbae071932774cb5b6` is exactly as described above, and therefore passes. As such, the `after_test_success` hook is executed, and a symlink named `tinyci-example_production` is created as a sibling of the current directory, pointing to the successfully built and tested export:


    $ ls -la ../tinyci-example_production
    
    projects/tinyci-example/builds/1539792869_f40785cbc4422f39c36118fbae071932774cb5b6/export

The second commit, `279c8713d16f67f764fbf616fbab727672e23b0a` fails its test stage, due to an `exit 1` inserted into `test.sh`.

The last commit, (the one we just made,) also fails.

Now, lets try out the `compact` command:

    $ cd ../tinyci-example-bare
    $ tinyci compact --builds_to_leave=$(readlink -f ../tinyci-example_production)
    
(MacOS users should leave the the `-f` switch out of this command, due to differences with BSD coreutils.)

We should see the following output:

    [15:09:56] Compacted /Users/jonnie/projects/tinyci-example/builds/<THIS COMMIT>.tar.gz
    
Only one of our builds has been compressed. Let's look at the contents of our `builds` directory:

    $ ls -lah builds
    
    total 8
    drwxr-xr-x   5 jonnie  staff   160B 18 Oct 15:45 .
    drwxr-xr-x  13 jonnie  staff   416B 18 Oct 15:46 ..
    drwxr-xr-x   4 jonnie  staff   128B 18 Oct 15:45 1539792869_f40785cbc4422f39c36118fbae071932774cb5b6
    -rw-r--r--   1 jonnie  staff   1.7K 18 Oct 15:45 <THIS COMMIT>.tar.gz
    drwxr-xr-x   4 jonnie  staff   128B 18 Oct 15:45 <NEW COMMIT>
    
The first build, `1539792869_f40785cbc4422f39c36118fbae071932774cb5b6` has been left in place due to the `--builds_to_leave` option we passed to `tinyci compact`. We used `readlink` to get the absolute path of our `tinyci-example_production` symlink and passed this into `builds-to-leave`. This ensures our deployed instance remains untouched.
    
The most recent build, `<NEW COMMIT>` has been left in place due to the `--num-builds-to-leave` option, which while not passed directly here, defaults to 1.

Therefore, only the middle build, `<THIS COMMIT>`, was eligible for compression.

### More Information

If you require any further explanation of TinyCI, consult the [README](https://github.com/JonnieCache/tinyci), the [RDoc](http://rdoc.info/gems/tinyci), or feel free to [email me.](mailto:jonnie@cleverna.me)

### Copyright

Copyright (c) 2019 Jonathan Davies. See [LICENSE](LICENSE) for details.

