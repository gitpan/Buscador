package Buscador::Thread;
use strict;

=head1 NAME

Buscador::Thread - provide some thread views for Buscador

=head1 DESCRIPTION

This provides two different thread views for Buscador - traditional 
'JWZ' style view and a rather funky looking 'lurker' style. They can be 
accessed using 


    ${base}/mail/thread/<id>
    ${base}/mail/lurker/<id>


where C<id> can be the message-id of any message in the thread. neat, huh?


=head1 SEE ALSO

JWZ style message threading
http://www.jwz.org/doc/threading.html

Lurker style
http://lurker.sourceforge.net

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright (c) 2004, Simon Wistow

=cut



package Mail::Thread; # Fscking hack!

no warnings 'redefine';

sub _get_hdr {

    my ($class, $msg, $hdr) = @_;
    $msg->simple->header($hdr) || '';
}


package Email::Store::Mail;
use strict;
use Mail::Thread::Chronological;

sub lurker :Exported {
   my ($self,$r)  = @_;
   my $mail       = $r->objects->[0];
   my $root       = $mail->container->root;

    while (1) {
        last if $root->message->date;
        my @children = $root->children;
        last if (@children>1);
        $root = $children[0];
    }

   my $lurker     = Mail::Thread::Chronological->new;
   my @root       = $lurker->arrange( $root );


   $r->{template_args}{root} = \@root;

}

sub thread :Exported {
    my ($self,$r)  = @_;
   my $mail       = $r->objects->[0];
   my $root       = $mail->container->root;

    while (1) {
        last if $root->message->date;
        my @children = $root->children;
        last if (@children>1);
        $root = $children[0];
    }

   $r->{template_args}{thread} = $root;
}


sub thread_as_html {
    my $mail = shift;
    my $cont = $mail->container;
    my $orig = $cont;
    my %crumbs;
    # We can't use ->root here, because we want to keep track of the
    # breadcrumbs, and this way is more efficient.
    while (1) {
        $crumbs{$cont}++;
        if ($cont->parent) { $cont = $cont->parent } else { last }
    }
    while (1) {
        last if $cont->message->date;
        my @children = $cont->children;
        last if (@children>1);
        $cont = $children[0];
    }
    my $html = "<UL class=\"mktree\">\n";
    my $add_me;
    my $base = Buscador->config->{uri_base};
    $add_me = sub {
        my $c = shift;
        $html .= "<li ".(exists $crumbs{$c} && "class=\"liOpen\"").">";

        # Bypass has-a because we might not really have it!
        my $mess = Email::Store::Mail->retrieve($c->message->id);
        if (!$mess) { $html .= "<i>message not available</i>" }
        elsif ($c == $orig) { $html .= "<b> this message </b>" }
        else {
            $html .= qq{<A HREF="${base}mail/view/}.$mess->id.q{">}.
        $mess->subject."</A>\n";
        $html .= "<BR>&nbsp;&nbsp<SMALL>".eval {$mess->addressings(role =>"From")->first->name->name}."</SMALL>\n";
        }

        if ($c->children) {
            $html .="<ul>\n";
            $add_me->($_) for $c->children;
            $html .= "</ul>\n";
        }
        $html .= "</li>\n";
    };
    $add_me->($cont);
    $html .="</ul>";
    return $html;
}

1;



