#!/usr/bin/env perl
# Copyright (c) 2014, Aleksandr Derbenev <ya.alex-ac@yandex.com>
# This file is distributed under BSD License that can be found in the
# License.md file.

package SortIncludes;

use strict;
use warnings;
use v5.10;

use Getopt::Long qw(GetOptions);
use FileHandle;
use Pod::Find qw(pod_where);
use Pod::Usage;
use Test::More;

sub read_file($) {
  my ($file) = @_;
  my $fh = FileHandle->new($file, 'r');
  die "Can't read `$file`!" if !defined $fh;
  <$fh>;
}

sub write_file($@) {
  my ($file, @content) = @_;
  my $fh = FileHandle->new($file, 'w');
  die "Can't write `$file`!" if !defined $fh;
  print $fh @content;
}

sub sort_includes(@) {
  my (@content) = @_;

  my $block_start;
  my $block_end;
  my $i = 0;
  for (@content) {
    if (/^#(?:include|import) [<"][^<>"]+[>"]/) {
      $block_end = $i;
      $block_start = $i if !defined $block_start;
    } elsif (defined $block_start) {
      @content[$block_start..$block_end] =
          sort {
              ($a =~ /^#(?:include|import) [<"]([^<>"]+)[>"]/)[0] cmp
              ($b =~ /^#(?:include|import) [<"]([^<>"]+)[>"]/)[0]
          } @content[$block_start..$block_end];
      undef $block_start;
    }
    ++$i;
  }
  if (defined $block_start) {
    @content[$block_start..$#content] =
        sort {
            ($a =~ /^#(?:include|import) [<"]([^<>"]+)[>"]/)[0] cmp
            ($b =~ /^#(?:include|import) [<"]([^<>"]+)[>"]/)[0]
        } @content[$block_start..$#content];
  }

  @content;
}

sub sort_includes_test() {
  my @input = (
      '#include <cassert>',
      '#import <Cocoa/Cocoa.h>',
      '#include <stdio.h>',
      '',
      '#include "my_c_plus_plus_class.h"',
      '#import "MyObjectiveCClass.h"',
      '#if 0',
      '#include "hello2.h"',
      '#include "hello1.h"',
      '#endif',
      );
  my @output = (
      '#import <Cocoa/Cocoa.h>',
      '#include <cassert>',
      '#include <stdio.h>',
      '',
      '#import "MyObjectiveCClass.h"',
      '#include "my_c_plus_plus_class.h"',
      '#if 0',
      '#include "hello1.h"',
      '#include "hello2.h"',
      '#endif',
      );
  ok(@output == sort_includes(@input), "Presorted test.");
}

sub process($) {
  my ($file) = @_;

  write_file $file, sort_includes read_file $file;
}

sub main() {
  my @inputs;
  my $help;
  my $man;
  GetOptions '<>' => sub { push @inputs, $_[0] },
             'help|h|?' => \$help,
             'man' => \$man
      or pod2usage -message => "Can't parse arguments!",
                   -exitval => 2,
                   -verbose => 1
                   -input => pod_where({-inc => 1}, __PACKAGE__);
  pod2usage -exitval => 1,
            -input => pod_where({-inc => 1}, __PACKAGE__),
            -verbose => 1 if $help;
  pod2usage -exitval => 0,
            -input => pod_where({-inc => 1}, __PACKAGE__),
            -verbose => 2 if $man;
  pod2usage -exitval => 3,
            -verbose => 1,
            -input => pod_where({-inc => 1}, __PACKAGE__),
            -message => "No input file specified!" if !scalar @inputs;
  process $_ for @inputs;
}

sub test() {
  sort_includes_test;
}

1;

__END__


=head1 NAME

sort-includes - Sort include and import preprocessor directives alphabeticaly
in the C/C++/Objective-C/Objective-C++ source files.

=head1 SYNOPSYS

sort-includes [options] file ...

  Options:
    -help           brief documentation
    -man            full documentation

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Print the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s), sort
B<#include>/B<#import> preprocessor directives alphabetically and writes result
back to the file.

=head1 AUTHOR

Aleksandr Derbenev <ya.alex-ac@yandex.com>

=cut

