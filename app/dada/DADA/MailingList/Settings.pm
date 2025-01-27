package DADA::MailingList::Settings; 
use strict;
use lib qw(./ ../ ../../ ../../DADA ../perllib); 

use DADA::Config qw(!:DEFAULT); 	
use DADA::App::Guts; 
use DADA::Template::Widgets; 
use Try::Tiny; 
use Carp qw(croak carp); 

my $t = $DADA::Config::DEBUG_TRACE->{DADA_MailingList_Settings};

my $type; 
my $backend; 
my $dbi_obj = undef; 

sub _init  { 
    my $self   = shift; 
	my ($args) = @_; 

	
    if($args->{-new_list} == 1){ 
	
		$self->{name}     = $args->{-list};
		$self->{new_list} = 1;
	}else{ 
		
		if($self->_list_name_check($args->{-list}) == 0) { 
    		croak('BAD List name "' . $args->{-list} . '" ' . $!);
		}
		$self->{new_list} = 0;
	}
}

sub new {
	
	my $class = shift;
	
	my ($args) = @_; 
	
	my $self = {};			
	bless $self, $class;

	if(!exists($args->{-list})){ 
		croak "You MUST pass a list in, -list!"; 
	}
	
	if(!exists($args->{-new_list})){ 
		$args->{-new_list} = 0;
	}
	
	$self->_init($args); 
	$self->_sql_init(); 
	

	return $self;
}




sub _sql_init  { 
	
    my $self = shift; 
    
    $self->{function} = 'settings sql'; # seriously, wha?
    
    $self->{sql_params} = {%DADA::Config::SQL_PARAMS};

	if(!keys %{$self->{sql_params}}){ 
		croak "sql params not filled out?!"; 
	}
	else {
		
	}


#	if(!$dbi_obj){ 
		#warn "We don't have the dbi_obj"; 
		require DADA::App::DBIHandle; 
		$dbi_obj = DADA::App::DBIHandle->new; 
		$self->{dbh} = $dbi_obj->dbh_obj; 
#	}else{ 
#		#warn "We HAVE the dbi_obj!"; 
#		$self->{dbh} = $dbi_obj->dbh_obj; #
#	}
	
}




