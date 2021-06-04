package Mojolicious::Command::Author::generate::obrazi;
use Mojo::Base Mojolicious::Command => -signatures;
use Mojo::File 'path';
use Mojo::Util qw(getopt encode decode dumper);
use Mojo::Collection 'c';
use Text::CSV_XS qw( csv );
use Imager;

sub _U {'UTF-8'}
has description => 'Generate a gallery from a directory structure with images';
has usage       => sub { shift->extract_usage };
my $headers = [qw(category path title description author image thumbnail)];
has from_dir => sub { path('./')->to_abs };
has to_dir   => sub { $_[0]->app->home->child('public') };

# images to be resized
has matrix => sub { c($headers) };

# '1000x1000'
sub max {
  if ($_[1]) {
    ($_[0]->{max}{width}, $_[0]->{max}{height}) = $_[1] =~ /(\d+)x(\d+)/;
    return $_[0];
  }
  return $_[0]->{max} //= {width => 1000, height => 1000};
}

# '100x100'
sub thumbs {
  if ($_[1]) {
    ($_[0]->{thumbs}{width}, $_[0]->{thumbs}{height}) = $_[1] =~ /(\d+)x(\d+)/;
    return $_[0];
  }
  return $_[0]->{thumbs} //= {width => 100, height => 100};
}

sub run ($self, @args) {
  getopt \@args,
    'f|from=s'   => \(my $from_dir = $self->from_dir),
    't|to=s'     => \(my $to_dir   = $self->to_dir),
    'x|max=s'    => \(my $max      = $self->max),
    's|thumbs=s' => \(my $thumbs   = $self->thumbs),
    ;
  $self->from_dir(path($from_dir)->to_abs)->to_dir(path($to_dir)->to_abs)->max($max)->thumbs($thumbs);
  $self->_do_csv();
  $self->_resize();
  $self->_copy_to();
  return;
}

# Reads the `from_dir` and dumps a csv file named after the from_dir folder.
# The file contains a table with paths and default titles and descriptions for
# the pictures.  This file can be given to the painter to add titles and
# descriptions for the pictures using an application like LibreOffice Calc or
# M$ Excel.
sub _do_csv ($self, $root = $self->from_dir) {
  my $csv_filepath = decode _U, $root->child($root->to_array->[-1] . '.csv');
  if (-f $csv_filepath) {
    $self->app->log->debug(
      "$csv_filepath already exists.$/\tIf you want to refresh it, please remove it.$/\tContinuing with resizing and copying files...$/"
    );
    return $self;
  }
  my $matrix = $self->matrix;
  my $category;
  $root->list_tree({dir => 1})->sort->each(sub {
    if (-d $_) {
      $category = decode(_U, $_->to_array->[-1]);
      push @$matrix,
        [
        $category,
        decode(_U, $_->to_string =~ s|$root||r),
        'Заглавие на категорията с до две-три думи',
        'Описание с две до пет изречения на категорията - къде какво, кога, защо, за кого и т.н',
        'Марио Беров', '', '',
        ];
    }
    else {
      return if $_ !~ /(?:jpe?g|png|gif)$/i;
      say $_;
      my $img;
      my $warning = '';
      if (not eval { $img = Imager->new(file => $_) }) {
        $warning = ' !!! Skipping... ' . Imager->errstr();

        # return;
      }
      my $size  = {width => ($img ? $img->getwidth() : 'XXXX'), height => ($img ? $img->getheight() : 'XXXX')};
      my $image = decode(_U, $_->to_array->[-1]);
      push @$matrix,
        [
        $category,
        decode(_U, ($_->to_string =~ s|$root||r) . $warning),
        'Заглавие на изображението с до две-три думи',
        'Описание с две до пет изречения на изображението.'
          . $/
          . ' Материали, размери,какво, защо - според каквото мислиш, че е важно.',
        'Марио Беров',
        $image =~ s/^(.+?)\.(.\w+)$/$1-$size->{width}x$size->{height}.$2/r,
        '',
        ];
    }
  });
  csv(in => $matrix->to_array, enc => _U, out => \my $data, binary => 1, sep_char => ",");
  path($csv_filepath)->spurt($data);

  # say dumper($matrix);
  return $self;
}

# Scales and resizes images to maximum width and height and generates thumbnails
sub _resize($self) {
  my $matrix = $self->matrix;
  if (@$matrix == 1) {

    # read the CSV file from disk to get calc
    my $root = $self->from_dir;
    my $csv_filepath = decode _U, $root->child($root->to_array->[-1] . '.csv');
    $matrix = c @{csv(in => $csv_filepath, enc => _U, binary => 1, sep_char => ",")};
    $self->matrix($matrix);
  }
  return $self;
}

sub _copy_to($self) {

}
1;

=encoding utf8

=head1 NAME

Mojolicious::Command::Author::generate::obrazi - a gallery generator command

=head1 SYNOPSIS

  Usage: APPLICATION generate obrazi [OPTIONS]

    ./myapp.pl generate obrazi --from --to
    mojo generate obrazi --from ~/Pictures/summer-2021 \
        --to /opt/myapp/public/summer-2021

    mojo generate obrazi --from ~/Pictures/summer-2021 \
        --to /opt/myapp/public/albums/summer-2021 -x 800x600 -s 96x96

  Options:
    -h, --help   Show this summary of available options
    -f, --from   Root of directory structure from which the images
                 will be taken. Defaults to ./.
    -t, --to     Root directory where the gallery will be put. Defaults to ./.
    -x, --max    Maximal image dimesnions in pixels in format 'widthxheight'.
                 Defaults to 1000x1000.
    -s, --thumbs Thumbnails maximal dimensions. Defaults to 100x100 pixels.

=head1 DESCRIPTION

L<Mojolicious::Command::Author::generate::obrazi generates a gallery from a
directory structure containing images. The gallery is a static html file which
content can be easily taken, modified, and embedded into any page.

In addition the command generates a csv file describing the images. This file
can be edited. Titles and descriptions can be added for each image and then the
command can be run again to regenerate the gallery with the new titles and
descriptions.

The word B<обраꙁъ>(singular) means L<face, image, picture, symbol, example,
template, etc.|https://histdict.uni-sofia.bg/dictionary/show/d_05616>
in OCS/Old BG language.

=head1 ATTRIBUTES

L<Mojolicious::Command::Author::generate::obrazi> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $обраꙁи->description;
  $makefile       = $обраꙁи->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $обраꙁи->usage;
  $makefile = $обраꙁи->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::Author::generate::obrazi> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $makefile->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Imager>, L<Text::CSV_XS>
L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut


