
use strict;
use warnings;

package DBD;
{
    use Settings;
    use DBI;

    use constant FOUND     => 1;
    use constant NOT_FOUND => 0;

    sub new {
        my $class = shift;
        my $This  = {};

        bless $This, $class;
        return $This;
    }

    sub Connect_DB {
        my $This = shift;
        $This->{Dbh} = DBI->connect(
            MYSQL_DB,
            MYSQL_USER,
            MYSQL_PASS,
            {
                PrintError => MYSQL_PRINT_ERROR, #don't report errors via warn
                RaiseError => MYSQL_RAISE_ERROR, #Report errors via die
            }
        );
        return "ERROR: MSQL:\n Did not connect to (MYSQL){DB}: Maybe MYSQL is not setup " unless defined $This->{Dbh};
 
        return;
    }

    sub Init_DB {
        my $This = shift;
        # create the rables of the Monster
        #no strict "refs";
        my @Tables = keys(%MYSQL_TABLES);
        foreach (@Tables) {
            print "\n making table $_ ";
            my $query = $This->{Dbh}->prepare( $MYSQL_TABLES{$_} )
              or return "\n<P>ERROR: MSQL:<P>\n Can't prepare SQL $DBI::errstr\n";
            $query->execute
              or return "\n<P>ERROR: MSQL:<P>\n Can't execute SQL $DBI::errstr\n";
        }
        return;
    }

# special stuff to disconect properly from the database.
#
    sub Disconnect_DB {
        my $This = shift;
        # connect to database (regular DBI)
        $This->{Dbh}->disconnect;
        return;
    }

    sub DESTROY {
        my $This = shift;
        $This->Disconnect_DB unless not defined $This->{Dbh};

    }


  # sub get_older_perople {
#		
		my $This = shift;
 #       my $query =
  #        $This->{Dbh}->prepare("select suplier_name, payment_amount from suplier,description,payment where description_txt like '%older people%' and description_id = payment_desc_2 and suplier_id = payment_suplier_id;");
    #    $query->execute;
   #     my %suplier;
#	my $name;
#	my $payment;
#	while ( ($name,$payment) = $query->fetchrow_array){
#		$suplier{$name} += $payment;
#	}
 #       $query->finish;
#	foreach my $k (sort {$suplier{$b} <=> $suplier{$a} } keys %suplier){
#		print $k." = " .$suplier{$k}."\n";
#	}
 #      # return $amount;
#	}

sub get_total_spent_on_service {
	my $This = shift;
	my $service = shift;
	next if not $service;
	my $qservice = $This->{Dbh}->quote($service);
	$service =~ s/'/ /g;
        my $query =
          $This->{Dbh}->prepare("select payment_amount,description_id from description, payment  where 
		description_txt like '%$service%' and payment_desc_2 = description_id;");
        $query->execute;
	my $cash;
	my $desc_id;
	my $amount;
	while ( ($amount,$desc_id) = $query->fetchrow_array){
		$cash += int($amount);
	}
        $query->finish;
	#foreach my $k (sort {$suplier{$b} <=> $suplier{$a} } keys %suplier){
		print " '$desc_id' $cash \n";
	#}
       # return $amount;
#	$This->add_total($desc_id,$cash);
	return $cash;
	}



 sub get_service_head {
		
	my $This = shift;
        my $query =
          $This->{Dbh}->prepare("select description_txt from description,payment  where payment_desc_2 = description_id;
");
        $query->execute;
        my %desc;
	my $name;
	my $description_txt;
	while ( ($description_txt) = $query->fetchrow_array){
		$desc{$description_txt} = 1;
	}
        $query->finish;
	#foreach my $k (sort {$suplier{$b} <=> $suplier{$a} } keys %suplier){
	#	print $k." = " .$suplier{$k}."\n";
	#}
       # return $amount;

	return keys %desc;
	}

 sub get_older_people {
		
		my $This = shift;
        my $query =
          $This->{Dbh}->prepare("select payment_id ,description_txt from description,payment  where description_txt like '%older people%' and payment_desc_2 = description_id;
");
        $query->execute;
        my %suplier;
	my $name;
	my $payment_id;
	while ( ($payment_id) = $query->fetchrow_array){
		$suplier{$payment_id} = 1;
	}
        $query->finish;
	#foreach my $k (sort {$suplier{$b} <=> $suplier{$a} } keys %suplier){
	#	print $k." = " .$suplier{$k}."\n";
	#}
       # return $amount;

	return keys %suplier;
	}


 sub get_all_ids {
		
		my $This = shift;
        my $query =
          $This->{Dbh}->prepare("select payment_id from payment;");
        $query->execute;
        my %suplier;
	my $name;
	my $payment_id;
	while ( ($payment_id) = $query->fetchrow_array){
		$suplier{$payment_id} = 1;
	}
        $query->finish;
	#foreach my $k (sort {$suplier{$b} <=> $suplier{$a} } keys %suplier){
	#	print $k." = " .$suplier{$k}."\n";
	#}
       # return $amount;

	return keys %suplier;
	}


	sub add_payment_DB {
        	my ( 	
			$This,
			$payment_suplier,
			$payment_amount,
			$payment_desc_1,
			$payment_desc_2,
			$payment_desc_3,
			$payment_ref


	  	) = @_;


			my $suplier_id = $This->add_suplier($payment_suplier); 
        	my $description_id_1 = $This->add_description($payment_desc_1);
			my $description_id_2 = $This->add_description($payment_desc_2);
			my $description_id_3 = $This->add_description($payment_desc_3);	
			my $qpayment_ref = $This->{Dbh}->quote($payment_ref);
			
			# check if we have an entry for suplier
       	my $query    = $This->{Dbh}->prepare(
           	"SELECT payment_id FROM payment	WHERE
				payment_amount = '$payment_amount' 
				and payment_desc_1 = '$description_id_1' 
				and payment_desc_2 = '$description_id_2' 
				and payment_desc_3 = '$description_id_3'
			"   
		);
        $query->execute;
		my $payment_id = -1;
        ($payment_id) = $query->fetchrow_array;
        $query->finish;

        if ($payment_id) {
			return $payment_id;
		} else {
         # if no entry make one
			my $query = $This->{Dbh}->prepare(
               	"INSERT INTO payment ( 
						payment_amount,
						payment_ref,
						payment_suplier_id,
						payment_desc_1,
						payment_desc_2,
						payment_desc_3
					) values( 
						'$payment_amount',
						$qpayment_ref,
						'$suplier_id',
						'$description_id_1',
						'$description_id_2',
						'$description_id_3'
					)"
           	);
           	$query->execute;
           	$query->finish;
		}
		return ($This->last_inserted_id('payment') );

	}

	sub add_total {

		my ( $This,$total_desc_id,$total) = @_; 
		die "$total_desc_id,$total " unless $total_desc_id;
		die "$total_desc_id,$total " unless $total;

		# check if we have an entry for descritpion
	       	my $query    = $This->{Dbh}->prepare(
           	"SELECT total_description_id FROM total	WHERE total_description_id like $total_desc_id"   
		);
        $query->execute;
        my ($desc_id) = $query->fetchrow_array;
        $query->finish;

        if ($desc_id) {
			return $desc_id;
		} else {
         # if no entry make one
			my $query = $This->{Dbh}->prepare(
               	"INSERT INTO total ( total_description_id,total_amount ) values( $total_desc_id,$total)"
           	);
           	$query->execute;
           	$query->finish;
        }
        return ($This->last_inserted_id('total') );
    }

	sub add_description {

		my ( $This,$desc) = @_; 
		my $qdesc = $This->{Dbh}->quote($desc);

		# check if we have an entry for descritpion
       	my $query    = $This->{Dbh}->prepare(
           	"SELECT description_id FROM description	WHERE description_txt like $qdesc"   
		);
        $query->execute;
		my $desc_id = -1;
        ($desc_id) = $query->fetchrow_array;
        $query->finish;

        if ($desc_id) {
			return $desc_id;
		} else {
         # if no entry make one
			my $query = $This->{Dbh}->prepare(
               	"INSERT INTO description ( description_txt ) values( $qdesc)"
           	);
           	$query->execute;
           	$query->finish;
        }
        return ($This->last_inserted_id('description') );
    }

	sub add_suplier {

		my ( $This,$suplier) = @_; 
		my $qsuplier = $This->{Dbh}->quote($suplier);

		# check if we have an entry for suplier
       	my $query    = $This->{Dbh}->prepare(
           	"SELECT suplier_id FROM suplier	WHERE suplier_name=$qsuplier"   
		);
        $query->execute;
		my $suplier_id = -1;
        ($suplier_id) = $query->fetchrow_array;
        $query->finish;

        if ($suplier_id) {
			return $suplier_id;
		} else {
         # if no entry make one
			my $query = $This->{Dbh}->prepare(
               	"INSERT INTO suplier ( suplier_name ) values( $qsuplier)"
           	);
           	$query->execute;
           	$query->finish;
        }
        return ($This->last_inserted_id('suplier') );
    }

	 sub last_inserted_id {
        my $This  = shift;
        my $table = shift;

        my $query =
          $This->{Dbh}->prepare("SELECT LAST_INSERT_ID() FROM $table ");
        $query->execute;
        my ($id) = $query->fetchrow_array;

        $query->finish;

        return $id;

    }

sub get_payment {
        my $This  = shift;
        my $payment_ref = shift;

        my $query =
          $This->{Dbh}->prepare(
		  	"SELECT 
				payment_amount, 
				payment_ref, 
				payment_suplier_id,
				payment_desc_1,
				payment_desc_2,
				payment_desc_3
				FROM payment WHERE payment_id='$payment_ref->{id}'");
        $query->execute;
         (
		$payment_ref->{amount},
		$payment_ref->{'ref'},
		$payment_ref->{suplier_id},
		$payment_ref->{desc_1_id},
		$payment_ref->{desc_2_id},
		$payment_ref->{desc_3_id}
		
		) = $query->fetchrow_array;

        $query->finish;

        #return $description;

    }	

sub select_max {
 	my $This  = shift;
        my $entity = shift;
	my $relation = shift;

        my $query =
          $This->{Dbh}->prepare("select max($entity) from $relation");
        $query->execute;
        my ($amount) = $query->fetchrow_array;

        $query->finish;

        return $amount;




}


sub get_description {

        my $This  = shift;
        my $desc_id = shift;

        my $query =
          $This->{Dbh}->prepare("SELECT  description_txt FROM description WHERE description_id='$desc_id'");
        $query->execute;
        my ($description) = $query->fetchrow_array;

        $query->finish;

        return $description;

    }		
 sub get_suplier {
        my $This  = shift;
        my $suplier_id = shift;

        my $query =
          $This->{Dbh}->prepare("SELECT  suplier_name FROM suplier WHERE suplier_id='$suplier_id'");
        $query->execute;
        my ($suplier_name) = $query->fetchrow_array;

        $query->finish;

        return $suplier_name;

    }	

	sub get_last_id {
		my $This = shift;
  		my $table = shift;
		my $query =
          $This->{Dbh}->prepare("SELECT  count(*) FROM $table");
        $query->execute;
        my ($suplier_cnt) = $query->fetchrow_array;

        $query->finish;	
		return ($suplier_cnt );

	}

	}
1;