sub save {
	
    my ( $self, $args ) = @_;

	require Storable; 
	my $orig_settings = Storable::dclone($args->{-settings});
	my $new_settings  = Storable::dclone($args->{-settings});
	
	my $also_save_for = [];
	if(exists($args->{-also_save_for})) {
		$also_save_for = $args->{-also_save_for};
    }
	
	if ( $t == 1 ) {
        require Data::Dumper;
        warn '$new_settings: ' . Data::Dumper::Dumper($new_settings);
    }
    unless ( $self->{new_list} ) {
        if ( exists( $new_settings->{list} ) ) {
            croak "don't pass list to save()!";
        }
    }

    my $d_query =
        'DELETE FROM '
      . $self->{sql_params}->{settings_table}
      . ' where list = ? and setting = ?';
    my $a_query =
      'INSERT INTO ' . $self->{sql_params}->{settings_table} . ' values(?,?,?)';

    warn '$d_query ' . $d_query if $t;
    warn '$a_query ' . $a_query if $t;
    if ( !$self->{RAW_DB_HASH} ) {
        $self->_raw_db_hash;
    }
				
	
	if($self->{new_list} != 1){		
		# some keys need to be encrypted
		for (qw(
			sasl_smtp_password 
			discussion_pop_password
			)) {
			if(exists($new_settings->{$_})){ 
			
				$new_settings->{$_} = strip( $new_settings->{$_} );
			
		        if ( defined($new_settings->{$_}) ) {
				
					require DADA::Security::Password; 
					require DADA::MailingList::Settings; 
					my $local_copy_ls = DADA::MailingList::Settings->new(
						{
							-list => $self->{name}
						}
					);
		            $new_settings->{$_} = DADA::Security::Password::cipher_encrypt(
		                    $local_copy_ls->param('cipher_key'),
		                    $new_settings->{$_}
					);
					undef($local_copy_ls);				
		        }
			}
		}
		#/ some keys need to be encrypted	 
	}

	
	# Encrypts the List Password, if it's passed: 
	if(exists($new_settings->{password})){ 
		if(defined($new_settings->{password})){ 
			require DADA::Security::Password;
			$new_settings->{password} 
				= DADA::Security::Password::encrypt_passwd(
					$new_settings->{password}
				); 
		}
	}
	# /Encrypts the List Password, if it's passed
	
		 
    if ($new_settings) {

        $self->_existence_check($new_settings);

        for my $setting ( keys %$new_settings ) {

            my $sth_d = $self->{dbh}->prepare($d_query);
            $sth_d->execute( $self->{name}, $setting )
              or die "cannot do statement $DBI::errstr\n";
            $sth_d->finish;

            my $sth_a = $self->{dbh}->prepare($a_query);
            $sth_a->execute( $self->{name}, $setting,
                $new_settings->{$setting} )
              or die "cannot do statement $DBI::errstr\n";
            $sth_a->finish;
        }

        # This should give you a brand new copy of the hashref,
        # So when we run the following tests...
        $self->{RAW_DB_HASH} = undef;
        $self->_raw_db_hash;

        if ( $self->{RAW_DB_HASH}->{list} || $self->{new_list} == 1 ) {

            #special cases:
            if ( !defined( $self->{RAW_DB_HASH}->{admin_menu} )
                || $self->{RAW_DB_HASH}->{admin_menu} eq "" )
            {
                require DADA::Template::Widgets::Admin_Menu;
                my $sth_am = $self->{dbh}->prepare($a_query);
                $sth_am->execute( $self->{name}, 'admin_menu',
                    DADA::Template::Widgets::Admin_Menu::create_save_set() )
                  or die "cannot do statement $DBI::errstr\n";

            }

            if ( !defined( $self->{RAW_DB_HASH}->{cipher_key} )
                || $self->{RAW_DB_HASH}->{cipher_key} eq "" )
            {

                require DADA::Security::Password;

                my $new_cipher_key =
                  DADA::Security::Password::make_cipher_key();
                my $sth_ck = $self->{dbh}->prepare($a_query);
                $sth_ck->execute( $self->{name}, 'cipher_key', $new_cipher_key )
                  or die "cannot do statement $DBI::errstr\n";

            }

            #/special cases:
        }
        else {
            carp
"$DADA::Config::PROGRAM_NAME $DADA::Config::VER warning! listshortname isn't defined! list "
              . $self->{function}
              . " db possibly corrupted!"
              unless $self->{new_list};
        }

        $self->{cached_settings} = undef;

        require DADA::App::ScreenCache;
        my $c = DADA::App::ScreenCache->new;
        $c->flush;

        $self->{RAW_DB_HASH} = undef;

		for my $other_list(@$also_save_for){ 
			try {
				my $other_ls = DADA::MailingList::Settings->new({-list => $other_list}); 				
				$other_ls->save({
					-also_save_for => [],
					-settings      => $orig_settings, 
				}); 
			} catch { 
				warn 'problem saving settings for, ' . $other_list . ' because:' . $_; 
			};
		}
        return 1;
    }
    return 1;
}




sub perhapsCorrupted { 
	my $self = shift; 
	return 1; 
}







sub _raw_db_hash { 

	my $self     = shift; 
	my $settings = {};

	# This is sincerely stupid. 
	
	# um, caching? 
	return 
	    if $self->{RAW_DB_HASH}; 
	    
	
	# Need $self->{RAW_DB_HASH} as a hash ref of settings - easy enough...
	
	my $query = 'SELECT setting, value FROM ' . $self->{sql_params}->{settings_table} .' WHERE list = ?';
	
	my $sth = $self->{dbh}->prepare($query); 
	   $sth->execute($self->{name})
            or croak "cannot do statement! (at: _raw_db_hash) $DBI::errstr\n";   

	
	while((my @stuff) = $sth->fetchrow_array){		
		$settings->{$stuff[0]} = $stuff[1]; 
	}
	
	$sth->finish; 

	$self->{RAW_DB_HASH} = $settings; 	
	

}




