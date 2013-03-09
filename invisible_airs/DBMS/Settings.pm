# we are going to create a myql table

# we need some special instructions to help us correct our programe  
#use strict;

package Settings;
require Exporter;
@ISA     = qw(Exporter);

@EXPORT =
  qw (
    %MYSQL_TABLES 
   	MYSQL_PASS MYSQL_DB MYSQL_USER
 	MYSQL_PRINT_ERROR MYSQL_RAISE_ERROR
);

# USED for 'search' 'admin' on web interface:

use constant MYUSER   => 'xxxxx';
use constant MYDATABASE => 'BRISTOL_EXPENSES';
<<<<<<< HEAD
use constant MYPASS => 'xxxxxx'; 
=======
use constant MYPASS => 'xxxxx'; 
>>>>>>> 809f1acaffbe09d5a3ca724ecec9f5ee41534792

use constant {

    MYSQL_PASS        => MYPASS,
    MYSQL_DB          => 'dbi:mysql:'.MYDATABASE.';mysql_read_default_file=/etc/mysql/my.cnf',
    MYSQL_USER        => MYUSER,
    MYSQL_PRINT_ERROR => 1,
    MYSQL_RAISE_ERROR => 1,

};

# Now we will define our table
# varible types char integer

%MYSQL_TABLES = (
    payment => 'create table payment  (
			payment_id smallint  not null AUTO_INCREMENT,
			payment_amount FLOAT(10,4) not null,
			payment_ref char(150),
			payment_suplier_id smallint unsigned not null,
			payment_desc_1 smallint unsigned not null,
			payment_desc_2 smallint unsigned not null,
			payment_desc_3 smallint unsigned not null,
			index (payment_id)
		) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',
	
	suplier	 => 'create table suplier  (
			suplier_id smallint  not null AUTO_INCREMENT, 
			suplier_name char(150) not null,
			UNIQUE (suplier_name),
			FULLTEXT (suplier_name),
			index (suplier_id)
		) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',
	description	 => 'create table description  (
			description_id smallint  not null AUTO_INCREMENT, 
			description_txt char(150) not null,
			UNIQUE (description_txt),
			FULLTEXT (description_txt),
			index (description_id)
		) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',		
	total	 => 'create table total  (
			total_id smallint  not null AUTO_INCREMENT, 
			total_description_id smallint not null,
			total_amount int not null,
			UNIQUE (total_description_id),
			index (total_id)
		) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',	


);
