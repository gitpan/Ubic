use strict;
use warnings;

package Ubic::UserGroupInspection;
BEGIN {
  $Ubic::UserGroupInspection::VERSION = '1.25';
}

use base 'Exporter';
our @EXPORT_OK = qw( effective_group_id real_group_id effective_user_id real_user_id );

BEGIN {
    return if $^O ne 'MSWin32';

    require Win32::pwent;
    push @Win32::pwent::EXPORT_OK, 'endgrent';
    Win32::pwent->import( qw( getpwent endpwent setpwent getpwnam getpwuid getgrent endgrent setgrent getgrnam getgrgid ) );
}


sub effective_group_id {
    return $) if $^O ne 'MSWin32';
    return _win_current_group_id();
}


sub real_group_id {
    return $( if $^O ne 'MSWin32';
    return _win_current_group_id();
}


sub _win_current_group_id {
    require Win32API::Net;

    my %userInfo;
    Win32API::Net::UserGetInfo( "", getlogin, 4, \%userInfo );
    Win32API::Net::UserGetInfo( "", getlogin, 3, \%userInfo ) if !keys %userInfo;
    die "UserGetInfo() failed: $^E" if !keys %userInfo;

    return "$userInfo{primaryGroupId} $userInfo{primaryGroupId}";
}


sub effective_user_id {
    return $> if $^O ne 'MSWin32';
    return getpwnam getlogin;
}


sub real_user_id {
    return $< if $^O ne 'MSWin32';
    return getpwnam getlogin;
}

__END__
=pod

=head1 NAME

Ubic::UserGroupInspection

=head1 VERSION

version 1.25

=head2 effective_group_id

Returns OS-independently the effective group id of the current process.

=head2 real_group_id

Returns OS-independently the real group id of the current process.

=head2 _win_current_group_id

Returns the group id of the current process. It is basically just the main group id of the current user.

=head2 effective_user_id

Returns OS-independently the effective user id of the current process.

=head2 real_user_id

Returns OS-independently the real user id of the current process.

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

