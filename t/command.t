use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::File qw(curfile path tempdir);
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
  note $from_dir . '|' . $random_tempdir;
  my $buffer = '';
  {
    open my $handle, '>', \$buffer;
    local *STDOUT = $handle;
    $command->run('-f' => $from_dir, '-t' => $random_tempdir);
  }
  note $buffer;
  like $buffer => qr/loga16\.png/, 'right file';
};
subtest help     => $help;
subtest defaults => $defaults;
#TODO subtest run      => $run;

done_testing;

