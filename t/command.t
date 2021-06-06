use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::File qw(curfile path tempdir);
use Mojo::Util qw(encode decode);
use lib curfile->dirname->dirname->child('lib')->to_string;
my $t              = Test::Mojo->new('Mojolicious');
my $random_tempdir = tempdir('opraziXXXX', TMPDIR => 1, CLEANUP => 1);

my $COMMAND = 'Mojolicious::Command::Author::generate::obrazi';
require_ok($COMMAND);
my $command = $COMMAND->new();
isa_ok($command => 'Mojolicious::Command');

# Help
my $help = sub {
  my $buffer = '';
  {
    open my $handle, '>', \$buffer;
    local *STDOUT = $handle;
    $t->app->start('generate', 'obrazi', '-h');
  }

  like $buffer => qr/myapp.pl generate obrazi --from --to/ => 'SYNOPSIS';
  like $buffer => qr/-f, --from/                           => 'SYNOPSIS --from';
  like $buffer => qr/-t, --to/                             => 'SYNOPSIS --to';
  like $buffer => qr/-x, --max/                            => 'SYNOPSIS --max';
  like $buffer => qr/-s, --thumbs/                         => 'SYNOPSIS --thumbs';
};

my $defaults = sub {

  is $command->from_dir   => path('./')->to_abs, 'from_dir is current dir';
  is $command->to_dir     => $t->app->home->child('public'), 'to_dir is app->home/public';
  is_deeply $command->max => {width => 1000, height => 1000},
    'max is 1000x1000';
  is_deeply $command->thumbs => {width => 100, height => 100},
    'thumbs is 100x100';
  like $command->description => qr/images$/, 'right description';
};
my $run = sub {
  my $from_dir = curfile->dirname->child('data/from');

  # Remove previously generated index file.
  unlink "$from_dir/" . $from_dir->to_array->[-1] . '.csv';
  my $buffer = '';

  {
    open my $handle, '>', \$buffer;
    local *STDERR = $handle;
    $command->run('-f' => $from_dir, '-t' => $random_tempdir);
  }

  # note $buffer;
  like $buffer                  => qr/warn.+?Skipping.+?loga4.png. Image error: iCCP/, 'right warning';
  like $buffer                  => qr/loga16\.png/,                                    'right file';
  like decode('UTF-8', $buffer) => qr/Inspecting category мозайки/,                    'right category';
};
subtest help     => $help;
subtest defaults => $defaults;
subtest run      => $run;

done_testing;

