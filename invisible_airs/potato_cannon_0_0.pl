#!/usr/bin/perl
 
#use warnings;
use strict;
use Device::SerialPort;
use lib "DBMS";
use DBD;
use Time::HiRes qw(usleep);
use Term::Screen;
use Term::ReadKey;

use constant DEBUG			=> 0;#turns off serial port
use constant AUTO			=> 1;
use constant WITH_KNIFE 		=> 0;
use constant WITH_SANDERS		=> 0;#using sanders
use constant WITH_POTATO		=> 1;#using potato
use constant WITH_SEAT			=> 0;#using seat

use constant DISPLAY_PAUSE		=> 1000000;
use constant SERIAL_PORT		=> qw( /dev/ttyUSB0 );#/dev/ttyUSB1);
use constant ROW_PRODUCTION		=> 4;

use constant SLEEP_BF_FIRE 		=> 500000;#
use constant SLEEP_AFT_FIRE 	 	=> 500000;#

use constant STRING_LENGTH		=> 80;

use constant SANDER_DELAY => 25000; # delay for rhythmic pulsing of sanders

use constant COL			=> 25;# <- from centre
use constant ROW			=> 4;
use constant COL_DATA			=> 10;# -> from centre
use constant COL_PRESSURE		=> 30;
use constant ROW_PRESSURE		=> 4;
# 1 millisecond == 1000 microseconds


use constant MIN_TIME_INTERVAL => 1000;
if( WITH_SANDERS){
	use constant MAX_TIME_INTERVAL => 16000000;
}else{
	use constant MAX_TIME_INTERVAL => 11000000; 
}
use constant TOTAL_TIME =>  MAX_TIME_INTERVAL - MIN_TIME_INTERVAL;

use constant MIN_PRESSURE => 0;
use constant MAX_PRESSURE  =>  100; 
use constant TOTAL_PRESSURE => MAX_PRESSURE - MIN_PRESSURE; 

use constant MIN_PAYMENT => 0;
use constant MAX_PAYMENT => 10000;
use constant TOTAL_PAYMENT => MAX_PAYMENT - MIN_PAYMENT;
require Term::Screen;

# sanity checks

######## init screen
my $flashing = 0;
my $scr = new Term::Screen;
unless ($scr) { die " Something's wrong w/screen \n"; }

####### init database BRISTOL_EXPENSES 
my $dbd = DBD->new;
$dbd->Connect_DB;

my $max_payment = $dbd->select_max('payment_amount', 'payment');

my @ids = undef;

if (WITH_SANDERS){	
	@ids = $dbd->get_older_people;
}else{
	@ids = $dbd->get_all_ids;
}

fisher_yates_shuffle(\@ids);

## calibrate the min_payment - max_payment

#my ($high,$low) = (0,100000000);

#foreach my $a (@ids){ 
#	my %payment = ();
#	$payment{id} = $a; 
#	$dbd->get_payment(\%payment);
#
#	if($high < $payment{amount}){
#		$high = $payment{amount};
#	}
#	if($low > $payment{amount}){
#		$low = $payment{amount};
#	}	
#	
#
#}
#die " $low  $high \n";

#exit;

#init conection to serial port for the air cannon

my $port = '';
$port = init_serial() if ! DEBUG;


# screen message

use constant WELCOME_MSG	=> "YoHa - Invisible Airs, Database, Expenditure, Power";
use constant STATUS_MSG		=> "Port: $port DEBUG: ".DEBUG. " AUTO: ".AUTO;
use constant TOOL_STATUS	=> 	" WITH_KNIFE: ".WITH_KNIFE. 
					" WITH_POTATO: ". WITH_POTATO .
					" WITH_SANDERS: ". WITH_SANDERS.
					" WITH_SEAT: " . WITH_SEAT;

