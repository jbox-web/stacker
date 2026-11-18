require "../spec_helper"

describe Stacker::Licenses do
  # The list follows licenses.manifest: the LICENSE of each runtime shard
  # (kemal's own dependencies included), the upstream text of each C library
  # whose license carries a copyright line of its own, one grouped file per
  # SPDX id for the others, plus the project's own LICENSE. An empty or
  # partial list means the harvest did not run before compilation.
  it "embeds the notices of the manifest plus the project license" do
    Stacker::Licenses::FILES.keys.should eq([
      "admiral.txt",
      "backtracer.txt",
      "clib-Apache-2.0.txt",
      "clib-Boehm-GC.txt",
      "clib-GCC-runtime-exception.txt",
      "crinja.txt",
      "crystal-env.txt",
      "exception_page.txt",
      "kemal.txt",
      "liblzma.txt",
      "libxml2.txt",
      "libyaml.txt",
      "musl.txt",
      "pcre2.txt",
      "radix.txt",
      "stacker.txt",
      "systemd_notify.txt",
      "zlib.txt",
    ])
  end

  it "records which libraries each grouped notice covers" do
    Stacker::Licenses::FILES["clib-Apache-2.0.txt"].should start_with("Used by: openssl, crystal\n")
  end

  # The GCC Runtime Library Exception 3.1 is an additional permission of the
  # GPLv3: libgcc is GPL-3.0-or-later WITH that exception, never GPL-2.0.
  it "names the license the GCC runtime exception applies to" do
    notice = Stacker::Licenses::FILES["clib-GCC-runtime-exception.txt"]
    notice.should contain("libgcc is distributed under GPL-3.0-or-later WITH the following exception")
    notice.should_not contain("GPL-2.0")
  end

  # MIT, BSD and zlib all require the copyright notice to be reproduced: the
  # notice of the library, not the blank of a license template.
  it "carries the copyright notice of each library, as its authors wrote it" do
    files = Stacker::Licenses::FILES
    files["admiral.txt"].should contain("Copyright (c) 2017 Jason Waldrip")
    files["backtracer.txt"].should contain("Copyright (c) 2020 Sijawusz Pur Rahnama")
    files["crinja.txt"].should contain("Copyright 2017 Johannes Müller")
    files["crystal-env.txt"].should contain("Copyright (c) 2017 Brian J. Cardiff")
    files["exception_page.txt"].should contain("Copyright (c) 2018 Paul Smith")
    files["kemal.txt"].should contain("Copyright (c) 2016 Serdar Doğruyol")
    files["radix.txt"].should contain("Copyright (c) 2016 Luis Lavena")
    files["systemd_notify.txt"].should contain("Copyright (c) 2019 Serge Pokhodyaev")
    files["stacker.txt"].should contain("Copyright (c) 2020-2026 Nicolas Rodriguez")
    files["libxml2.txt"].should contain("Copyright (C) 1998-2012 Daniel Veillard")
    files["libyaml.txt"].should contain("Copyright (c) 2006-2016 Kirill Simonov")
    files["musl.txt"].should contain("Copyright © 2005-2020 Rich Felker, et al.")
    files["pcre2.txt"].should contain("University of Cambridge")
    files["zlib.txt"].should contain("Jean-loup Gailly and Mark Adler")
  end

  it "embeds no license template with its blanks left in" do
    Stacker::Licenses::FILES.each do |name, text|
      text.should_not match(/<year>|<owner>|<copyright holders>/), name
    end
  end

  # What `stacker licenses` prints: every notice, each under a header that
  # names its file, separated by a blank line.
  describe ".text" do
    it "prints each notice under a header naming its file, in order" do
      text = Stacker::Licenses.text
      text.should start_with("==> admiral.txt <==\n")
      text.should contain("\n\n==> backtracer.txt <==\n")
      text.scan(/^==> [^\n]+ <==$/m).size.should eq(18)
    end
  end
end
