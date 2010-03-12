package Thruk;

use 5.008000;
use strict;
use warnings;

use Thruk::Utils;
use Catalyst::Runtime '5.70';

###################################################
# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages

use parent qw/Catalyst/;
use Catalyst qw/
                Authentication
                Authorization::ThrukRoles
                CustomErrorMessage
                ConfigLoader
                StackTrace
                Static::Simple
                Redirect
                Compress::Gzip
                /;
our $VERSION = '0.44';

###################################################
# Configure the application.
#
# Note that settings in thruk.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config('name'                   => 'Thruk',
                    'version'                => $VERSION,
                    'released'               => 'March 12, 2010',
                    'image_path'             => 'root/thruk/images',
                    'default_view'           => 'TT',
                    'View::TT'               => {
                        TEMPLATE_EXTENSION => '.tt',
                        ENCODING           => 'utf8',
                        INCLUDE_PATH       => 'templates',
                        FILTERS            => {
                                                'duration'  => \&Thruk::Utils::filter_duration,
                                                'nl2br'     => \&Thruk::Utils::filter_nl2br,
                                            },
                        PRE_DEFINE         => {
                                                'sprintf'      => \&Thruk::Utils::filter_sprintf,
                                                'duration'     => \&Thruk::Utils::filter_duration,
                                                'name2id'      => \&Thruk::Utils::name2id,
                                                'uri'          => \&Thruk::Utils::uri,
                                                'uri_with'     => \&Thruk::Utils::uri_with,
                                                'html_escape'  => \&Thruk::Utils::_html_escape,
                                            },
                        PRE_CHOMP          => 1,
                        POST_CHOMP         => 1,
                        TRIM               => 1,
                        CACHE_SIZE         => 0,
                        COMPILE_EXT        => '.ttc',
                        COMPILE_DIR        => '/tmp/ttc',
                        STAT_TTL           => 60,
                        STRICT             => 0,
#                        DEBUG              => 'all',
                    },
                    'View::GD'               => {
                        gd_image_type      => 'png',

                    },
                    'Plugin::ConfigLoader'   => { file => 'thruk.conf' },
                    'Plugin::Authentication' => {
                        default_realm => 'Thruk',
                        realms => {
                            Thruk => { credential => { class => 'Thruk'       },
                                       store      => { class => 'FromCGIConf' },
                            }
                        }
                    },
                    'custom-error-message' => {
                        'error-template'    => 'error.tt',
                        'response-status'   => 500,
                    },
                    'static' => {
                        'ignore_extensions' => [ qw/tpl tt tt2/ ],
                    },
);

###################################################
# set installed themes
my $themes_dir = "root/thruk/themes/";
my @themes;
opendir(my $dh, $themes_dir) or die "can't opendir '$themes_dir': $!";
for my $entry (readdir($dh)) {
    next unless -d $themes_dir."/".$entry;
    next if $entry =~ m/^\./mx; # hide hidden dirs
    next if $entry eq 'images';
    push @themes, $entry;
}
@themes = sort @themes;
closedir $dh;
__PACKAGE__->config->{'View::TT'}->{'PRE_DEFINE'}->{'themes'} = \@themes;

###################################################
# set installed themes
my $ssi_dir = "ssi/";
my %ssi;
opendir( $dh, $ssi_dir) or die "can't opendir '$ssi_dir': $!";
for my $entry (readdir($dh)) {
    next if $entry eq '.' or $entry eq '..';
    next if $entry !~ /\.ssi$/mx;
    $ssi{$entry} = { name => $entry } 
}
closedir $dh;
__PACKAGE__->config->{'ssi_includes'} = \%ssi;

###################################################
# Start the application
__PACKAGE__->setup();


###################################################
# Logging
#
# check if logdir exists
if(!-d 'logs') { mkdir('logs') or die("failed to create logs directory: $!"); }

# initialize Log4Perl
use Catalyst::Log::Log4perl;

my $log4perlconfig;
my $log4confarr = __PACKAGE__->config->{'Catalyst::Log::Log4perl'}->{'conf'};
if(defined $log4confarr and ref $log4confarr eq 'ARRAY') {
    $log4perlconfig .= join("\n", @{$log4confarr})."\n";
    __PACKAGE__->log(Catalyst::Log::Log4perl->new(\$log4perlconfig));
}
elsif(!__PACKAGE__->debug) {
    __PACKAGE__->log->levels( 'info', 'warn', 'error', 'fatal' );
}

###################################################
# GD installed?
__PACKAGE__->config->{'has_gd'} = 1;

=head1 NAME

Thruk - Catalyst based monitoring web interface

=head1 SYNOPSIS

    script/thruk_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Thruk::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Sven Nierlein, 2009, <nierlein@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
