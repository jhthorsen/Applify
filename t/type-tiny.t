use warnings;
use strict;
use Test::More;

plan skip_all => 'Types::Standard is required' unless eval 'require Types::Standard;1';

my $app = eval <<'HERE' or die $@;
use Applify;
use Types::Standard qw(ArrayRef Bool Int);
option bool => give_cookies => 'give', isa => Bool;
option int => n_cookies => 'cookies', isa => Int;
option int => people_ages => 'ages', isa => ArrayRef[Int], n_of => '@', default => sub { [qw(12 24 44)] };
app {};
HERE

{
  no warnings qw(once redefine);
  *Applify::print_help = sub { eval { $main::help++ } };
}

my $script = $app->_script;

is_deeply(run('--give-cookies'), [1, undef, [qw(12 24 44)]], 'type bool') or diag $@;
is_deeply(run('--n-cookies',   5),  [undef, 5,     [qw(12 24 44)]], 'type int')   or diag $@;
is_deeply(run('--people-ages', 10), [undef, undef, [qw(10)]],       'type array') or diag $@;

eval { $app->n_cookies('yikes') };
like "$@", qr{Failed check for "n_cookies".*"yikes"}s, '$app->n_cookies not int';

run('--n-cookies', 'foo');
like "$@", qr{Invalid input:.*foo}s, 'n_cookies not int';

run('--people-ages', 'bar');
like "$@", qr{Failed check for --people-ages:.*"bar"}s, 'people_ages not int';

done_testing;

sub run {
  local @ARGV = @_;
  return eval {
    my $app = $script->app;
    [$app->give_cookies, $app->n_cookies, $app->people_ages];
  } || [];
}
