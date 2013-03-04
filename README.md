[![Build Status](https://secure.travis-ci.org/elgalu/thor-exclude_pattern.png?branch=master)](http://travis-ci.org/elgalu/thor-exclude_pattern)

Thor with exclude_pattern
=========================

This fork adds a new option :exclude_pattern => /regexp/ to the directory() method.

Directory method
----------------

> Copies recursively the files from source directory to root directory. If any of the files finishes with .tt, it's considered to be a template and is placed in the destination without the extension .tt. If any empty directory is found, it's copied and all .empty_directory files are ignored. If any file name is wrapped within % signs, the text within the % signs will be executed as a method and replaced with the returned value.

If :exclude_pattern => /regexp/, it prevents copying files that match that regexp.

Specs for the added option
--------------------------

```ruby
it "ignores files within excluding/ directories when exclude_pattern is provided" do
  invoke! "doc", "docs", :exclude_pattern => /excluding\//
  file = File.join(destination_root, "docs", "excluding", "rdoc.rb")
  expect(File.exists?(file)).to be_false
end

it "copies and evalutes files within excluding/ directory when no exclude_pattern is present" do
  invoke! "doc", "docs"
  file = File.join(destination_root, "docs", "excluding", "rdoc.rb")
  expect(File.exists?(file)).to be_true
  expect(File.read(file)).to eq("BAR = BAR\n")
end
```

[![Gem Version](https://badge.fury.io/rb/thor.png)](https://rubygems.org/gems/thor)
[![Dependency Status](https://gemnasium.com/wycats/thor.png?travis)](https://gemnasium.com/wycats/thor)
[![Code Climate](https://codeclimate.com/github/wycats/thor.png)](https://codeclimate.com/github/wycats/thor)
[![Coverage Status](https://coveralls.io/repos/wycats/thor/badge.png?branch=master)](https://coveralls.io/r/wycats/thor)

Thor
====

Description
-----------
Thor is a simple and efficient tool for building self-documenting command line
utilities.  It removes the pain of parsing command line options, writing
"USAGE:" banners, and can also be used as an alternative to the [Rake][rake]
build tool.  The syntax is Rake-like, so it should be familiar to most Rake
users.

[rake]: https://github.com/jimweirich/rake

Installation
------------
    gem install thor

Usage and documentation
-----------------------
Please see the [wiki][] for basic usage and other documentation on using Thor.

[wiki]: https://github.com/wycats/thor/wiki

License
-------
Released under the MIT License.  See the [LICENSE][] file for further details.

[license]: LICENSE.md