use constant DESC_1_NAME 	=> 'DETAIL FIELD';
use constant DESC_1_TXT 	=> 'Goods, works or services being paid for by BCC';
use constant DESC_2_NAME 	=> 'SERVICE HEAD'; 
use constant DESC_2_TXT 	=> 'Overall service area, budget paying for goods, works or services';
use constant DESC_3_NAME 	=> 'COST CENTRE';
use constant DESC_3_TXT 	=> 'Individual cost centre for the record';

$scr->clrscr();
my $msg_border = '+---------------------------------------------------------------------------+';
$scr->at( 0, ($scr->cols()/2) - (length($msg_border)/2))->puts($msg_border);
$scr->at(3, ($scr->cols()/2) - (length(WELCOME_MSG)/2))->puts(WELCOME_MSG);
$scr->at(6, ($scr->cols()/2) - (length(WELCOME_MSG)/2))->puts(STATUS_MSG);
$scr->at(9, ($scr->cols()/2) - (length(TOOL_STATUS)/2))->puts(TOOL_STATUS);
$scr->at( 12, ($scr->cols()/2) - (length($msg_border)/2))->puts($msg_border);


# initialise cannon
init_air_cannon();

my $payment_index = 2;
my $last_payment_id = $dbd->get_last_id('payment');

my $k = $scr->getch(); 
while( $k ne 'q') {
	my %payment = ();
	my %display = '';
	$display{ln} =0;
	$payment{id} = $ids[$payment_index]; 
	$dbd->get_payment(\%payment);

	$display{desc_1} 	= $dbd->get_description($payment{desc_1_id});
	$display{desc_2} 	= $dbd->get_description($payment{desc_2_id});
	$display{desc_3} 	= $dbd->get_description($payment{desc_3_id});
	$display{suplier} 	= $dbd->get_suplier($payment{suplier_id});
	$display{payment} 	= int($payment{amount});
	die ' NO PAYMENT' unless $payment{amount};
	$display{pressure} 	= cash_to_psi($display{payment});
	$display{id}		= $payment_index -1 ;
	$payment_index++;

	$scr->clrscr();
	
	if($display{pressure} > MAX_PRESSURE){
		$display{ln} =	to_screen_display(\%display);
		next;
	}else{	
		$display{ln} = 	to_screen_display(\%display);
		if (! AUTO){
			manual(\%display);
		}else{
			auto(\%display);
		}
	}

	$scr->at(-1,-1); 
	$scr->clrscr();
	$scr->normal();
	usleep(SLEEP_AFT_FIRE);
	if($scr->key_pressed()){
		$k = $scr->getch(); 
	}
}

$scr->clrscr();
$scr->normal();

sub auto {
	my $display_ref = shift;


	$scr->clrscr();
	usleep(SLEEP_BF_FIRE);
	$display_ref->{ln} = 0;
	$display_ref->{ln} = to_screen_display($display_ref);
	#die; " ln " . $display_ref->{ln};
	convert_expenditure_to_air($display_ref->{ln},$display_ref->{payment},$display_ref->{pressure});	
	usleep(DISPLAY_PAUSE);
	$scr->clrscr;
	$display_ref->{ln} = 0;
	$display_ref->{ln} = to_screen_display($display_ref);
	if(WITH_SANDERS){
		trigger_sanders($display_ref->{pressure},$display_ref->{ln});
	}else{
		fire_air_cannon($display_ref->{pressure},$display_ref->{ln});
	}
	usleep(DISPLAY_PAUSE);

}


