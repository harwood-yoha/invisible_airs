use strict;
use warnings;
use DBD;


my $dbd = DBD->new;
$dbd->Connect_DB;
$dbd->Init_DB;
#$dbd->add_student_DB('mick',32,'London');
