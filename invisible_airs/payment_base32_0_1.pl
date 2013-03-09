#!/usr/bin/perl
 
use warnings;
use strict;
use Device::SerialPort;
use lib "DBMS";
use DBD;
use MIME::Base32 qw( RFC ); 
use Time::HiRes qw(usleep);
# 1 millisecond == 1000 microseconds
use constant MIN_TIME_INTERVAL => 1000;
use constant MAX_TIME_INTERVAL => 3500000;
use constant TOTAL_TIME =>  MAX_TIME_INTERVAL - MIN_TIME_INTERVAL;

# conect to database BRISTOL_EXPENSES as Citizen
my %lookup  = ( 'A' => [0,0,0,0,0,1,1,1,1,1], 
                 'B' => [1,1,1,1,1,0,0,0,0,0], 
                 'C' => [0,1,1,1,1,1,0,0,0,0],
                 'D' => [1,0,1,1,1,0,1,0,0,0],
                 'E' => [1,1,0,1,1,0,0,1,0,0],
                 'F' => [1,1,1,0,1,0,0,0,1,0],
                 'G' => [1,1,1,1,0,0,0,0,1,0],
                 'H' => [1,0,0,0,0,0,1,1,1,1],
                 'I' => [0,1,0,0,0,1,0,1,1,1],
                 'J' => [0,0,1,0,0,1,1,0,1,1],
                 'K' => [0,0,0,1,0,1,1,1,0,1],
                 'L' => [0,0,0,0,1,1,1,1,1,0],
                 'M' => [1,1,0,0,0,0,0,1,1,1],
                 'N' => [1,0,1,0,0,0,1,0,1,1],
                 'O' => [1,0,0,1,0,0,1,1,0,1],
                 'P' => [1,0,0,0,1,0,1,1,1,0],
                 'Q' => [0,1,1,0,0,1,0,0,1,1],
                 'U' => [0,1,0,1,0,1,0,1,0,1],
                 'R' => [0,1,0,0,1,1,0,1,1,0],
                 'S' => [0,0,1,1,0,1,1,0,0,1],
                 'T' => [0,0,1,0,1,1,1,0,1,0],
                 'V' => [0,0,0,1,1,1,1,1,0,0],
                 'W' => [0,0,1,1,1,1,1,0,0,0],
                 'X' => [0,1,0,1,1,1,0,1,0,0],
                 'Y' => [0,1,1,0,1,1,0,0,1,0],
                 'Z' => [0,1,1,1,0,1,0,0,0,1],
                 '2' => [1,0,0,1,1,0,1,1,0,0],
                 '3' => [1,0,1,0,1,0,1,0,1,0],
                 '4' => [1,0,1,1,0,0,1,0,0,1],
                 '5' => [1,1,0,0,1,0,0,1,1,0],
                 '6' => [1,1,0,1,0,0,0,1,0,1],
                 '7' => [1,1,1,0,0,0,0,0,1,1],
                    );   



my $dbd = DBD->new;
$dbd->Connect_DB;

#$dbd->get_older_perople();

#die;

my $max_payment = $dbd->select_max('payment_amount', 'payment');
#initialise conection to the air cannon

my $port = init_serial();
  
# initialise cannon

my $payment_index = 1;
my $last_payment_id = $dbd->get_last_id('payment');

while(1) {

	
	my %payment = ();
	$payment{id} = $payment_index;
	$payment_index++; #increment for next payment 
	$dbd->get_payment(\%payment);
	
	my ($desc) = $dbd->get_description($payment{desc_1_id});
#	my $desc = $dbd->get_suplier($cnt);
	my $encoded = MIME::Base32::encode("$desc £" . $payment{amount} . " ");
	my @code = split(//,$encoded);
	foreach my $str (@code){
		
		my @arr = @{$lookup{$str}};
		for(my $cnt = 0; $cnt <= $#arr;$cnt++){
			if ($arr[$cnt]){
				$port->write( $cnt);
				print " $cnt ";
			}else{
				$port->write('m');
				print " m ";
			} 
			#print "sending $_ \n";
			usleep(60000);		
			my $str = '';
			$str = $port->lookfor();
			chop $str;
   			print " str  = '$str' \n";
			#usleep(100000);
		}
	}
  	my $decoded = MIME::Base32::decode($encoded);

	#print " $encoded - $decoded \n";
	usleep(MAX_TIME_INTERVAL);	
}


sub init_serial {
    my @devs = qw( /dev/ttyUSB0 /dev/ttyUSB1 /dev/ttyUSB2 /dev/ttyUSB3);
 
    my $port = undef;
    for my $port_dev (@devs) {
        $port = Device::SerialPort->new($port_dev);
	print "$port_dev\n";
        last if $port;
    }
    if(!$port) {
        die "No known devices found to connect to serial: $!\n";
    }
 
    $port->databits(8);
    $port->baudrate(9600);
    $port->parity("none");
    $port->stopbits(1);
 
    return $port;
}