sub manual {
	my ($display_ref) = @_;

	$display_ref->{ln} = press_to_fire($display_ref->{ln});
		
	my $my_sequence = qr/\x1b\x06\z/;  # <CTRL>+<ALT>+F
	my $key ='';
	my $key_buf = '';

	ReadMode 4;
	while ($key ne 'q') {
    	$key = ReadKey();
    	#printf "key=$key_buf\\x%02x\n", ord($key);  # debug
		if($key eq 'q'){exit;}
		$key_buf .= $key;
    		if ($key_buf =~ $my_sequence) {
        	#system "xmessage 'OH YA!'";
			$scr->clrscr();
			usleep(SLEEP_BF_FIRE);
			$display_ref->{ln} = 0;
			$display_ref->{ln} = to_screen_display($display_ref);	
			convert_expenditure_to_air($display_ref->{ln},$display_ref->{payment},$display_ref->{pressure});	
			usleep(DISPLAY_PAUSE);
			#	$scr->clrscr;
			if(WITH_SANDERS){
				trigger_sanders($display_ref->{pressure},$display_ref->{ln});
			}else{
				fire_air_cannon($display_ref->{pressure},$display_ref->{ln});
			}
			usleep(DISPLAY_PAUSE);
			last;
    		}
	};
	ReadMode 0;
}


sub convert_expenditure_to_air{
	
	my ($ln,$expense,$pressure) = @_;
	#die "($ln,$expense,$pressure) ";
	my @wait = qw(| / - \ | / - \ | / );
	my $expense_incre = $expense / 10;
	my $pressure_incre = $pressure / 10;
	my ($p,$e) = (0,0);
	for(my $cnt = 0; $cnt <= 10;$cnt++){
		#my $b_str = make_breath_str($cnt);	
		disp_expense_to_air($wait[$cnt],$ln,$e,int($p). ' psi');
		$p = $p + $pressure_incre;
		$e = $e + $expense_incre;

		$scr->at(-1,-1);
		usleep(250000);
			
	}


}

sub cash_to_psi {
	my $cash = shift;
	my $psi  = $cash * (TOTAL_PRESSURE / TOTAL_PAYMENT);
	return $psi;

}

sub psi_to_time {
	my $psi = shift;
	my $time  = $psi * (TOTAL_TIME / TOTAL_PRESSURE);
	return $time;

}

sub time_to_psi {

	my $time = shift;
		my $psi  = $time * (TOTAL_PRESSURE / TOTAL_TIME);

	return $psi;
}

sub fire_air_cannon {
	
	my ($psi,$ln,$dummy) = @_;
	my $current_pressure = MIN_PRESSURE;
	open_valve_in();
	my $str = '';
	
	my $total_sleep_time = psi_to_time($psi);
	#print " total sleep $total_sleep_time\n";
	my $sleep = $total_sleep_time / 10;
	my $cnt = 1;
	do {
		usleep($sleep);	
		$current_pressure += time_to_psi($sleep);
		my $b_str = make_breath_str($cnt);	
		disp_air($b_str,$ln, '[ OPEN ]', $current_pressure);
		$scr->at(-1,-1); 
		$cnt++;
		
	} while($current_pressure < $psi );
	close_valve_in();
	$cnt--;
	usleep(500000); 
	open_valve_out();
	do {
		usleep($sleep / 2);	
		$current_pressure -= time_to_psi($sleep);
		my $b_str = make_breath_str($cnt);
		if($current_pressure < 0){$current_pressure = 0;}	
		disp_air($b_str,$ln, '[CLOSED]', $current_pressure);
		$scr->at(-1,-1); 
		$cnt--;
#	}	

	} while($current_pressure > (MIN_PRESSURE) );
#	print "current pressure close valve out $current_pressure \n";

	#retard cylinder
	if(WITH_KNIFE){
	#	open_valve_out();
		open_valve_in();
		sleep 1;
	}
	close_valve_out();
	sleep 1;


}

sub init_air_cannon {
	close_valve_out();
	open_valve_in();	
}	

sub close_valve_in {		
     $port->write("a") if ! DEBUG;#air-out pin 13 HIGH	
}

sub open_valve_in {

	$port->write("b") if ! DEBUG;#air-in pin 13 LOW
}

sub close_valve_out {		
    $port->write("c") if ! DEBUG;#air-out pin 13 HIGH	
}

sub open_valve_out {

	$port->write("d") if ! DEBUG;#air-in pin 13 LOW
}

####################  BEGIN SANDERS #####################


