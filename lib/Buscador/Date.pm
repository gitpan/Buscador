package Buscador::Date;
use strict;


=head1 NAME

Buscador::Date - a plugin to provide date pages for Buscador

=head1 DESCRIPTION

This provides pages which "do the right thing" for

    ${base}/date/view/<year>
    ${base}/date/view/<year>/<month>
    ${base}/date/view/<year>/<month>/<day>

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright (c) 2004, Simon Wistow

=cut


# put path munging stuff here

sub parse_path_order { 13 }

sub parse_path {
    my ($self, $buscador) = @_;

    $buscador->{path} =~ s!date/!mail_date/!;
}



package Email::Store::Date;
use strict;
use Time::Piece;
use Time::Seconds;
use Lingua::EN::Numbers::Ordinate;

sub view :Exported {
    my $self = shift;
    return $self->list(@_);
}

sub list :Exported {
    my $self = shift;
    my ($r)  = @_;

    my @objects    = @{$r->args};

    $r->{path} =~ s!mail_date/!date/!;
    $r->{template_args}{ordinate} = sub { ordinate(shift) };

    return if @objects==1 && $self->year($r,  @objects);
    return if @objects==2 && $self->month($r, @objects);
    return $self->day($r, @objects);

}

sub day {
    my ($self,$r, @objects) = @_;

     $self = $self->do_pager($r);

    my $deftime    = localtime;
    my $time;

    my $s = sprintf "%.4d-%.2d-%.2d", $objects[0], $objects[1], $objects[2];
    eval {
            $time      = Time::Piece->strptime($s, "%Y-%m-%d");
    };
    $time = undef if $@ || $s ne $time->strftime("%Y-%m-%d");

    $time                      = $deftime unless defined $time;
    my @mails                  =  map { $_->mail } 
                                  $self->search(  year => $time->year, month => $time->mon, day => $time->mday );
    $r->{template}             = "list";
    $r->{template_args}{mails} = \@mails;
    $r->{template_args}{date}  = $time;
    $r->{template_args}{tomorrow}  = Time::Piece->new($time + ONE_DAY); 
    $r->{template_args}{yesterday} = Time::Piece->new($time - ONE_DAY);

}


sub month {
    my ($self,$r, @objects) = @_;

    my $year  = $objects[0];
    my $month = $objects[1];
    my $s     = sprintf "%.4d-%.2d-%.2d", $year, $month, 15;
    my $date  = Time::Piece->strptime($s, "%Y-%m-%d");

    

    my @days;
    for my $day (1..$date->month_last_day) {
        $days[$day-1] = scalar Email::Store::Date->search(  year => $year, month => $month, day => $day );
    }



    $r->{template}             = "month";
    $r->{template_args}{days}  = \@days;
    $r->{template_args}{date}  = $date;
    $r->{template_args}{next_month} = Time::Piece->new($date + ONE_MONTH);
    $r->{template_args}{last_month} = Time::Piece->new($date - ONE_MONTH);


    return 1;
}


sub year {
    my ($self,$r, @objects) = @_;


    my @months;
    my $year = $objects[0];


    for my $m (1..12) {
        $months[ $m - 1 ] = scalar Email::Store::Date->search( year => $year, month => $m );
    }

    $r->{template}              = "year";
    $r->{template_args}{months} = \@months;
    $r->{template_args}{year}   = $objects[0];
    $r->{template_args}{next}   = Time::Piece->strptime($year+1, "%Y");
    $r->{template_args}{prev}   = Time::Piece->strptime($year-1, "%Y");


    return 1;
}

use Class::DBI::Pager;
sub do_pager {
    my ($self, $r) = @_;
    if ( my $rows = $r->config->{rows_per_page}) {
        return $r->{template_args}{pager} = $self->pager($rows, $r->query->{page});
   } else { return $self }
}

1;


