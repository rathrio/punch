$ punch [![Build Status](https://travis-ci.org/rathrio/punch.svg?branch=master)](https://travis-ci.org/rathrio/punch)
=====================================================================================================================

A CLI for file based time tracking.

This came into existence because maintaining an Excel sheet with my working
hours was a huge pain in the ass (mostly because I suck at Excel) and the
accountant didn't care about the format as long as it's somewhat readable.

Hence, I came up with a revolutionary format called BRF
(Brigitte-Readable-Format):

```
November 2014

20.11.14   08:00-12:00   12:30-18:30   Total: 10:00
22.11.14   14:00-16:00                 Total: 02:00

Total: 12:00
```

Super easy to read for Brigitte, super easy to parse and generate, aaand super
useless otherwise.

Recommended Installation
------------------------

Clone this repo and create an alias that executes `punch.rb`.

```bash
git clone git@github.com:rathrio/punch.git ~/wherever/you/like/punch
alias punch=`ruby ~/wherever/you/like/punch/punch.rb`
```

As an alternative to the alias you can link punch.rb to a folder in your path, e.g.

```bash
cd ~/wherever/you/like/punch/
ln -sr punch.rb ~/.bin/punch
```

Bash tab completion can be enabled by sourcing `punch-completion.bash`. Zsh
completion is currently provided
[here](https://github.com/rathrio/punch-zsh-completion).

Help and Documentation
----------------------

An exhaustive list of flags and switches can be found in `help.txt`, which will
also be printed via the `--help` (`-h`) switch. The most important features are
documented below in more detail.

To browse the docs locally, make sure you have the
[`yard`](https://github.com/lsegal/yard) gem installed and run `punch --doc`.
This will open them up in your default web browser.

Usage
-----

Punch saves your working time in a BRF text file. Each file represents one month
and new files will be automatically generated as time goes by. A month in Punch
starts on the 21th of the previous month and ends on the 20th of the current
one. To display the month, execute `punch` without any arguments:

```
$ punch

Krusty Krab - Mai 2015 - Spongebob Squarepants

10.05.15

Total: 00:00
```

The first line is the header, which contains the title of the BRF file, the
current month name and your full name. The following lines list the days you
have worked on on a separate line each. The last line show the monthly total.

The current day is always visible, even if you haven't added any blocks to it
yet. That's why you only see the current date in an empty month. For the
following examples the current day will 10.05.15 (DD.MM.YY).

### Adding blocks

What are blocks? A block is a time span with a start time and an end time (duh!)
and you can add them to the current day like this:

```
$ punch 08:00-12:30

Krusty Krab - Mai 2015 - Spongebob Squarepants

10.05.15   08:00-12:30   Total: 04:30

Total: 04:30
```

Leading zeros and minutes may be omitted, thus `punch 8-12:30` is equivalent to
`punch 08:00-12:30`. The colon can be omitted for 3+ digits.

You can pass multiple blocks to add them all to the current day:

```
$ punch 8-12:30 13:15-18

Krusty Krab - Mai 2015 - Spongebob Squarepants

10.05.15   08:00-12:30   13:15-18:00   Total: 09:15

Total: 09:15
```

### Adding blocks to past days

#### `--yesterday`

You forgot to punch your time yesterday? Use the `--yesterday` (`-y`) switch:

```
$ punch -y 8-10

Krusty Krab - Mai 2015 - Spongebob Squarepants

09.05.15   08:00-10:00                 Total: 02:00
10.05.15   08:00-12:30   13:15-18:00   Total: 09:15

Total: 11:15
```

#### `--day`

If yesterday is not far enough in the past, you can pass a date to add blocks to with the
`--day` (`-d`) flag:

```
$ punch -d 08.05.15 21:45-22

Krusty Krab - Mai 2015 - Spongebob Squarepants

08.05.15   21:45-22:00                 Total: 00:15
10.05.15   08:00-12:30   13:15-18:00   Total: 09:15

Total: 09:30
```

#### `--edit` and `--format`

Sometimes you mess up or you just want to manually edit the BRF file. For
scenarios like these, the `--edit` (`-e`) switch will open up the current BRF
file with your default text editor. You don't have to worry about the totals or
indentation when manually editing the file. Punch will automatically format the
file the next time you add some blocks. To trigger formatting by hand, use the
`--format` (`-f`) switch.

### Overlaps

Punch will automatically merge blocks together should you add one that overlaps
with others on the same day. So running `punch 12-15` and `punch 13-18` results in `12-18`.

```
$ punch 12-15

Krusty Krab - Mai 2015 - Spongebob Squarepants

10.05.15   12:00-15:00   Total: 03:00

Total: 03:00

$ punch 13-18

Krusty Krab - Mai 2015 - Spongebob Squarepants

10.05.15   12:00-18:00   Total: 06:00

Total: 06:00
```

This behaviour can be used to append, prepend and shadow blocks.

#### Caveats

A block belongs to the current day if the block's start time is on the current
day. This means that blocks that span over midnight are not split up, but belong
to the day they start at. Adding blocks on the following day that overlap with
these over-midnight blocks are currently not handled correctly.

```
$ punch

Krusty Krab - Mai 2015 - Spongebob Squarepants

09.05.15   23:00-02:00   Total: 03:00

Total: 03:00

$ punch 1-4

Krusty Krab - Mai 2015 - Spongebob Squarepants

09.05.15   23:00-02:00   Total: 03:00
10.05.15   01:00-04:00   Total: 03:00

Total: 06:00
```

### Interactive Editor

The `--interactive` (`-i`) mode comes in very handy when `--day` and
`--yesterday` just won't do. It provides a simple interface to select one or
more days and even allows you to add hours to multiple days with one punch.

![Demo](https://i.imgur.com/6x4y6Pc.gif)

#### Modes

There are basically two modes, the **command** and **punch** mode.

In command mode, indicated by the `>>` prompt, you can select days with a comma
or space separated list of numbers that correspond to the numbers on the very
left side in the braces. Once you hit return you will enter punch mode,
indicated by the `Add blocks:` prompt, where you can use the Punch syntax you're
used to from the default CLI. You can abort punch mode anytime by hitting return
with an empty prompt. This will return you to command mode.

In command mode, you can save and quit the interactive session with `x` and quit it
without saving with `q`.

Once you have exited the session with `x`, Punch will print the edited month
with the days updated highlighted in pink by default.