# below sub triggers sanders in triplet with total duration split into thirds
sub trigger_sanders {
	
	my ($psi,$ln,$dummy) = @_;
	my $current_pressure = MIN_PRESSURE;
	my $total_sleep_time = psi_to_time($psi);	
	#my $sander_cycle = $total_sleep_time * 333;
	my $sander_cycle = $total_sleep_time / 3;

	fire_sander_one();
	sanders_time_to_screen ($sander_cycle,1,$ln);
	switch_off_sander_one();

	usleep(SANDER_DELAY);

	fire_sander_two();
	sanders_time_to_screen ($sander_cycle,2,$ln);
	switch_off_sander_two();

	usleep(SANDER_DELAY);	

	fire_sander_three();
	sanders_time_to_screen ($sander_cycle,3,$ln);
	switch_off_sander_three();

	usleep(SANDER_DELAY);


}	

sub sanders_time_to_screen {
	my ($total_sleep_time,$sander,$ln) = @_;
	my $str = '';
	my $current_pressure = 0;
	my $sleep = $total_sleep_time / 10;
	my $cnt = 1;
	for (my $cnt = 0;$cnt <= 10;$cnt++){
		$current_pressure += time_to_psi($sleep);

		my $b_str = make_breath_str($cnt);	
		disp_sander_air($b_str,$ln, $sander,'[ START ]', $current_pressure);
		$scr->at(-1,-1); 
		$cnt++;
		usleep($sleep);	
		}
		disp_sander_air('clossing',$ln, $sander,'[ STOP  ]', $current_pressure);
		$scr->at(-1,-1);
	}


sub init_sanders {
	# must have subroutines which set all relays to closed	
	switch_off_sander_one();
	switch_off_sander_two();
	switch_off_sander_three();
}


sub fire_sander_one {

	$port->write("e") if ! DEBUG;
}

sub fire_sander_two {

	$port->write("g") if ! DEBUG;
}

sub fire_sander_three {
	$port->write("i") if ! DEBUG;
}

sub switch_off_sander_one {
	$port->write("f") if ! DEBUG;
}

sub switch_off_sander_two {
	$port->write("h") if ! DEBUG;
}

sub switch_off_sander_three {
	$port->write("j") if ! DEBUG;
}