sub _list_name_check { 

	my ($self, $n) = @_; 
		$n = $self->_trim($n);
	return 0 if !$n; 
	return 0 if $self->_list_exists($n) == 0;  
	$self->{name} = $n;
	return 1; 
}




sub _list_exists { 
	my ($self, $n)  = @_; 
	if(!defined($dbi_obj)){ 
	#	croak "Why?"; 
	}
	return DADA::App::Guts::check_if_list_exists(
				-List       => $n, 
	);
}







sub removeAllBackups {}
sub uses_backupDirs {	return 0;	}


sub get { 
	
	my $self = shift; 
	my %args = (
	    -Format => "raw", 
	    -dotted => 0, 
	    @_
	); 

	$self->_raw_db_hash;
	
	my $ls                   = $self->{RAW_DB_HASH}; 
	
	$ls = $self->post_process_get($ls, {%args});
	
	if($args{-dotted} == 1){ 
        my $new_ls = {}; 
        while (my ($k, $v) = each(%$ls)){
            $new_ls->{'list_settings.' . $k} = $v; 
        }
        return $new_ls; 

	}
	else { 
			
	    return $ls; 
    }
}




sub post_process_get {

    my $self = shift;
    my $li   = shift;
    my $args = shift;

    if(! exists($args->{-all_settings})){ 
        $args->{-all_settings} = 0; 
    }
   #  warn '$args->{-all_settings} ' . $args->{-all_settings}; 
    
    carp "$DADA::Config::PROGRAM_NAME $DADA::Config::VER warning! List "
      . $self->{function}
      . " db empty!  List setting DB Possibly corrupted!"
      unless keys %$li;

    carp
"$DADA::Config::PROGRAM_NAME $DADA::Config::VER warning! no listshortname saved in list "
      . $self->{function}
      . " db! List "
      . $self->{function}
      . " DB Possibly corrupted!"
      if !$li->{list};

    carp "listshortname in db, '"
      . $self->{name}
      . "' does not match saved list shortname: '"
      . $li->{list} . "'"
      if $self->{name} ne $li->{list};

    if ( $args->{-Format} ne 'unmunged' ) {
        $li->{charset_value} = $self->_munge_charset($li);
        $li = $self->_munge_for_deprecated($li);

        if ( !exists( $li->{list_info} ) ) {
            $li->{list_info} = $li->{info};
        }
		
		# This is backwards compat, to move this setting to a new one, but 
		# only if it was set a certain way: 
        if ( !exists( $li->{completing_the_unsubscription} ) ) {
            if($li->{one_click_unsubscribe} == 1){ 
				$li->{completing_the_unsubscription} = 'one_click_unsubscribe_no_confirm_screen';
			}
        }		
		# Else, the value in $LIST_SETUP_DEFAULTS will be used. 

        # If we don't need to load, DADA::Security::Password, let's not.

        my $d_password_check = 0;
        for ( 'sasl_smtp_password',
            'discussion_pop_password' )
        {
            if (   exists( $DADA::Config::LIST_SETUP_DEFAULTS{$_} )
                || exists( $DADA::Config::LIST_SETUP_OVERRIDES{$_} ) )
            {
                $d_password_check = 1;
                require DADA::Security::Password;
                last;
            }
        }
        
        for ( 'sasl_smtp_password',
            'discussion_pop_password' )
        {

            if ( $DADA::Config::LIST_SETUP_OVERRIDES{$_} ) {

                $self->{orig}->{LIST_SETUP_OVERRIDES}->{$_} =
                  $DADA::Config::LIST_SETUP_OVERRIDES{$_};
                $DADA::Config::LIST_SETUP_OVERRIDES{$_} =
                  DADA::Security::Password::cipher_encrypt( $li->{cipher_key},
                    $DADA::Config::LIST_SETUP_OVERRIDES{$_} );
                next;
            }

            if ( $DADA::Config::LIST_SETUP_DEFAULTS{$_} ) {
                if ( !$li->{$_} ) {
                    $self->{orig}->{LIST_SETUP_DEFAULTS}->{$_} =
                      $DADA::Config::LIST_SETUP_DEFAULTS{$_};
                    $DADA::Config::LIST_SETUP_DEFAULTS{$_} =
                      DADA::Security::Password::cipher_encrypt(
                        $li->{cipher_key},
                        $DADA::Config::LIST_SETUP_DEFAULTS{$_} );
                }
            }
        }

        for ( keys %$li ) {
            if ( exists( $li->{$_} ) ) {
                if ( !defined( $li->{$_} ) ) {
                    delete( $li->{$_} );
                }
            }
        }

        if($args->{-all_settings} == 1) { 
            my $start_time = time; 
            my $html_settings          = $self->_html_settings;
            
            for ( keys %DADA::Config::LIST_SETUP_DEFAULTS ) {
                if ( !exists( $li->{$_} ) || length( $li->{$_} ) == 0 ) {
                 	if(exists($html_settings->{$_})) {
                        $li->{$_} = $self->_fill_in_html_settings($_);                      
                    }
                    else { 
                        $li->{$_} = $DADA::Config::LIST_SETUP_DEFAULTS{$_};
                    }
                }
            }
        }
        else { 
            for ( keys %DADA::Config::LIST_SETUP_DEFAULTS ) {
                if ( !exists( $li->{$_} ) || length( $li->{$_} ) == 0 ) {
                    $li->{$_} = $DADA::Config::LIST_SETUP_DEFAULTS{$_};               
                }
            }
        }
		# This says basically, make sure the list subscription quota is <= the global list sub quota. 
        $DADA::Config::SUBSCRIPTION_QUOTA ||= undef;

        if (   $DADA::Config::SUBSCRIPTION_QUOTA
            && $li->{subscription_quota}
            && ( $li->{subscription_quota} > $DADA::Config::SUBSCRIPTION_QUOTA )
          )
        {
            $li->{subscription_quota} = $DADA::Config::SUBSCRIPTION_QUOTA;
        }



        for ( 'sasl_smtp_password',
            'discussion_pop_password' )
        {
            if ( $DADA::Config::LIST_SETUP_OVERRIDES{$_} ) {
                $DADA::Config::LIST_SETUP_OVERRIDES{$_} =
                  $self->{orig}->{LIST_SETUP_OVERRIDES}->{$_};
            }

            if ( $DADA::Config::LIST_SETUP_DEFAULTS{$_} ) {
                $DADA::Config::LIST_SETUP_DEFAULTS{$_} =
                  $self->{orig}->{LIST_SETUP_DEFAULTS}->{$_};
            }
        }
    }

    # And then, there's this:
    # DEV: Strange, that it's been left out? Did it get removed?
    for ( keys %DADA::Config::LIST_SETUP_OVERRIDES ) {
        next if $_ eq 'sasl_smtp_password';
        next if $_ eq 'discussion_pop_password';
        $li->{$_} = $DADA::Config::LIST_SETUP_OVERRIDES{$_};
    }

    if ( !exists( $li->{admin_email} ) ) {
        $li->{admin_email} = $li->{list_owner_email};
    }
    elsif ( $li->{admin_email} eq undef ) {
        $li->{admin_email} = $li->{list_owner_email};
    }

    if ( $DADA::Config::ENFORCE_CLOSED_LOOP_OPT_IN != 1 ) {
		# ... 
    }
	else { 
	    $li->{enable_closed_loop_opt_in}               = 1;
        $li->{enable_mass_subscribe}                   = 0;
        $li->{enable_mass_subscribe_only_w_root_login} = 0; 
		$li->{allow_admin_to_subscribe_blacklisted}    = 0; 
	}
    return $li;

}




