use strict;
use warnings;
use Test::More;
use Cpanel::JSON::XS;

die("*** ERROR: this test is meant to be run with PLACK_TEST_EXTERNALSERVER_URI set,\nex.: THRUK_TEST_AUTH=omdadmin:omd PLACK_TEST_EXTERNALSERVER_URI=http://localhost:60080/demo perl t/scenarios/rest_api/t/305-controller_rest_commands.t") unless defined $ENV{'PLACK_TEST_EXTERNALSERVER_URI'};

BEGIN {
    plan tests => 722;

    use lib('t');
    require TestUtils;
    import TestUtils;
    $ENV{'NO_POST_TOKEN'} = 1; # disable adding "token" to each POST request
}

use_ok 'Thruk::Controller::Rest::V1::cmd';

my($host,$service) = ('localhost', 'Users');
my($hostgroup,$servicegroup) = ('Everything', 'Http Check');
my $cmds = Thruk::Controller::Rest::V1::cmd::get_rest_external_command_data();

for my $type (sort keys %{$cmds}) {
    my $obj_path = '';
    if($type eq 'hosts') {
        $obj_path = '/'.$host;
    } elsif($type eq 'hostgroups') {
        $obj_path = '/'.$hostgroup;
    } elsif($type eq 'services') {
        $obj_path = '/'.$host.'/'.$service;
    } elsif($type eq 'servicegroups') {
        $obj_path = '/'.$servicegroup;
    } elsif($type eq 'system') {
        $obj_path = '';
    } else {
        BAIL_OUT("unknown type: ".$type);
    }
    for my $cmd (sort keys %{$cmds->{$type}}) {
        next if $cmd eq 'acknowledge_host_problem_expire';
        next if $cmd eq 'acknowledge_svc_problem_expire';
        next if $cmd eq 'shutdown_process';
        next if $cmd eq 'restart_process';
        my $test = {
            'content_type' => 'application/json;charset=UTF-8',
            'url'          => '/thruk/r/'.$type.$obj_path.'/cmd/'.$cmd,
            'like'         => ['Command successfully submitted', 'COMMAND \['],
            'unlike'       => ['sending command failed'],
            'post'         => {
                comment_data      => "test",
                plugin_output     => "test",
                notification_time => "+60m",
                comment_id        => "1",
                downtime_id       => "1",
             },
        };
        TestUtils::test_page(%{$test});
    }
}