sub disp_sander_air {
	
	my ($str,$ln,$sander_num,$control,$current_pressure) = @_;

	
	my $msg_border = border();
	my $msg_name =  title_space('POLISHER/BRUSH AIR PRESSURE');
	
	$scr->at(ROW_PRESSURE+($ln+=2), 
		($scr->cols()/2) - length($msg_name)/2)->clreol()->bold()->reverse()->puts($msg_name);
	$scr->normal();
	$scr->at(ROW_PRESSURE+($ln+=2), 
		($scr->cols()/2) - COL_PRESSURE)->clreol()->bold()->puts('PREPAIRING SANDER: '. $sander_num);
	$scr->at(ROW_PRESSURE+($ln),
		($scr->cols()/2)  )->clreol()->bold()->puts('CURRENT PRESSURE ' .$current_pressure . ' PSI');
	$scr->at(ROW_PRESSURE+($ln+=2),
		($scr->cols()/2) - (length($msg_border)/2))->clreol()->bold()->puts($msg_border);

	if($control eq '[ START ]'){
		$scr->at(ROW_PRESSURE+($ln+=2),
			($scr->cols()/2) - COL_PRESSURE)->clreol()->bold()->puts('SANDER: '.$sander_num);
		$scr->at(ROW_PRESSURE+($ln),
			(($scr->cols()/2)  - COL_PRESSURE)+10)->clreol()->normal()->puts($str);
	}elsif ($control eq '[ STOP  ]'){
		$scr->at(ROW_PRESSURE+($ln+=2),
			($scr->cols()/2) - COL_PRESSURE)->clreol()->bold()->puts('SANDER: '.$sander_num);

		$scr->at(ROW_PRESSURE+($ln),
			(($scr->cols()/2)  - COL_PRESSURE)+10)->clreol()->normal()->puts($str);
	}else {
		$scr->at(ROW_PRESSURE+($ln+=2),($scr->cols()/2) - COL_PRESSURE)->clreol()->bold()->puts('AWAITING INSTRUCTION');

		$scr->at(ROW_PRESSURE+($ln), (($scr->cols()/2) - COL_PRESSURE)+10)->clreol()->normal()->puts($str);

	}
	$ln++;
	$scr->at(ROW_PRESSURE+($ln), ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	return $ln;
}



####################  END SANDERS #####################

sub init_serial {
    my @devs = SERIAL_PORT;
 
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





sub border {
	my $str = '';
	my $l = (STRING_LENGTH + COL_DATA)- COL;
	foreach(0..$l){$str .= '_'};
	return $str;
}

sub title_space {
	my $title = shift;          
	my $maxwidth = (STRING_LENGTH + COL_DATA)- COL;
        $maxwidth = length($title) if length($title) > $maxwidth;
        my $spc = '';  
        foreach( 0..($maxwidth - length($title))/2){
		$spc .= ' ';
	}

            #$title = " " * (($maxwidth - length($title))/2) . $title;
          return $spc.$title.$spc;
          
}


sub make_breath_str {
	my $num = shift;
	my $str = '';
	for(my $cnt = 0; $cnt < $num;$cnt++){
		$str .= '=';
	}
	return "$str>";
}
sub make_sander_str {
	my $num = shift;
	my $str;
	for(my $cnt = 0; $cnt < $num;$cnt++){
		$str .= '\/\\';
	}

	return $str.'>';
}


sub string_format {
	my $str = shift;
	my @words = split(/\s/,$str);
	my @string;
	my $cnt = 0;
	foreach my $w (@words){
		$string[$cnt] .= "$w ";
		if( length ($string[$cnt]) > STRING_LENGTH){$cnt++}
	}
	#foreach (@string){print "$_\n"}

	return (@string);

}

sub to_screen_display {

	my ($display_ref) = @_;
	
	my $cnt = 0;
	my $msg_border = border();
	$scr->at(ROW+$cnt, ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	my $msg_name =  title_space('BRISTOL CITY COUNCIL EXPENDITURE OVER £500');
	$scr->at(ROW+$cnt, ($scr->cols()/2) - length($msg_name)/2 )->clreol()->bold()->reverse()->puts($msg_name);
	$scr->normal();
	$cnt++;
	$scr->at(ROW+$cnt,  ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	entity_to_screen($cnt++,"SUPLIER:",$display_ref->{suplier});
	entity_to_screen($cnt++,DESC_1_NAME.":",$display_ref->{desc_1});
	entity_to_screen($cnt++,DESC_2_NAME.":",$display_ref->{desc_2});
	entity_to_screen($cnt++,DESC_3_NAME.":",$display_ref->{desc_3});
	entity_to_screen($cnt++,"PAYMENT:","£".$display_ref->{payment}.'.00');
	entity_to_screen($cnt++,"INDEX:",$display_ref->{id});
	$cnt++;
	return $cnt;

}


sub entity_to_screen {
	my ($ln,$entity,$atom) = @_;
	$scr->at(ROW+$ln,  ($scr->cols()/2) - COL)->clreol()->bold()->puts($entity);
	$scr->at(ROW+$ln,  ($scr->cols()/2) - COL_DATA)->clreol()->normal()->puts($atom);

}


sub press_to_fire {
	
	my ($ln) = @_;

	my $msg_border = '+-------------------------------------------------------------------+';
	$scr->at(ROW_PRESSURE+($ln+=2), ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);	
	my $msg_name =  title_space("PRESS <CTRL>+<ALT>+F TO FIRE");
	$scr->at(ROW_PRESSURE+($ln+=2), ($scr->cols()/2) - length($msg_name)/2)->clreol()->bold()->reverse()->puts($msg_name);
	$scr->normal();
	$ln+=2;
	$scr->at(ROW_PRESSURE+($ln), ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$ln++;
}




sub disp_expense_to_air {
	
	my ($str,$ln,$expense,$current_pressure) = @_;
	#die $current_pressure;

	my $msg_border = border();
	my $msg_name =  title_space('CONVERTING CASH INTO AIR PRESSURE - PLEASE WAIT');
	$scr->at(ROW_PRESSURE+($ln+=2), ($scr->cols()/2) - length($msg_name)/2)->clreol()->bold()->reverse()->puts($msg_name);
	$scr->normal();
	$scr->at(ROW_PRESSURE+($ln+=2),  ($scr->cols()/2) - COL_PRESSURE)->clreol()->bold()->puts('EXPENDITURE '.'£'.int($expense).'.00');
	$scr->at(ROW_PRESSURE+($ln),  ($scr->cols()/2) + COL_DATA)->clreol()->normal()->puts($str);

	$scr->at(ROW_PRESSURE+($ln),  ($scr->cols()/2) + (COL_DATA-6))->clreol()->bold()->puts('AIR PRESSURE ' .$current_pressure . ' PSI');
	$scr->at(ROW_PRESSURE+($ln+=2),($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$ln++;

}


sub disp_air {
	
	my ($str,$ln,$direction,$current_pressure) = @_;

	
	my $msg_border = border();
	my $msg_name =  title_space('AIR PRESSURE');
	$scr->at(ROW_PRESSURE+($ln+=2), ($scr->cols()/2) - length($msg_name)/2)->clreol()->bold()->reverse()->puts($msg_name);
	$scr->normal();
	$scr->at(ROW_PRESSURE+($ln+=2), ($scr->cols()/2) - COL_PRESSURE)->clreol()->bold()->puts('VALVE POSITION '. $direction);
	$scr->at(ROW_PRESSURE+($ln),($scr->cols()/2)  )->clreol()->bold()->puts('CURRENT PRESSURE ' .$current_pressure . ' PSI');
	$scr->at(ROW_PRESSURE+($ln+=2),($scr->cols()/2) - (length($msg_border)/2))->clreol()->bold()->puts($msg_border);

	if($direction eq '[ OPEN ]'){
		$scr->at(ROW_PRESSURE+($ln+=2),($scr->cols()/2) - COL_PRESSURE)->clreol()->bold()->puts('FILLING ');
		$scr->at(ROW_PRESSURE+($ln),(($scr->cols()/2)  - COL_PRESSURE)+10)->clreol()->normal()->puts($str);
	}elsif ($direction eq '[CLOSED]'){
		$scr->at(ROW_PRESSURE+($ln+=2),($scr->cols()/2) - COL_PRESSURE)->clreol()->bold()->puts('EMPTYING');

		$scr->at(ROW_PRESSURE+($ln),(($scr->cols()/2)  - COL_PRESSURE)+10)->clreol()->normal()->puts($str);
	}else {
		$scr->at(ROW_PRESSURE+($ln+=2),($scr->cols()/2) - COL_PRESSURE)->clreol()->bold()->puts('AWAITING INSTRUCTION');

		$scr->at(ROW_PRESSURE+($ln), (($scr->cols()/2) - COL_PRESSURE)+10)->clreol()->normal()->puts($str);

	}
	$ln++;
	$scr->at(ROW_PRESSURE+($ln), ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	return $ln;
}

#sub commify {
 #         local $_  = shift;
  #        1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
   #       return $_;
    #      }




#sub to_screen{
#	my $msg = shift;
#	if($type eq 'production'){
#		$scr->at(ROW_PRODUCTION, COL_PRODUCTION)->clreol()->puts($msg);
#		$scr->normal();
#
#
#	}
#}#

# fisher_yates_shuffle( \@array ) : generate a random permutation
# of @array in place
sub fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}
	