sub params { 
	
	my $self = shift; 
	
	if(keys %{$self->{cached_settings}}){ 
		#... 
	}
	else { 
		$self->{cached_settings} = $self->get; 
	}
	
	return $self->{cached_settings};
	
}



sub param { 
	
	my $self  = shift; 
	my $name  = shift  || undef; 
	my $value = shift;
	
	if(!defined($name)){ 
		croak "You MUST pass a name as the first argument!"; 
	}
	
	if(!exists($DADA::Config::LIST_SETUP_DEFAULTS{$name})){ 
		croak "Cannot call param() on unknown setting, '$name'"; 
	}
	
	
	if(keys %{$self->{cached_settings}}){ 
		warn "$name is cached, using cached stuff." if $t;  
	}
	else { 
		warn "$name is NOT cached, fetching new stuff" if $t; 
		$self->{cached_settings} = $self->get; 
	}
	
	if(defined($value)){  
		$self->save({-settings =>{$name => $value}});
		$self->{cached_settings} = {};
		return $value; # or... what should I return?
	}
	else { 
	
		if(exists($self->{cached_settings}->{$name}) && defined($self->{cached_settings}->{$name})) { 
		    warn 'setting is cached and defined.' if $t; 
			return $self->{cached_settings}->{$name};
		}
		elsif($self->_html_settings()->{$name}){ 
		    warn 'setting isa _html_settings. ' if $t; 
		    
            if($self->{cached_settings}->{_cached_all_settings} == 1) {
                warn 'all settings are cached, but the saved value seems to be blank!' if $t;  
                # Guess it's... blank. 
                return ''; 
		    }
		    else { 
		        warn 'removing cache' if $t; 
                $self->{cached_settings} = {}; 
                warn 'creating cache, with all vals' if $t;     
                $self->{cached_settings} = $self->get(-all_settings => 1); 
                warn 'setting that cache has all vals' if $t; 
                $self->{_cached_all_settings} = 1; 
                warn 'returning val for, ' . $name if $t; 
                return $self->{cached_settings}->{$name}; 
		    }
		}
		elsif(! exists($self->{cached_settings}->{$name}) ) { 
		    carp "Cannot fill in value for, '$name'";
			return undef; 
		}
		else { 
		    return ''; 
		}
	}
}

sub _html_settings {
    return {
        html_confirmation_message         => 1,
        html_subscribed_message           => 1,
        html_unsubscribed_message         => 1,
        html_subscription_request_message => 1,
    };
}

sub _fill_in_html_settings { 
    my $self = shift;
	my $name = shift; 
	
	my $message_settings = { 
        html_confirmation_message         => 'confirmation.tmpl',
        html_subscription_request_message => 'subscription_request.tmpl',	    
        html_subscribed_message           => 'subscribed.tmpl',
        html_unsubscribed_message         => 'unsubscribed.tmpl',
	}; 
	
    if(exists($message_settings->{$name})) { 
        my $raw_screen = DADA::Template::Widgets::_raw_screen( 
			{ 
				-screen => 'list/' . $message_settings->{$name} 
			} 
		);
        return $raw_screen; 
	}
	else { 
		return undef; 
	}
}



sub save_w_params {

    my $self      = shift;
    my ($args)    = @_;
    my $associate = undef;
    my $settings  = {};
	
	# use Data::Dumper; 
	# warn Dumper($args); 

    if ( !exists( $args->{-associate} ) ) {
        croak(
'you\'ll need to pass a Perl object with a compatible, param() method in "-associate"'
        );
    }
    if ( !exists( $args->{-settings} ) ) {
        croak(
'you\'ll need to pass what you want to save in the, "-settings" param as a hashref'
        );
    }

    $associate = $args->{-associate};
    $settings  = $args->{-settings};

    my $saved_settings = {};

    for my $setting (keys %$settings) {

        # is it here?
        if ( defined( $associate->param($setting) ) ) {
			if($associate->param($setting) ne '') { 
            	$saved_settings->{$setting} = $associate->param($setting);
			}
			else { 
            	$saved_settings->{$setting} = $settings->{$setting};				
			}
        }
        else {

            # fallback
			# not checking for defined-ness here, since the value could be, "undef"
            $saved_settings->{$setting} = $settings->{$setting};
        }

        # This is probably a good place to check that the variable is actually
        # a valid value.
    }

#	use Data::Dumper; 
#	croak Data::Dumper::Dumper($saved_settings); 

	delete($args->{-associate});
	$args->{-settings} = $saved_settings; 
    return $self->save($args);
	
}

sub also_save_for_list { 
	my $self = shift; 
	my $q    = shift;
	
	my $also_save_for      = $q->param("also_save_for") // undef; 
	my @also_save_for_list = ();
	if($also_save_for) {
		@also_save_for_list = split(',', $q->param("also_save_for_list"));
	}
	if(scalar @also_save_for_list > 0){ 
		return [@also_save_for_list];
	}
	else { 
		return []; 
	}
	
}






sub _existence_check { 

    my $self = shift; 
    my $li   = shift; 
    for(keys %$li){ 
        if(!exists($DADA::Config::LIST_SETUP_DEFAULTS{$_})){         
            croak("Attempt to save a unregistered setting: '$_'"); 
        }
    }
}




sub _munge_charset { 
	my ($self, $li) = @_;
	
	
	if(!exists($li->{charset})){ 
	   $li->{charset} =  $DADA::Config::LIST_SETUP_DEFAULTS{charset};
	    
	}
	
	my $charset_info = $li->{charset};
	my @labeled_charsets = split(/\t/, $charset_info);	
	return $labeled_charsets[$#labeled_charsets];      

}



sub _munge_for_deprecated { 
	
	my ($self, $li) = @_; 
	$li->{list_owner_email} ||= $li->{mojo_email};
#    $li->{admin_email}      ||= $li->{list_owner_email}; 
  
    $li->{privacy_policy}   ||= $li->{private_policy};
  
	#we're talkin' way back here..
	
	if(!exists($li->{list_name})){ 
		$li->{list_name} = $li->{list}; 
		$li->{list_name} =~ s/_/ /g;
	}
	
	return $li; 
}




sub _trim { 
	my ($self, $s) = @_;
	return DADA::App::Guts::strip($s);
}



sub _dd_freeze {
    my $self = shift;
    my $data = shift;

    require Data::Dumper;
    my $d = new Data::Dumper( [$data], ["D"] );
    $d->Indent(0);
    $d->Purity(1);
    $d->Useqq(0);
    $d->Deepcopy(0);
    $d->Quotekeys(1);
    $d->Terse(0);

    # ;$D added to make certain we get our data structure back when we thaw
    return $d->Dump() . ';$D';

}

sub _dd_thaw {

    my $self = shift;
    my $data = shift;

    # To make -T happy
    my ($safe_string) =  $data =~ m/^(.*)$/s;
    $safe_string = 'my ' . $safe_string; 
    my $rv = eval($safe_string);
    if ($@) {
        croak "couldn't thaw data! - $@\n" . $data;
    }
    return $rv;
}







1; 

=head1 NAME

DADA::MailingList::Subscribers - API for the Dada Mailing List Settings

=head1 SYNOPSIS

 # Import
 use DADA::MailingList::Settings; 
 
 # Create a new object
  my $ls = DADA::MailingList::Settings->new(
           		{ 
					-list => $list, 
				}
			);
 
	# A hashref of all settings
	my $li = $ls->get; 
	print $li->{list_name}; 
 	
 
 
	# Save a setting
	$ls->save({
		-settings => {
			list_name => "my list", 
		}
	});
 
 # save a setting, from a CGI parameter, with a fallback variable: 
 $ls->save_w_params(
	-associate => $q, # our CGI object
	-settings  => { 
		list_name => 'My List', 
	}
 ); 
 
 
  # get one setting
  print $ls->param('list_name'); 
 
 
 
 #save one setting: 
 $ls->param('list_name', "My List"); 
  
 
 # Another way to get all settings
 my $li = $ls->params; 


=head1 DESCRIPTION

This module represents the API for Dada Mail's List Settings. Each DADA::MailingList::Settings object represents ONE list. 

Dada Mail's list settings are basically the saved values and preferences that 
make up the, "what" of your Dada Mail list. The settings hold things like the name of your list, the description, as well as things like email sending options.  

=head2 Mailing List Settings Model

Settings are saved in a key/value pair, as originally, the backend for all this was a dn file. This module basically manipulates that key/value hash. Very simple. 

=head2 Default Values of List Settings

The default value of B<ALL> list settings are saved currently in the I<Config.pm> file, in the variable, C<%LIST_SETUP_DEFAULTS>

This module will make sure you will not attempt to save an unknown list setting in the C<save> method, as well when calling C<param> with either one or two arguments. 

The error will be fatal. This may seem rash, but many bugs surface just because of trying to use a list setting that does not actually exist. 

The C<get> method is NOT guaranteed to give back valid list settings! This is a known issue and may be fixed later, after backwards-compatibility problems are assessed. 

=head1 Public Methods

Below are the list of I<Public> methods that we recommend using when manipulating the  Dada Mail List Settings: 

=head2 Initializing

=head2 new

 my $ls = DADA::MailingList::Settings->new({-list => 'mylist'}); 

C<new> requires you to pass a B<listshortname> in, C<-list>. If you don't, your script will die. 

A C<DADA::MailingList::Settings> object will be returned. 

=head2 Getting/Setting Mailing List Paramaters

=head2 get

 my $li = $ls->get; 

There are no public parameters that we suggest passing to this method. 

This method returns a hashref that contains each and every key/value pair of settings associated with the mailing list you're working with.

This method will grab a fresh copy of the list settings from whatever backend is being used. Because of this, we suggest that instead of using this method, you use the, C<param> or C<params> method, which has caching of this information.  

=head3 Diagnostics

None, really. 

=head2 save

 $ls->save({-settings => {list_name => 'my new list name'}}); 

C<save> accepts a hashref as a parameter. The hashref should contain key/value pairs of list settings you'd like to change. All key/values passed will re-write any options saved. There is no validation of the information you passed. 

DO NOT pass, I<list> as one of the key/value pairs. The method will return an error. 

This method is most convenient when you have many list settings you'd like saved at one time. See the, C<param> method if all you want to do is save one list setting parameter. 

Returns B<1> on success. 


=head2 save_w_params

 $ls->save_w_params(
	-associate => $q, # our CGI object
	-settings  => { 
		list_name => 'My List', 
	}
 ); 

C<save_w_params> allows you to save list settings that are passed in a compatible Perl object (one that has a C<param> method, similar to CGI.pm's)

C<save_w_params> also allows you to pass a fallback value of the list settings you want to save. 

C<-associate> should hold a Perl Object with the compatable, C<param> method (like CGI.pm's C<param> method. B<required> 

C<-settings> should hold a hashref of the fallback values for each list setting you want to save. 

Returns, C<1> on success. 

=head3 Diagnostics

=over

=item * Attempt to save a unregistered setting - 

The actual settings you attempt to save have to actually exist. Make sure the names (keys) of your the list settings you're attempting to pass are valid. 


=back


=head2 param

 # Get a Value
 $ls->param('list_name'); 
 
 # Save a Value
 $ls->param('list_name', 'my new list name'); 

C<param> can be used to get and save  a list setting parameter. 

Call C<param> with one argument to receive the value of the name of the setting you're passing. 

Call C<param> with two arguments - the first being the name of the setting, the second being the value you'd like to save. 

C<param> is something of a wrapper around the C<get> method, but we suggest using C<param> over, C<get> as, C<param> checks the validity of the list setting B<name> that you pass, as well as caching information you've already fetched from the backend.

=head3 Diagnostics

=over

=item * You MUST pass a name as the first argument!

You cannot call, C<param> without an argument. That first argument needs to be the name of the list setting you want to get/set. 

=item * Cannot call param() on unknown setting.

If you do call C<param> with 2 arguments, the first argument has to be the name of a setting tha actual exists. 

=back

For the two argument version of calling this method, also see the, I<Diagnostics> section of the, C<save> method. 

=head2 params

	my $li = $ls->params;

Takes no arguments. 

Returns the exact same thing as the, C<get> method, except does caching of any information fetched from the backend. Because of this, it's suggested that you use C<params>, instead of, C<get> whenever you can. 

=head2 A note about param and params

The name, C<param> and, C<params> is taken from the CGI.pm module: 

Many different modules support passing parameter values to their own methods, as a sort of shortcut. We had this in mind, but we haven't used or tested how compatible this idea is. When and if we do, we'll update the documentation to reflect this. 

=head1 BUGS AND LIMITATIONS

=head1 COPYRIGHT 

Copyright (c) 1999 - 2023 Justin Simoni All rights reserved. 

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, 
Boston, MA  02111-1307, USA.

=cut 
