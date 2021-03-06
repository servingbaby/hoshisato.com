#!/usr/bin/perl

eval "use diagnostics; 1"  or die("\n[ FATAL ] Could not load the Diagnostics module.\n\nTry:\n\n      sudo apt-get install perl-modules\n\nThen try running this script again.\n\n");
use Getopt::Long qw(:config no_ignore_case bundling pass_through);
use POSIX;
use strict;

############################################################################################################
##       ___                     __        ___      ____            __    __                              ##
##      /   |  ____  ____ ______/ /_  ___ |__ \    / __ )__  ______/ /___/ /_  __                         ##
##     / /| | / __ \/ __ `/ ___/ __ \/ _ \__/ /   / __  / / / / __  / __  / / / /                         ##
##    / ___ |/ /_/ / /_/ / /__/ / / /  __/ __/   / /_/ / /_/ / /_/ / /_/ / /_/ /                          ##
##   /_/  |_/ .___/\__,_/\___/_/ /_/\___/____/  /_____/\__,_/\__,_/\__,_/\__, /    ...new & improved!!!   ##
##         /_/ apache2buddy.pl                                          /____/                            ##
##                                                                                                        ##
############################################################################################################
# author: richard forth
# version: 0.1
# description: apache2buddy, a fork of apachebuddy that caters for apache2, obviously.
#
#            http://apache2buddy.pl/installation
#            http://apache2buddy.pl/changelog
#
############################################################################################################
#                                           D I S C L A I M E R  
############################################################################################################
#
#  PLEASE NOTE THAT THIS IS DESIGNED AS A REPORTING TOOL ONLY
#  ==============================================================
#
#  There are no plans to make this script automatically change any apache configuration settings, as this 
#  could prove disasterous in production environments.
#
#  Needless to say this script comes without any warranty or fitness for a particular use and you run it
#  at your own risk. 
#
#  * * * * USE THIS SCRIPT AT YOUR OWN RISK * * * * 
#
#  Every care has been taken to make sure this does nothing bad, it should only be reading configuration
#  files, and doing a bit of maths, and printing out a shiny report.
#
#  Nothing more nothing less. 
#
#  Please pay special attention and review the source code before deciding whether you should run this on 
#  your systems. 
#
#  I am not responsible for any damage caused to your data, systems or hardware, loss of business, your 
#  marriage breaking down, getting your car or house reposessed, or ending up in prison or losing your job
#  and drug habits developing , insolvency, bankruptcy, personal hygiene issues, disease  or death that may 
#  stem as  a direct result of running this script.
#
#  YOU HAVE BEEN WARNED!
#
#
###########################################################################################################
#
#  Note:
#
#  If you really want to read all of the source code, I suggest that you start from the comment:
#
#  ########################
#  # BEGIN MAIN EXECUTION #
#  ########################
#
#  Because everything from this point to that, is just a bunch of subroutines that the script needs in order
#  to be able to run, and it won't flow or make any sense until you start from the "start".
#
##########################################################################################################
# Variable to hold the date / time stamp that this file was last changed
#
our $date_last_modified = "Sunday, October 18th, 2015 @ 15:18";

## print usage
sub usage {
	our $usage_output = <<'END_USAGE';

Usage: apache2buddy.pl [OPTIONS]
If no options are specified, the basic tests will be run.

	-h, --help		Print this help message
	-p, --port=PORT		Specify an alternate port to check (default: 80)
	-v, --verbose		Use verbose output (this is very noisy, only useful for debugging)
	-n, --nocolor		Use default terminal color, dont try to be all fancy! 
	-H, --noheader		Do not show header title bar.
	-N, --noinfo		Do not show informational messages.
	    --nonews		Do not show news messages.	
	-K, --no-ok		Do not show OK messages.
	-W, --nowarn		Do not show warning messages.
	-L, --light-term	Show colours for a light background terminal.
	-r, --report		Implies -HNWK  --nonews or --noinfo --nowarn --no-ok --noheader --nonews

More information (1990's style info pages):

		http://apache2buddy.pl/about
		http://apache2buddy.pl/installation
		http://apache2buddy.pl/usage
		http://apache2buddy.pl/examples
		http://apache2buddy.pl/known_bugs
		http://apache2buddy.pl/feature_requests
		http://apache2buddy.pl/project_roadmap
		http://apache2buddy.pl/changelog

END_USAGE

	print $usage_output;
}
########################
# GATHER CMD LINE ARGS #
########################

# if help is not asked for, we do not give it
my $help = "";

# by default, assume the terminal has dark background, eg putty 
my $LIGHTBG = 0;

# if no port is specified, we default to 80
my $port = 80;

# by default, do not use verbose output
our $VERBOSE = "";

# by default, use color output
our $NOCOLOR = 0;

# by default, show news messages 
our $NONEWS = 0;

# by default, show informational messages 
our $NOINFO = 0;

# by default, show ok messages 
our $NOOK = 0;

# by default, show warnings 
our $NOWARN = 0;

# by default, show full output 
our $REPORT = 0;

# by default, show header 
our $NOHEADER = 0;

# grab the command line arguments
GetOptions(
	'help|h' => \$help,
	'port|p:i' => \$port,
	'verbose|v' => \$VERBOSE,
	'nocolor|n' => \$main::NOCOLOR,
	'noinfo|N' => \$NOINFO,
	'nowarn|W' => \$NOWARN,
	'report|r' => \$REPORT,
	'light-term|L' => \$LIGHTBG,
	'no-ok|K' => \$NOOK,
	'noheader|H' => \$NOHEADER,
	'nonews' => \$NONEWS
);

# check for invalid options, bail if we find any and print the usage output
if ( @ARGV > 0 ) {
	print "Invalid option: ";
	foreach (@ARGV) {
		print $_." ";
	}
	print "\n";
	usage;
	exit;
}

if ( $REPORT ) {
	$NOHEADER = 1;
	$NOINFO = 1;
	$NONEWS = 1;
	$NOWARN = 1;
	$NOOK = 1;
}

# Declare constants such as ANSI COLOR schemes.
# TO SAVE CODE and thus also massively cut down on the file size, Ive decided to handle NOCOLOR here, 
# instead of on every single line where I need to print something. it seems much simpler and cleaner
# to print an empty string rather than an escape sequence, rather than doubling up on print() statements.
our $RED;
our $GREEN;
our $YELLOW;
our $BLUE;
our $PURPLE;
our $CYAN;
our $ENDC;
our $BOLD;
our $UNDERLINE;
if ( ! $NOCOLOR ) {
	if ( ! $LIGHTBG ) {
		$RED = "\033[91m";
		$GREEN = "\033[92m"; # Like a light green color, not good for light terminals, but perfect for dark, eg PuTTY, terminals.
		$YELLOW = "\033[93m"; # Like a yellow color, not good for light terminals, but perfect for dark, eg PuTTY, terminals.
		$BLUE = "\033[94m";
		$PURPLE = "\033[95m"; # technically its Magento... 
		$CYAN = "\033[96m"; # Like a light blue color, not good for light terminals, but perfect for dark, eg PuTTY, terminals.
	} else {
		$RED = "\033[1m"; # bold all the things!
		$GREEN = "\033[1m"; # bold all the things!
		$YELLOW = "\033[1m"; # bold all the things!
		$BLUE = "\033[1m"; # bold all the things!
		$PURPLE = "\033[1m"; # bold all the things!
		$CYAN = "\033[1m";  # bold all the things!
	}
	$ENDC = "\033[0m"; # reset the terminal color
	$BOLD = "\033[1m"; # what it says on the tin, you can double up eg make a bold red: ${BOLD}${RED}Something${ENDC}
	$UNDERLINE = "\033[4m"; # again you can double this one up.
} else {
	$RED = ""; # SUPPRESS COLORS
	$GREEN = ""; # SUPPRESS COLORS
	$YELLOW = ""; # SUPPRESS COLORS
	$BLUE = ""; # SUPPRESS COLORS
	$PURPLE = ""; # SUPPRESS COLORS
	$CYAN = ""; # SUPPRESS COLORS
	$ENDC = ""; # SUPPRESS COLORS
	$UNDERLINE = ""; # SUPPRESS COLORS
	$BOLD = ""; # SUPPRESS COLORS
	$UNDERLINE = ""; # SUPPRESS COLORS
}

# here we're going to build a list of the files included by the Apache 
# configuration
sub build_list_of_files {
	my ($base_apache_config,$apache_root) = @_;

	# these to arrays will contain lists of Apache configuration files
	# this is going to be the ultimate list of files that will be parsed 
	# searching for arguments
	my @master_list;
	# this will be a "scratch" space to store a list of files that 
	# currently need to be searched for more "include" lines
	my @find_includes_in;

	# put the main configuration file into the list of files we're going
	# to include
	push(@master_list,$base_apache_config);

	# put the main configuratino file into the list of files we need to 
	# search for include lines
	push(@find_includes_in,$base_apache_config);
	
	#get the Include lines from the main apache config
	@master_list = find_included_files(\@master_list,\@find_includes_in,$apache_root);
}

# here we're going to build an array holding the content of all of the 
# available configuration files
sub build_config_array {
	my ($base_apache_config,$apache_root) = @_;

	# these to arrays will contain lists of Apache configuration files
	# this is going to be the ultimate list of files that will be parsed 
	# searching for arguments
	my @master_list;

	# this will be a "scratch" space to store a list of files that 
	# currently need to be searched for more "include" lines
	my @find_includes_in;

	# put the main configuration file into the list of files we're going
	# to include
	push(@master_list,$base_apache_config);

	# put the main configuratino file into the list of files we need to 
	# search for include lines
	push(@find_includes_in,$base_apache_config);

	#get the Include lines from the main apache config
	@master_list = find_included_files(\@master_list,\@find_includes_in,$apache_root);
}

# this will find all of the files that need to be included
sub find_included_files {
	my ($master_list, $find_includes_in, $apache_root) = @_; 

	# get the number of elements in the array
	my $count = @$find_includes_in;

	# this array will eventually hold the entire apache configuration
	my @master_config_array;

	# while there are still entries in this array, keep processing
	while ( $count > 0 ) {
		my $file = $$find_includes_in[0];
		
		print "VERBOSE: Processing ".$file."\n" if $main::VERBOSE;

		if(-d $file && $file !~ /\*$/) {
			print "VERBOSE: Adding glob to ".$file.", is a directory\n" if $main::VERBOSE;
			$file .= "/" if($file !~ /\/$/);
			$file .= "*";
		}

		# open the file
		open(FILE,$file) || die("Unable to open file: ".$file."\n");
		
		# push the file into an array
		my @file = <FILE>;

		# put the file in the master configuration array
		push(@master_config_array,@file);

		# close the file
		close(FILE);

		# search the file for includes
		foreach (@file) {
			
			# this will be used to store a list of any new include
			# lines found
			# my @new_includes; 

			# if the line looks like an include, then we want to examine it
			if ( $_ =~ m/^\s*include\s+/i ) {
				# grab the included file name or file glob
				$_ =~ s/\s*include\s+(.+)\s*/$1/i;

				# strip out any quoting
				$_ =~ s/['"]+//g;

				# prepend the Apache root for files or
				# globs that are relative
				if ( $_ !~ m/^\// ) {
					$_ = $apache_root."/".$_;
				}

				# check for file globbing
				if(-d $_ && $_ !~ /\*$/) {
					print "VERBOSE: Adding glob to ".$_.", is a directory\n" if $main::VERBOSE;
					$_ .= "/" if($_ !~ /\/$/);
					$_ .= "*";
				}

				if ( $_ =~ m/.*\*.*/ ) {
					my $glob = $_;
					my @include_files;
					chomp($glob);

					# if the include is a file glob,
					# expand it and add the files
					# to the list
					my @new_includes = expand_included_files(\@include_files, $glob, $apache_root);
					push(@$master_list,@new_includes);
					push(@$find_includes_in,@new_includes);
				}
				else {
					# if it is not a glob, push the 
					# line into the configuration 
					# array
					push(@$master_list,$_);
					push(@$find_includes_in,$_);
				}
			}
			# This extra bit of code is required for apache 2.4's new directive "IncludeOptional"
			if ( $_ =~ m/^\s*includeoptional\s+/i ) {
				# grab the included file name or file glob
				$_ =~ s/\s*includeoptional\s+(.+)\s*/$1/i;

				# strip out any quoting
				$_ =~ s/['"]+//g;

				# prepend the Apache root for files or
				# globs that are relative
				if ( $_ !~ m/^\// ) {
					$_ = $apache_root."/".$_;
				}

				# check for file globbing
				if(-d $_ && $_ !~ /\*$/) {
					print "VERBOSE: Adding glob to ".$_.", is a directory\n" if $main::VERBOSE;
					$_ .= "/" if($_ !~ /\/$/);
					$_ .= "*";
				}

				if ( $_ =~ m/.*\*.*/ ) {
					my $glob = $_;
					my @include_files;
					chomp($glob);

					# if the include is a file glob,
					# expand it and add the files
					# to the list
					my @new_includes = expand_included_files(\@include_files, $glob, $apache_root);
					push(@$master_list,@new_includes);
					push(@$find_includes_in,@new_includes);
				}
				else {
					# if it is not a glob, push the 
					# line into the configuration 
					# array
					push(@$master_list,$_);
					push(@$find_includes_in,$_);
				}
			}
		}
		# trim the first entry off the array now that we have 
		# processed it
		shift(@$find_includes_in);

		# get the new count of files left to look at
		$count = @$find_includes_in;
	}

	# return the config array with the included files attached
	return @master_config_array;
}

# this will expand a glob into a list of individual files
sub expand_included_files {
	my ($include_files, $glob, $apache_root) = @_;

	# use a call to ls to get a list of the files from the glob
	my @files = `ls $glob 2> /dev/null`;

	# add the files from the glob to the array we're going to pass back
	foreach(@files) {
		chomp($_);
		push(@$include_files,$_);
		print "VERBOSE: Adding ".$_." to list of files for processing\n" if $main::VERBOSE;
	}

	# return the include_files array with the files from the glob attached
	return @$include_files;
}

# search the configuration array for a defined value that is not inside of a 
# virtual host
sub find_master_value {
	my ($config_array, $model, $config_element) = @_;

	# store our results in an array
	my @results;

	# used to control whether or not we are currently ignoring elements 
	# while searching the array
	my $ignore = 0;

	my $ignore_by_model = 0;
	my $ifmodule_count = 0;

	# apache has two available models - prefork and worker. only one can be
	# in use at a time. we have already determined which model is being 
	# used
	my $ignore_model1;
	my $ignore_model2;
	
	if ( $model =~ m/.*worker.*/i ) {
		$ignore_model1 = "prefork";
		$ignore_model2 = "event";
	} elsif ( $model =~ m/.*event.*/i )  {
		$ignore_model1 = "worker";
		$ignore_model2 = "prefork";
	} else {
		$ignore_model1 = "worker";
		$ignore_model2 = "event";
	}

	print "VERBOSE: Searching Apache configuration for the ".$config_element." directive\n" if $main::VERBOSE;

	# search for the string in the configuration array
	foreach (@$config_array) {
		# ignore lines that are comments
		if ( $_ !~ m/^\s*#/ ) {
			chomp($_);

			# we ignore lines that are within a Directory, Location, 
			# File, or Virtualhost block
		
			# check to see if we have an opening tag for one of the 
			# block types listed above
			if ( $_ =~ m/^\s*<(directory|location|files|virtualhost|ifmodule\s.*$ignore_model1|ifmodule\s.*$ignore_model2)/i ) {
				#print "Starting to ignore lines: ".$_."\n";
				$ignore = 1;
			}
			# check for a closing block to stop ignoring lines
			if ( $_ =~ m/^\s*<\/(directory|location|files|virtualhost|ifmodule)/i ) {
				#print "Starting to watch lines: ".$_."\n";
				$ignore = 0;
			}

			# if we're not ignoring lines, check and see if we've 
			# found the configuration element we're looking for
			if ( $ignore != 1 ) {		
				# if we find a match
				if ( $_ =~ m/^\s*$config_element\s+.*/i ) {
					chomp($_);
					$_ =~ s/^\s*$config_element\s+(.*)/$1/i;
					push(@results,$_);
				}
			}
		}
	}

	# if we find multiple definitions for the same element, we should 
	# return the last one
	my $result;

	if ( @results > 1 ) {
		$result = $results[@results - 1];
	}
	else {
		$result = $results[0];
	}

	#Result not found
	if (@results == 0) {
		$result = "CONFIG NOT FOUND";
	}

	print "VERBOSE: $result " if $main::VERBOSE;
	# Ubuntu does not store the Apache user, group, or pidfile definitions 
	# in the apache2.conf file. instead, variables are in the configuration 
	# file and the real values are in /etc/apache2/envvars. this is a 
	# workaround for that behavior.
	if ( $config_element =~ m/[users|group|pidfile]/i && $result =~ m/^\$/i ) {
		if ( -e "/etc/debian_version" && -e "/etc/apache2/envvars") {
			print "VERBOSE: Using Ubuntu workaround for: ".$config_element."\n" if $main::VERBOSE;
			print "VERBOSE: Processing /etc/apache2/envvars\n" if $main::VERBOSE;

			open(ENVVARS,"/etc/apache2/envvars") || die "Could not open file: /etc/apache2/envvars\n";	
			my @envvars = <ENVVARS>;
			close(ENVVARS);

			# change "pidfile" to match Ubuntu's "pid_file" 
			# definition
			if ( $config_element =~ m/pidfile/i ) {
				$config_element = "pid_file";
			}

			foreach (@envvars) {
				if ( $_ =~ m/.*$config_element.*/i ) {
					chomp($_);
					$_ =~ s/^.*=(.*)\s*$/$1/i;
					$result = $_;
				}
			}
		}
	}

	# return the value to the main program
	return $result;
}

# this will examine the memory usage of the apache processes and return one of
# three different outputs: average usage across all processes, the memory usage
# by the largest process, or the memory usage by the smallest process
sub get_memory_usage {
	my ($process_name, $apache_user, $search_type) = @_;
	
	my (@proc_mem_usages, $result);

	# get a list of the pid's for apache running as the appropriate user
	my @pids = `ps aux | grep $process_name | grep -v root | grep $apache_user | awk \'{ print \$2 }\'`;

        # if length of @pids is still zero then die with an error.
	if (@pids == 0) {
                show_crit_box(); print ("Error getting a list of PIDs\n");
		print ("DEBUG -> Process Name: ".$process_name."\nDEBUG -> Apache_user: ".$apache_user."\nDEBUG -> Search Type: ".$search_type."\n\n");
		exit 1;
	} 
	# figure out how much memory each process is using
	foreach (@pids) {
		chomp($_);
		# pmap -d is used to determine the memory usage for the 
		# individual processes
		my $pid_mem_usage = `pmap -d $_ | egrep "writeable/private|privado" | awk \'{ print \$4 }\'`;
		$pid_mem_usage =~ s/K//;
		chomp($pid_mem_usage);

		print "VERBOSE: Memory usage by PID ".$_." is ".$pid_mem_usage."K\n" if $main::VERBOSE;
		
		# on a busy system, the grep output will return the pid for the
		# grep process itself, which will be gone by the time we get 
		# around to running pmap
		if ( $pid_mem_usage ne "" ) {
			push(@proc_mem_usages, $pid_mem_usage);
		}
	}

	# examine the array 
	if ( $search_type eq "high" ) {
		# to find the largest process, sort the values from largest to
		# smallest and take the first one
		@proc_mem_usages = sort { $b <=> $a } @proc_mem_usages;
		$result = $proc_mem_usages[0] / 1024;
	}
	if ( $search_type eq "low" ) {
		# to find the smallest process, sort the values from smallest to
		# largest and take the first one
		@proc_mem_usages = sort { $a <=> $b } @proc_mem_usages;
		$result = $proc_mem_usages[0] / 1024;
	}
	if ( $search_type eq "average" ) {
		# to get the average, add up the total amount of memory used by
		# each process, and then divide by the number of processes
		my $sum = 0; 
		my $count;
		foreach (@proc_mem_usages) {
			$sum = $sum + $_;
			$count++;
		} 

		# our result is in kilobytes, convert it to megabytes before 
		# returning it
		$result = $sum / $count / 1024;
	}
	
	# round off the result
	$result = round($result);

	return $result;
}

# this function accepts the path to a file and then tests to see whether the 
# item at that path is an Apache binary
sub test_process {
	my ($process_name) = @_;
	# THIS SUBROUTINE WORKS FINE WITH httpd4u EXECUTABLES TOO.
        # Reduce to only aphanumerics, to deal with "nginx: master process" or any newlnes
        $process_name = `echo -n $process_name | sed 's/://g'`;

	# the first line of output from "httpd -V" should tell us whether or
	# not this is Apache
	our @output;
	if ( $process_name eq '/usr/sbin/httpd' ) {
		@output = `$process_name -V 2>&1 | grep "Server version"`;
		print "VERBOSE: First line of output from \"$process_name -V\": $output[0]" if $main::VERBOSE;
	} elsif ( $process_name eq '/usr/sbin/httpd.worker' ) {
		# Handle Worker processes better
		# BUGFIX, first identified by C. Piper Balta 
		@output = `$process_name -V 2>&1 | grep "Server version"`;
		print "VERBOSE: First line of output from \"$process_name -V\": $output[0]" if $main::VERBOSE;
	} elsif ( $process_name eq '/usr/sbin/apache2' ) {
		@output = `/usr/sbin/apache2ctl -V 2>&1 | grep "Server version"`;
		print "VERBOSE: First line of output from \"/usr/sbin/apache2ctl -V\": $output[0]" if $main::VERBOSE;
	} else {
		# this catchall should cover all other possibilities, such as
		# nginx, varnish, etc. 
		# BUGFIX, first identified by C. Piper Balta.
		my $return_val = 0;
		return $return_val;
	}


	my $return_val = 0;
        #if ( $output eq '' ) {
        #    $return_val = 0;
        #}

	# check for output matching Apache'
        if ( $output[0] =~ m/^Server version.*Apache\/[0-9].*/ ) {
		$return_val = 1;
	} 

	return $return_val;
}

# this will return the pid for the process listening on the port specified
sub get_pid {
	my ( $port ) = @_;

	# find the pid for the software listening on the specified port. this
	# might return multiple values depending on Apache's listen directives
	my @pids = `netstat -ntap | egrep "LISTEN|OUÇA" | grep \":$port \" | awk \'{ print \$7 }\' | cut -d / -f 1`;

	print "VERBOSE: ".@pids." found listening on port 80\n" if $main::VERBOSE;

	# set an initial, invalid PID. 
	my $pid = 0;;
	foreach (@pids) {
		chomp($_);
		$_ =~ s/(.*)\/.*/$1/;
		if ( $pid == 0 ) {
			$pid = $_;
		}
		elsif ( $pid != $_ ) {
			print "There are multiple PIDs listening on port $port.";
			exit;
		}
		else { 
			$pid = $_;
		}
	}

	# return the pid, or 0 if there is no process found
	if ( $pid eq '' ) {
		$pid = 0;
	}

	print "VERBOSE: Returning a PID of ".$pid."\n" if $main::VERBOSE;

	return $pid;
}

# this will return the path to the application running with the specified pid
sub get_process_name {
	my ( $pid ) = @_;

	print "VERBOSE: Finding process running with a PID of ".$pid."\n" if $main::VERBOSE;

	# based on the process name, we can figure out where the binary lives
	my $process_name = `ps ax | grep "\^[[:space:]]*$pid\[[:space:]]" | awk \'{print \$5 }\'`;
	chomp($process_name);

	print "VERBOSE: Found process ".$process_name."\n" if $main::VERBOSE;

	# return the process name, or 0 if there is no name found
	if ( $process_name eq '' ) {
		$process_name = 0;
	}

	return $process_name;
}

# this will return the apache root directory when given the full path to an
# Apache binary
sub get_apache_root {
	our ( $process_name ) = @_;
	our $apache_root;
	# use the identified Apache binary to figure out where the root directory is 
	# for the Apache instance
	if ( $process_name eq "/usr/sbin/apache2") {
		# use apache2ctl instead ...
		$apache_root = `apache2ctl -V 2>&1 | grep \"HTTPD_ROOT\"`;
		$apache_root =~ s/.*=\"(.*)\"/$1/;
		chomp($apache_root);
	} else {
		$apache_root = `$process_name -V 2>&1 | grep \"HTTPD_ROOT\"`;
		$apache_root =~ s/.*=\"(.*)\"/$1/;
		chomp($apache_root);
	}
	if ( $apache_root eq '' ) {
		$apache_root = 0;
	}

	return $apache_root;
}

# this will return the apache configuration file, relative to the apache root
# for the provided apache binary
sub get_apache_conf_file {
	our $apache_conf_file;
	my ( $process_name ) = @_;
	if ( $process_name eq "/usr/sbin/apache2") {
		# use apache2ctl instead ...
		$apache_conf_file = `apache2ctl -V 2>&1 | grep \"SERVER_CONFIG_FILE\"`;
		$apache_conf_file =~ s/.*=\"(.*)\"/$1/;
		chomp($apache_conf_file);
	} else {
		$apache_conf_file = `$process_name -V 2>&1 | grep \"SERVER_CONFIG_FILE\"`;
		$apache_conf_file =~ s/.*=\"(.*)\"/$1/;
		chomp($apache_conf_file);
	}
	# return the apache configuration file, or 0 if there is no result
	if ( $apache_conf_file eq '' ) {
		$apache_conf_file = 0;
	}

	return $apache_conf_file;
}

# this will determine whether this apache is using the worker or the prefork
# model based on the way the binary was built
sub get_apache_model {
	our $model;
	my ( $process_name ) = @_;
	if ( $process_name eq "/usr/sbin/apache2") {
		# In apache2, worker / prefork / event are no longer compiled-in.
		# Instead, with is a loaded in module 
		# differing from httpd / httpd24u's process directly, in ubuntu we need to run apache2ctl.
		$model = `apache2ctl -M 2>&1 | egrep "worker|prefork|event"`;
		chomp($model);
		$model =~ s/\s*mpm_(.*)_module\s*\S*/$1/;
	} else {
		$model = `$process_name -l 2>&1 | egrep "worker.c|prefork.c"`;
		chomp($model);
		$model =~ s/\s*(.*)\.c/$1/;
	}

	# return the name of the MPM, or 0 if there is no result
	if ( $model eq '' ) {
		# find another way to verify the MPM, for example httpd4u packages
		# use the loadmodule directive in /etc/httpd/conf.modules.d/00-mpm.conf.
		# As such a command like 'httpd -M | egrep "worker|prefork"' would be able
		# to capture this.
		$model = `$process_name -M 2>&1 | egrep "worker|prefork|event"`;
		chomp($model);
		$model =~ s/\s*mpm_(.*)_module\s*\S*/$1/;
	}
	# If model is STILL BLANK....set it to 0
	if ( $model eq '' ) {
		$model = 0 ;
	}
	return $model;
}

# this will get the Apache version string
sub get_apache_version {
	my ( $process_name ) = @_;
	# set a default value
	our $version = 0;
	
	# check for red hat style spache installs
	if ( $process_name eq '/usr/sbin/httpd' ) {
		$version = `$process_name -V 2>&1 | grep "Server version"`;
		chomp($version);
		$version =~ s/.*:\s(.*)$/$1/;
	}
	# ubuntu has to be different, so...
	if ( $process_name eq '/usr/sbin/apache2' ) {
                $version = `/usr/sbin/apache2ctl -V 2>&1 | grep "Server version"`;
                chomp($version);
                $version =~ s/.*:\s(.*)$/$1/;
        }

	return $version;
}

# this will us ps to determine the Apache uptime. it returns an array 
sub get_apache_uptime {
	my ( $pid ) = @_;

	# this will return the running time for the given pid in the format 
	# "days-hours:minutes:seconds"
	my $uptime = `ps -eo \"\%p \%t\" | grep $pid | grep -v grep | awk \'{ print \$2 }\'`;
	chomp($uptime);

	print "VERBOSE: Raw uptime: $uptime\n" if $main::VERBOSE;

	# check to see if we've been running for multiple days
	my ($days, $hours, $minutes, $seconds);
	if ( $uptime =~ m/^.*-.*:.*:.*$/ ) {	
		$days = $uptime;
		$days =~ s/([0-9]*)-.*/$1/;

		# trim the days off of our uptime value
		$uptime =~ s/.*-(.*)/$1/;
	
		($hours, $minutes, $seconds) = split(':', $uptime);
	}
	elsif ( $uptime =~ m/^.*:.*:.*/ ) {
		$days = 0;
		($hours, $minutes, $seconds) = split(':', $uptime);
	}
	elsif ( $uptime =~ m/^.*:.*/) {
		$days = 0;
		$hours = 0;
		($minutes, $seconds) = split(':', $uptime);	
	}
	else {
		$days = 0;
		$hours = 0;
		$minutes = 00;
		$seconds = 00;
	}

	# push everything into an array to pass back
	my @apache_uptime = ( $days, $hours, $minutes, $seconds );

	

	return @apache_uptime;
}

# return the global value for a PHP setting
sub get_php_setting {
	my ( $php_bin, $element ) = @_;	

	# this will return an array with all of the local and global PHP 
	# settings
	my @php_config_array = `php -r "phpinfo(4);"`;

	my @results;

	# search the array for our desired setting
	foreach (@php_config_array) {
		chomp($_);
		if ( $_ =~ m/^\s*$element\s*/ ) {
			chomp($_);
			$_ =~ s/.*=>\s+(.*)\s+=>.*/$1/;
			push(@results, $_);
		}
	}

        # if we find multiple definitions for the same element, we should 
        # return the last one (just in case)
        my $result;

        if ( @results > 1 ) {
                $result = $results[@results - 1];
        }
        else {
                $result = $results[0];
        }

	# some PHP directives are measured in MB. we want to trim the "M" off
	# here for those that are
	$result =~ s/^(.*)M$/$1/;

        # return the value to the main program
        return $result;
}

sub generate_standard_report {
	my ( $available_mem,
		$maxclients,
		$apache_proc_smallest,
		$apache_proc_average,
		$apache_proc_highest,
		$model,
		$threadsperchild,
		$mysql_memory_usage_mbytes,
		$java_memory_usage_mbytes,
		$redis_memory_usage_mbytes,
		$memcache_memory_usage_mbytes,
		$varnish_memory_usage_mbytes,
		$phpfpm_memory_usage_mbytes,
		$gluster_memory_usage_mbytes) = @_;


	# print a report header
	if ( ! $NOINFO ) { print "${BOLD}### GENERAL FINDINGS & RECOMMENDATIONS ###${ENDC}\n" } 
	insert_hrule();
 	our $servername;
	our $public_ip_address;

	print "Apache2buddy.pl report for server: ${CYAN}$servername${ENDC} \(${CYAN}$public_ip_address${ENDC}\):\n";
	# show what we're going to use to generate our numbers
	print "\nSettings considered for this report:\n\n"; # exempt from NOINFO directive. 
	printf ("%-62s ${CYAN}%d %2s${CYAN}\n",   "\tYour server's physical RAM:", $available_mem, "MB"); # exempt from NOINFO directive.
	my $memory_remaining = $available_mem - $mysql_memory_usage_mbytes - $java_memory_usage_mbytes - $redis_memory_usage_mbytes - $memcache_memory_usage_mbytes - $varnish_memory_usage_mbytes - $phpfpm_memory_usage_mbytes- $gluster_memory_usage_mbytes;
	printf ("${BOLD}%-62s${ENDC} ${CYAN}%d %2s${ENDC}\n",   "\tRemaining Memory after other services considered:", $memory_remaining, "MB"); # exempt from NOINFO directive.
	printf ("%-62s ${CYAN}%d${ENDC} %5s %-30s\n",   "\tApache's MaxClients directive:", $maxclients, " ", "<--------- Current Setting"); # exempt from NOINFO directive.
	printf ("%-62s ${CYAN}%s${ENDC}\n",   "\tApache MPM Model:", $model); # exempt from NOINFO directive.
	if ( ! $NOINFO ) { printf ("%-62s ${CYAN}%d %2s${ENDC}\n", "\tLargest Apache process (by memory):", $apache_proc_highest, "MB") }

	if ($model eq "prefork") {
		# based on the Apache memory usage (size of the largest process, 
		# check to see if the maxclients setting for Apache is sane
		our $max_rec_maxclients = $memory_remaining / $apache_proc_highest;
		$max_rec_maxclients = floor($max_rec_maxclients);
		our $tolerance = 0.90; 
		our $min_rec_maxclients = floor($max_rec_maxclients*$tolerance);

		# determine the maximum potential memory usage by Apache
		my $max_potential_usage = $maxclients * $apache_proc_highest;
		our $max_potential_usage_pct_avail = round(($max_potential_usage/$available_mem)*100);
		our $max_potential_usage_pct_remain = round(($max_potential_usage/$memory_remaining)*100);
		if ( $maxclients >= $min_rec_maxclients and  $maxclients <= $max_rec_maxclients ) {
			show_shortok_box(); print "\t${GREEN}Your MaxClients setting is within an acceptable range.${ENDC}\n"; # exempt from NOINFO directive.
			print "\tYour recommended MaxClients setting is between $min_rec_maxclients and $max_rec_maxclients${ENDC}.\t\t<------- Acceptable Range (10% of MAX)\n";
			printf ("%-62s ${CYAN}%d %2s${ENDC}\n", "\tMax potential memory usage:", $max_potential_usage, "MB");  # exempt from NOINFO directive.
			printf  ("%-62s ${CYAN}%3.2f %2s${ENDC}\n", "\tPercentage of TOTAL RAM allocated to Apache:", $max_potential_usage_pct_avail, "%");  # exempt from NOINFO directive.
			printf  ("%-62s ${CYAN}%3.2f %2s${ENDC}\n", "\tPercentage of REMAINING RAM allocated to Apache:", $max_potential_usage_pct_remain, "%");  # exempt from NOINFO directive.
		} elsif ( $maxclients < $min_rec_maxclients ) {
			show_shortcrit_box(); print "\t${RED}Your MaxClients setting is too low.${ENDC}\n"; # exempt from NOINFO directive.
			print "\t${YELLOW}Your recommended MaxClients setting is between $min_rec_maxclients and $max_rec_maxclients.${ENDC}\t\t<------- Acceptable Range (10% of MAX)\n";
			printf ("%-62s ${CYAN}%d %2s${ENDC}\n", "\tMax potential memory usage:", $max_potential_usage, "MB");  # exempt from NOINFO directive.
			printf  ("%-62s ${CYAN}%3.2f %2s${ENDC}\n", "\tPercentage of TOTAL RAM allocated to Apache:", $max_potential_usage_pct_avail, "%");  # exempt from NOINFO directive.
			printf  ("%-62s ${CYAN}%3.2f %2s${ENDC}\n", "\tPercentage of REMAINING RAM allocated to Apache:", $max_potential_usage_pct_remain, "%");  # exempt from NOINFO directive.
		} else {
			show_shortcrit_box(); print "\t${RED}Your MaxClients setting is too high.${ENDC}\n"; # exempt from NOINFO directive.
			print "\t${YELLOW}Your recommended MaxClients setting is between $min_rec_maxclients and $max_rec_maxclients.${ENDC}\t\t<------- Acceptable Range (10% of MAX)\n";
			printf ("%-62s ${RED}%d %2s${ENDC}\n", "\tMax potential memory usage:", $max_potential_usage, "MB");  # exempt from NOINFO directive.
			printf ("%-62s ${RED}%3.2f %2s${ENDC}\n", "\tPercentage of TOTAL RAM allocated to Apache:", $max_potential_usage_pct_avail, "%");  # exempt from NOINFO directive.
			printf ("%-62s ${RED}%3.2f %2s${ENDC}\n", "\tPercentage of REMAINING RAM allocated to Apache:", $max_potential_usage_pct_remain, "%");  # exempt from NOINFO directive.
		}
		# make a logfile entry at /var/log/apache2buddy.log
		open (LOGFILE, ">>/var/log/apache2buddy.log");
		sub date {
	        	my $current_date = `date +"%Y/%m/%d %H:%M:%S"`;
       			$current_date = substr($current_date,0,-1);
       			return $current_date;
        	}
	
        	print LOGFILE (date()." Model: \"Prefork\" Memory: \"$available_mem MB\" Maxclients: \"$maxclients\" Recommended: \"$max_rec_maxclients\" Smallest: \"$apache_proc_smallest MB\" Avg: \"$apache_proc_average MB\" Largest: \"$apache_proc_highest MB\" Highest Pct Remaining RAM: \"$max_potential_usage_pct_remain%\" \($max_potential_usage_pct_avail% TOTAL RAM)\n");
        	close(LOGFILE);
	
	}
	if ($model eq "worker") {
			print "\t${CYAN}Apache appears to be running in worker mode.\n";
			print "\tPlease check manually for backend processes such as PHP-FPM and pm.max_children.\n";
			print "\tApache2buddy does not calculate maxclients for worker model.${ENDC}\n";
			# make a logfile entry at /var/log/apache2buddy.log
			open (LOGFILE, ">>/var/log/apache2buddy.log");
			sub date {
	        		my $current_date = `date +"%Y/%m/%d %H:%M:%S"`;
       				$current_date = substr($current_date,0,-1);
       				return $current_date;
        		}
        		print LOGFILE (date()." Model: \"Worker\" Memory: \"$available_mem MB\" Maxclients: \"$maxclients\" Recommended: \"N\\A\" Smallest: \"$apache_proc_smallest MB\" Avg: \"$apache_proc_average MB\" Largest: \"$apache_proc_highest MB\"\n");
        		close(LOGFILE);
	}	
	if ($model eq "event") {
			print "\t${CYAN}Apache appears to be running in event mode.\n";
			print "\tPlease check manually for backend processes such as PHP-FPM and pm.max_children.\n";
			print "\tApache2buddy does not calculate maxclients for worker model.${ENDC}\n";
			# make a logfile entry at /var/log/apache2buddy.log
			open (LOGFILE, ">>/var/log/apache2buddy.log");
			sub date {
	        		my $current_date = `date +"%Y/%m/%d %H:%M:%S"`;
       				$current_date = substr($current_date,0,-1);
       				return $current_date;
        		}
        		print LOGFILE (date()." Model: \"Event\" Memory: \"$available_mem MB\" Maxclients: \"$maxclients\" Recommended: \"N\\A\" Smallest: \"$apache_proc_smallest MB\" Avg: \"$apache_proc_average MB\" Largest: \"$apache_proc_highest MB\"\n");
        		close(LOGFILE);
	}
	our $phpfpm_detected;
	if ( $phpfpm_detected ) {
		insert_hrule();
		print "${RED}PHP-FPM DETECTED: The results shown may be skewed, check /etc/php-fpm.d/<pool>.conf\nfor and calculate pm.max_children separately.${ENDC}\n";
	}
	insert_hrule();
	if ( ! $NOINFO ) { 
		print "A log file entry has been made in: /var/log/apache2buddy.log for future reference.\n\n";
		print "Last 5 entries:\n\n";
		my $entries = `tail -5 /var/log/apache2buddy.log`;
		print $entries."\n";
	}
}

# this rounds a value to the nearest hundreth
sub round {
	my ( $value ) = @_;

	# add five thousandths
	$value = $value + 0.005;

	# truncat the result
	$value = sprintf("%.2f", $value);

	return $value;
}	

#Return the number of CPU cores
sub get_cores {
    my $cmd = 'egrep ' . "'". '^physical id|^core id|^$' . "'" . ' /proc/cpuinfo | awk '. "'" . 'ORS=NR%3?",":"\n"' . "'" . '| sort | uniq | wc -l';
    my $cmd_out = `$cmd`;
    chomp $cmd_out;
    return $cmd_out;
}



# print a header
sub print_header {
	if ( ! $NOHEADER ) {
		my $header = <<"END_HEADER";
${BLUE}########################################################################################${ENDC}
${CYAN}##       ___                     __        ___      ____            __    __          ##${ENDC}
${GREEN}##      /   |  ____  ____ ______/ /_  ___ |__ \\    / __ )__  ______/ /___/ /_  __     ##${ENDC}
${PURPLE}##     / /| | / __ \\/ __ `/ ___/ __ \\/ _ \\__/ /   / __  / / / / __  / __  / / / /     ##${ENDC}
${BLUE}##    / ___ |/ /_/ / /_/ / /__/ / / /  __/ __/   / /_/ / /_/ / /_/ / /_/ / /_/ /      ##${ENDC}
${CYAN}##   /_/  |_/ .___/\\__,_/\\___/_/ /_/\\___/____/  /_____/\\__,_/\\__,_/\\__,_/\\__, /       ##${ENDC}
${GREEN}##         /_/ apache2buddy.pl                                          /____/        ##${ENDC}
${PURPLE}##                                                                                    ##${ENDC}
${BLUE}########################################################################################${ENDC}
END_HEADER

		print $header;
	}
	if ( ! $NOINFO ) { print "\n${PURPLE}About...${ENDC}\n" };
	if ( ! $NOINFO ) { show_info_box(); print "apache2buddy.pl is a fork of apachebuddy.pl.\n" }
	if ( ! $NOINFO ) { show_info_box(); print "Project status: ${GREEN}STABLE${ENDC}. Please report bugs, if you find any, so I can fix them!\n" }
	if ( ! $NOINFO ) { show_info_box(); print "Latest update: ${CYAN}$date_last_modified${ENDC}. Check ${CYAN}http://apache2buddy.pl/changelog${ENDC} for details.\n" }
	if ( ! $NOINFO ) { show_info_box(); print "Send bug reports / feature requests to ${BLUE}richard.forth AT gmail.com${ENDC}.\n" }
	if ( ! $NONEWS ) { show_news_box(); print "${GREEN}Support for the following systems has been added:${ENDC}.\n" }
	if ( ! $NONEWS ) { show_news_box(); print "${CYAN}Ubuntu 12.04 / 14.04, Debian 6 / 7 / 8, CentOS / Scientific Linux / RHEL versions 5.x, 6.x, 7.x.${ENDC}\n" }
}


sub show_debug_box {
	print "[ ${GREEN}DeBuG${ENDC} ] "; 
}

sub show_advisory_box {
	print "[ ${YELLOW}ADVISORY${ENDC} ] "; 
}

sub show_news_box {
	print "[ ${BOLD}* NEWS *${ENDC} ] ";
}

sub show_info_box {
	print "[ ${BOLD}INFO${ENDC}     ] ";
}

sub show_ok_box {
	print "[ ${GREEN}OK${ENDC}       ] ";
}

sub show_warn_box {
	print "[ ${BOLD}${YELLOW}WARNING${ENDC}  ] ";
}

sub show_crit_box {
	print "[ ${RED}CRITICAL${ENDC} ] ";
}

sub show_shortok_box {
	print "[ ${GREEN}OK${ENDC} ]";
}

sub show_shortcrit_box {
	print "[ ${RED}!!${ENDC} ] ";
}

sub insert_hrule() {
	print "-" x 80;
	print "\n";
}

sub preflight_checks {
	# There will be other showstoppers that become apparent as the script develops in execution,
	# however we can capture the common "basic errors" here, and gracefully exit with useful errors.
	
	if ( ! $NOINFO ) { print "\n${PURPLE}Performing Auto-Discovery, and Pre-Flight Checks...${ENDC}\n" }
	
	# Check 1
	# make sure the script is being run as root.
	# we need to run as root to ensure that we can access all of the appropriate
	# files
	my $uid = `id -u`;
	chomp($uid);

	print "VERBOSE: UID of user is: ".$uid."\n" if $VERBOSE;

	if ( $uid ne '0' ) {
		show_crit_box();
 	      	print "This script must be run as root.\n";
        	exit;
	} else {
		if ( ! $NOOK ) { show_ok_box(); print "This script is being run as root.\n" }
	}

	# Check 2
	# this script uses pmap to determine the memory mapped to each apache 
	# process. make sure that pmap is available.
	our $pmap = `which pmap`;
	chomp($pmap);

	# make sure that pmap is available within our path
	if ( $pmap !~ m/.*\/pmap/ ) { 
		show_crit_box(); 
		print "Unable to locate the pmap utility. This script requires pmap to analyze Apache's memory consumption.\n";
		exit;
	} else {
		if ( ! $NOOK ) { show_ok_box(); print "The utility 'pmap' exists and is available for use: ${CYAN}$pmap${ENDC}\n" }
	}

	# Check 3
	# make sure PHP is available before we proceed
	# check to see if there is a binary called "php" in our path
	my $check = `which php`;
	if ( $check eq '' ) {
		show_crit_box();
		print "Unable to locate the PHP binary.\n";
		my $path = `echo \$PATH`;
		chomp($path);
		print "VERBOSE: Path: $path\n" if $VERBOSE;
		exit;
	} else {	
		if ( ! $NOOK ) { show_ok_box(); print "'php' exists and is available for use: ${CYAN}$check${ENDC}\n" }
	}
	
	# Check 4
	# Check for valid port
	if ( $port < 0 || $port > 65534 ) {
		show_crit_box();
		print "INVALID PORT: $port. ";
		print "Valid port numbers are 1-65534.\n";
		exit;
	} else {
		if ( ! $NOOK ) { show_ok_box(); print "The port \(port ${CYAN}$port${ENDC}\) is a valid port.\n" }
	}
	
	# Check 5
	# Get OS Name and Version
	our $os_release;
	our $os_name = '';
	if ( ! $NOINFO ) { show_info_box(); print "We are attempting to discover the operating system type and version number ...\n" }
	# in traditional style we go for the obvious first and check if its Red Hat or CentOS
	if ( -f "/etc/redhat-release" ) {
	        $os_name = `cat /etc/redhat-release 2>&1 | head -1 | awk '{ print \$1 }'`;
	        chomp ($os_name);

	        if ( $os_name eq "CentOS" ) {
		        $os_release = `cat /etc/redhat-release 2>&1 | head -1 | awk '{ print \$3 }'`;
       		 } elsif ( $os_name  eq "Red" ) {
	        	$os_name = `cat /etc/redhat-release 2>&1 | head -1 | awk '{ print \$1 " " \$2 " " \$3 " " \$4 }'`;
                	chomp ($os_name);
                	$os_release = `cat /etc/redhat-release 2>&1 | head -1 | awk '{ print \$7 }'`;
       		 } elsif ( $os_name  eq "Scientific" ) {
	        	$os_name = `cat /etc/redhat-release 2>&1 | head -1 | awk '{ print \$1 " " \$2 }'`;
                	chomp ($os_name);
                	$os_release = `cat /etc/redhat-release 2>&1 | head -1 | awk '{ print \$3 }'`;
        	} else {
			show_crit_box();
	               	print ("Either we couldnt get the OS name, or its not a supported distro.\n");
			exit;
        	}
	}

	# if theres no /etc/redhat release check if its Ubuntu...
        if ( $os_name eq '' ) {
	        # then we have to assume its either debian or ubuntu ...
      	        $os_name = `lsb_release -a 2>&1 | grep "Distributor ID:" | awk '{ \$1=\$2=""; print }'`;
             	chomp ($os_name);
                # strip the leading spaces
                $os_name =~ s/\s*(.*)\s*/$1/;
                $os_release = `lsb_release -a 2>&1 | grep "Release:" | awk '{ \$1=""; print }'`;
                # strip the leading spaces
                $os_release =~ s/\s*(.*)\s*/$1/;
       	}

	## Or debian ...
	if ( $os_name eq '' ) {
		if ( -f "/etc/issue" ) {
			$os_name = `cat /etc/issue | head -1 | awk '{ print \$1 }'`;
             		chomp ($os_name);
			print $os_name."\n";
			if ( $os_name eq "Debian") {
				$os_release = `cat /etc/debian_version`;
				chomp($os_release);
				$os_release =~ s/(^.{3}).*$/$1/; 
			}
		}
	}	
	
	## or some other unsupported distro ...
	if ( $os_name eq '' ) {
		show_crit_box();
		print ("Either we couldnt get the OS name, or its not a supported distro.\n");
		exit;
        }
       	chomp ($os_release);
	if ( $os_release  eq "release" ) {
		# capture RHEL / CENTOS 7 first as I've not coded it up to support that yet, and the wording means that column 3 on CentOS 7 is the word "release" 
		# shift one more field along in the /etc/redhat-release file to get the actual version number
	        $os_release = `cat /etc/redhat-release 2>&1 | head -1 | awk '{ print \$4 }'`;
      		chomp ($os_release);
		$os_release =~ s/(^.{3}).*$/$1/; 
	}
 		
	if ( ! $NOINFO ) { show_info_box();  print "OS Name: ${CYAN}$os_name${ENDC}\n" }
	if ( ! $NOINFO ) { show_info_box();  print "OS Release: ${CYAN}$os_release${ENDC}\n" }

	# If its unsupported or end of life, continue, but complain loudly.
	if ( $os_name eq "Red Hat Enterprise Linux" or $os_name eq "CentOS" ) {
		# RedHat / CentOS 4 is currenly End of Life as of this writing.
		if ( $os_release <= 4 ) {
			if ( ! $NOWARN ) { show_warn_box(); print "${RED}$os_name $os_release is now end of life, its technically unsupported, we may get errors${ENDC}\n" }
		} else {
			 if ( ! $NOOK ) { show_ok_box(); print "Apache2buddy supports this OS Release/Version.\n" }
		}
	} elsif ( $os_name eq "Ubuntu" ) {
		if ( $os_release <= 13.10 ) {
			# take into account 12.04 LTS which is supported until 2018
			unless  ( $os_release == "12.04") {
				# as of current writing, 13.10 is the latest EOL version of Ubuntu
				# https://wiki.ubuntu.com/Releases
				show_warn_box();
				print $os_name." ".$os_release." is now end of life, its technically unsupported, we may get errors";
				print ".\n";
			}
		} else {
			show_ok_box;
			print "The operating system is supported.\n"
		}
	} elsif ( $os_name eq "Debian" ) {
		if ( $os_release <= 5.0 ) {
			# as of current writing, 5.0 (Lenny) is the latest EOL version of Debian
			# https://wiki.debian.org/DebianReleases
			show_warn_box();
			print $os_name." ".$os_release." is now end of life, its technically unsupported, we may get errors";
			print ".\n";
		} else {
			show_ok_box;
			print "The operating system is supported.\n"
		}
		
	}

	# get our hostname
	our $hostname = `which hostname`;
	chomp($hostname);
	print "VERBOSE: hostname executable path: ".$hostname if $VERBOSE;
	if ( $hostname eq '' ) {
		show_crit_box();
		print "Cannot find the 'hostname' executable.";
		exit;
	} else {   	
		#our $hostname;
		our $servername = `$hostname -f`;
		chomp($servername);
		if ( ! $NOINFO ) { show_info_box(); print "Hostname: ${CYAN}$servername${ENDC}\n" }
	}

	# get our ip address
	our $curl = `which curl`;
	chomp ($curl);
	print "VERBOSE: curl executable path: ".$curl if $VERBOSE;
	if ( $curl eq '' ) {
		show_crit_box;
		print "Cannot find the 'curl' executable.";
		exit;
	} else {   	
		#our $curl;
		# Commented out curlmyip.com as is now very slow to respond.
		#our $public_ip_address = `$curl -s curlmyip.com`;
		#chomp($public_ip_address); 
		our $public_ip_address = `$curl -s myip.dnsomatic.com`;
		if ( ! $NOINFO ) { show_info_box();  print "Primary IP: ${CYAN}$public_ip_address${ENDC}\n" }
	}	

	
	# Check 6
	# first thing we do is get the pid of the process listening on the 
	# specified port
	if ( ! $NOINFO ) { show_info_box(); print "We are checking the service running on port ${CYAN}$port${ENDC}...\n" }

	our $pid = get_pid($port);
	
	print "VERBOSE: PID is ".$pid."\n" if $VERBOSE;
	
	if ( $pid eq 0 ) {
		show_crit_box(); print "${RED}Unable to determine PID of the process.${ENDC} ${YELLOW}Is apache running on this server?${ENDC}\n";
		if ( $os_name eq "Ubuntu" or $os_name eq "Debian") {
			show_info_box(); print "${YELLOW}Chances are you havent yet installed Apache, try the following command:${ENDC}\n";
			show_info_box(); print "\n"; 
			show_info_box(); print "                  ${GREEN}sudo apt-get install apache2${ENDC}\n";
			show_info_box(); print "${YELLOW}Or try:${ENDC}\n"; 
			show_info_box(); print "                  ${GREEN}apache2ctl start${ENDC}\n";
			show_info_box(); print "\n"; 
			show_info_box(); print "${YELLOW}Then try running this script again.${ENDC}\n"; 
			exit;
		} else {
			show_info_box(); print "${YELLOW}Chances are you havent yet installed Apache, try the following commands:${ENDC}\n";
			show_info_box(); print "\n"; 
			show_info_box(); print "                  ${GREEN}yum install httpd${ENDC}\n";
			show_info_box(); print "                  ${GREEN}service httpd start${ENDC}\n";
			show_info_box(); print "                  ${GREEN}chkconfig httpd on${ENDC}\n";
			show_info_box(); print "${YELLOW}Or try:${ENDC}\n"; 
			show_info_box(); print "                  ${GREEN}service httpd start${ENDC}\n";
			show_info_box(); print "                  ${GREEN}chkconfig httpd on${ENDC}\n";
			show_info_box(); print "\n"; 
			show_info_box(); print "${YELLOW}Then try running this script again.${ENDC}\n"; 
			exit;
		}
	}
	
	# now we get the name of the process running with the specified pid
	our $process_name = get_process_name($pid);
	if ( ! $NOINFO ) { show_info_box; print "The process listening on port ${CYAN}$port${ENDC} is ${CYAN}$process_name${ENDC}\n" }
	
	if ( $process_name eq 0 ) {
		show_crit_box();
		print "Unable to determine the name of the process. Is apache running on this server?\n";
		exit;
	}

	# Check 7
	# check to see if the process we have identified is Apache
	our $is_it_apache = test_process($process_name);
	
	if ( $is_it_apache == 1 ) {
		our $apache_version = get_apache_version($process_name);
	
		print "VERBOSE: Apache version: $apache_version\n" if $VERBOSE;
	
		# if we received a "0", just print "Apache"
		if ( $apache_version eq 0 ) {
			$apache_version = "Apache";	
		}
		if ( ! $NOINFO ) { show_info_box; print "The process running on port ${CYAN}$port${ENDC} is ${CYAN}$apache_version${ENDC}.\n" }
	}  else {
		if ( ! $NOINFO ) { show_info_box; print "The process running on port $port is not Apache. Falling back to process list...\n" }
		my @process_info = split(' ', `ps -C 'httpd apache apache2' -f | grep '^root'`);
		$pid = $process_info[1];

		if ( !$pid ) {
			show_crit_box();
	                print "Could not find Apache process. Exiting...\n";
			exit;
	        } else {
			# If we found it, then reset the proces_name, and version.
			$process_name = get_process_name($pid);
			our $apache_version = get_apache_version($process_name);
			# also report what port apache is actually listening on.
			my $command = `netstat -plnt | egrep "httpd|apache2"`;
			if ( $command =~ /:+(\d+)/ ) { our $real_port = $1 }
			our $real_port;
			if ( ! $NOINFO ) { show_info_box; print "Apache is actually listening on port ${CYAN}$real_port${ENDC}\n" }
			if ( ! $NOINFO ) { show_info_box; print "The process running on port ${CYAN}$real_port${ENDC} is ${CYAN}$apache_version${ENDC}.\n" }

		}
	}
	# Check 8
	# determine the Apache uptime
	my @apache_uptime = get_apache_uptime($pid);
	
	if ( ! $NOINFO ) { show_info_box(); print "Apache has been running ${CYAN}$apache_uptime[0]${ENDC}d ${CYAN}$apache_uptime[1]${ENDC}h ${CYAN}$apache_uptime[2]${ENDC}m ${CYAN}$apache_uptime[3]${ENDC}s.\n" }
	
	# Check 9
	# find the apache root	
	our $apache_root = get_apache_root($process_name);
	print "VERBOSE: The Apache root is: ".$apache_root."\n" if $VERBOSE;
	
	# check 10
	# find the apache configuration file (relative to the apache root)
	our $apache_conf_file = get_apache_conf_file($process_name);
	print "VERBOSE: The Apache config file is: ".$apache_conf_file."\n" if $VERBOSE;
	
	# check 11
	# piece together the full path to the configuration file, if a server 
	# does not have the HTTPD_ROOT value defined in its apache build, then
	# try just using the path to the configuration file
	our $full_apache_conf_file_path;
	if ( -e $apache_conf_file ) {
		$full_apache_conf_file_path = $apache_conf_file;
		if ( ! $NOINFO ) { show_info_box(); print "The full path to the Apache config file is: ${CYAN}$full_apache_conf_file_path${ENDC}\n" }
	} elsif ( -e $apache_root."/".$apache_conf_file ) {
		$full_apache_conf_file_path = $apache_root."/".$apache_conf_file;
		if ( ! $NOINFO ) { show_info_box(); print "The full path to the Apache config file is: ${CYAN}$full_apache_conf_file_path${ENDC}\n" }
	} else {
		show_crit_box();
		print "Apache configuration file does not exist: ".$full_apache_conf_file_path."\n";
		exit;
	}
	
	# check 12
	# find out if we're using worker or prefork
	our $model = get_apache_model($process_name);	
	if ( $model eq 0 ) {
		show_crit_box();
		print "Unable to determine whether Apache is using worker or prefork\n";
		exit;
	} else {
                # account for '\x{d}' strangeness
                $model =~ s/\x{d}//;
                if ( ! $NOINFO ) { show_info_box(); print "Apache is using ${CYAN}$model${ENDC} model.\n" }
	}
	
	# Check 13	
	# get the entire config, including included files, into an array
	our @config_array = build_config_array($full_apache_conf_file_path,$apache_root);
	# determine what user apache runs as 
	our $apache_user = find_master_value(\@config_array, $model, 'user');
        # account for 'apache\x{d}' strangeness
        $apache_user =~ s/\x{d}//;
	unless ($apache_user eq "apache" or $apache_user eq "www-data") {
                my $apache_userid = `id -u $apache_user`;
                chomp($apache_userid);
                # account for 'apache\x{d}' strangeness
                $apache_user =~ s/\x{d}//;
                show_warn_box(); print ("${RED}Non-standard apache set-up, apache is running as UID: ${CYAN}$apache_userid${RED} (${CYAN}$apache_user${RED}). Expecting UID 48 ('apache' or 'www-data').${ENDC}\n");
		if ( ! $NOINFO ) { show_info_box(); print "Apache runs as ${CYAN}$apache_user${ENDC}.\n" }
        }	
	
	if (length($apache_user) > 8) {
		# Now we have to keep the first 7 characters and change the 8th character to a + sign, eg 'developer' becomes 'develop+'
		my $original_user = $apache_user;
		$apache_user = substr($original_user, 0, 7)."+";
	}

	# figure out how much RAM is in the server
	our $available_mem = `free | grep \"Mem:\" | awk \'{ print \$2 }\'` / 1024;
	$available_mem = floor($available_mem);

	if ( ! $NOINFO ) { show_info_box(); print "Your server has ${CYAN}$available_mem MB${ENDC} of PHYSICAL memory.\n" }

	# check 14
	# determine what the max clients setting is 
	# if apache2.4 get maxrequestworkers 
	if ( our $apache_version =~ m/.*\s*\/2.4.*/) {
		our $maxclients = find_master_value(\@config_array, $model, 'maxrequestworkers');
		if($maxclients eq 'CONFIG NOT FOUND') {
			if ( ! $NOWARN ) { show_warn_box; print "MaxRequestWorkers directive not found, assuming default values.\n" }
			if ( $model eq "prefork") {
				# Default for prefork - see http://httpd.apache.org/docs/current/mod/mpm_common.html#maxrequestworkers 
				$maxclients = 256; # yes, yes I know, but keeping the variable name saves a whole bunch of code just for semantics.
			} else {
				# Default for Worker
				$maxclients = 16; # yes, yes I know, but keeping the variable name saves a whole bunch of code just for semantics.
			}
				
		}
		# account for '\x{d}' strangeness
		$maxclients =~ s/\x{d}//;
		$maxclients =~ s/\s//;
		if ( ! $NOINFO ) { show_info_box();  print "Your MaxRequestWorkers setting is ${CYAN}$maxclients${ENDC}.\n" }
	} else {
		# otherwise, assume 2.2 and get maxclients
		our $maxclients = find_master_value(\@config_array, $model, 'maxclients');
		if($maxclients eq 'CONFIG NOT FOUND') {
			if ( ! $NOWARN ) { show_warn_box; print "MaxClients directive not found, assuming default values.\n" }
			if ( $model eq "prefork") {
				# Default for prefork - see http://httpd.apache.org/docs/current/mod/mpm_common.html#maxrequestworkers 
				$maxclients = 256; # yes, yes I know, but keeping the variable name saves a whole bunch of code just for semantics.
			} else {
				# Default for Worker
				$maxclients = 16; # yes, yes I know, but keeping the variable name saves a whole bunch of code just for semantics.
			}
		}
		# account for '\x{d}' strangeness
		$maxclients =~ s/\x{d}//;
		$maxclients =~ s/\s//;
		if ( ! $NOINFO ) { show_info_box();  print "Your MaxClients setting is ${CYAN}$maxclients${ENDC}.\n" }
	}
	
	# Check 15
	# Get serverlimit value	
	our $serverlimit = find_master_value(\@config_array, $model, 'serverlimit');
	if($serverlimit eq 'CONFIG NOT FOUND') {
		if ( ! $NOWARN ) { show_warn_box; print "ServerLimit directive not found, assuming default values.\n" }
			our $model;
			if ( $model eq "prefork") {
				# Default for prefork - see http://httpd.apache.org/docs/current/mod/mpm_common.html#maxrequestworkers 
				$serverlimit = 256; # yes, yes I know, but keeping the variable name saves a whole bunch of code just for semantics.
			} else {
				# Default for Worker
				$serverlimit = 16; # yes, yes I know, but keeping the variable name saves a whole bunch of code just for semantics.
			}
	}
	# account for '\x{d}' strangeness
	$serverlimit =~ s/\x{d}//;
	if ( ! $NOINFO ) { show_info_box();  print "Your ServerLimit setting is ${CYAN}$serverlimit${ENDC}.\n" }
	
	# Check 16
	#calculate ThreadsPerChild. This is useful for the worker MPM calculations
	if ( $model eq "worker") {
		our $threadsperchild = find_master_value(\@config_array, $model, 'threadsperchild');
		if($threadsperchild eq 'CONFIG NOT FOUND') {
			if ( ! $NOWARN ) { show_warn_box; print "ThreadsPerChild directive not found, assuming default values.\n" }
			$threadsperchild = 25;
		}
		if ( ! $NOINFO ) { show_info_box();  print "Your ThreadsPerChild setting is ${CYAN}$threadsperchild${ENDC}.\n" }
	}
	our $threadsperchild;
	if ($model eq "worker") {
		if ( ! $NOINFO ) { show_info_box(); print "Your ThreadsPerChild setting for worker MPM is  ".$threadsperchild."\n" }
		if ( ! $NOINFO ) { show_info_box(); print "Your ServerLimit setting for worker MPM is  ".$serverlimit."\n" }
	}

	# Check 16b
	# Display the PHP Memory Limit
	# Note that we do nothing with this in terms of calculations
	# Use it as a conversation starter, esp if memoty_limit is 3GB! as this is a per-process setting!
	# get the PHP memory limit
	# This has been abstracted to a separate subroutine
	detect_php_memory_limit();

	# Check 17 : Other Services
	# This has been abstracted out into a separate subroutine
	detect_additional_services();

	# Check 18 : Maxclients Hits
	# This has been abstracted out into a separate subroutine
	detect_maxclients_hits($model, $process_name);
}

sub detect_maxclients_hits {
	our ($model, $process_name) = @_;
	if ($model eq "worker") {
		return;
	} else {
		print "\n${PURPLE}Detecting If Maxclients or MaxRequestWorkers has been hit recently....${ENDC}\n";
	}
	our $hit = 0;
	if ($process_name eq "/usr/sbin/httpd") {
		our $maxclients_hits = `grep -i reached /var/log/httpd/error_log | tail -5`;
	} else {
		our $maxclients_hits = `grep -i reached /var/log/apache2/error.log | tail -5`;
	}
	our $maxclients_hits;
	if ($maxclients_hits) {
		$hit = 1;
	}
	our $hit;
	if ($hit) {
		show_warn_box();
		print "${YELLOW}MaxClients has been hit recently (maximum of 5 results shown), consider the dates and times below:${ENDC}\n";
		print $maxclients_hits;
	} else {
		show_ok_box();
		print "${GREEN}MaxClients has not been hit recently.${ENDC}\n";
		return;
	}
		
}	


sub detect_php_memory_limit {
	
	print "\n${PURPLE}Detecting PHP Memory Limits...${ENDC}\n";
	
	our $apache_proc_php = get_php_setting('/usr/bin/php', 'memory_limit');
	show_info_box(); print "Your PHP Memory Limit (Per-Process) is ${CYAN}".$apache_proc_php." MB${ENDC}.\n"; # exempt from  NOINFO filter.
}

sub get_service_memory_usage_mbytes {
	my ( $svc )  = @_;
	my @usage_by_pids = `ps -C $svc -o rss | grep -v RSS`;
	our $usage_mbytes = 0;
	foreach my $proc (@usage_by_pids) {
		our $usage_mbytes += $proc / 1024;
	}
	our $usage_mbytes = round($usage_mbytes);
	
	return $usage_mbytes;
}


sub detect_additional_services() {
	
	if ( ! $NOINFO ) { print "\n${PURPLE}Detecting additional services for consideration...${ENDC}\n" }
	
	# Detect Mysql
	our $mysql_detected = 0;
	our $mysql_detected = `ps -C mysqld -o rss | grep -v RSS`;
	if ( $mysql_detected ) {
		if ( ! $NOINFO ) { show_info_box(); print "${CYAN}MySQL${ENDC} Detected => " } 
		# Get MySQL Memory Usage
		our $mysql_memory_usage_mbytes = get_service_memory_usage_mbytes("mysqld");
		if ( ! $NOINFO ) { print "Using ${CYAN}$mysql_memory_usage_mbytes MB${ENDC} of memory.\n" }
	} else {
		our $mysql_memory_usage_mbytes = 0;
	}
	
	# Detect Java
	our $java_detected = 0;
	$java_detected = `ps -C java -o rss | grep -v RSS`;
	if ( $java_detected ) { if ( ! $NOINFO ) { show_info_box(); print "${CYAN}Java${ENDC} Detected => " } }
	# Get Java Memory Usage
	if ( $java_detected ) {
		our $java_memory_usage_mbytes = get_service_memory_usage_mbytes("java");
		if ( ! $NOINFO ) { print "Using ${CYAN}$java_memory_usage_mbytes MB${ENDC} of memory.\n" }
	} else {
		our $java_memory_usage_mbytes = 0;
	}

	# Detect Varnish
	our $varnish_detected = 0;
	$varnish_detected = `ps -C varnishd -o rss | grep -v RSS`;
	if ( $varnish_detected ) { 
		if ( ! $NOINFO ) { show_info_box(); print "${CYAN}Varnish${ENDC} Detected => " }
		# Get varnish Memory Usage
		our $varnish_memory_usage_mbytes = get_service_memory_usage_mbytes("varnishd");
		if ( ! $NOINFO ) { print "Using ${CYAN}$varnish_memory_usage_mbytes MB${ENDC} of memory.\n" }
	} else {
		our $varnish_memory_usage_mbytes = 0;
	}

	# Detect Redis
	our $redis_detected = 0;
	$redis_detected = `ps -C redis-server -o rss | grep -v RSS`;
	if ( $redis_detected ) { 
		if ( ! $NOINFO ) { show_info_box(); print "${CYAN}Redis${ENDC} Detected => " }
		# Get Redis Memory Usage
		our $redis_memory_usage_mbytes = get_service_memory_usage_mbytes("redis-server");
		if ( ! $NOINFO ) { print "Using ${CYAN}$redis_memory_usage_mbytes MB${ENDC} of memory.\n" }
	} else {
		our $redis_memory_usage_mbytes = 0;
	}

	# Detect Memcache
	our $memcache_detected = 0;
	$memcache_detected = `ps -C memcached -o rss | grep -v RSS`;
	if ( $memcache_detected ) { 
		if ( ! $NOINFO ) { show_info_box(); print "${CYAN}Memcache${ENDC} Detected => " }
		# Get Memcache Memory Usage
		our $memcache_memory_usage_mbytes = get_service_memory_usage_mbytes("memcached");
		if ( ! $NOINFO ) { print "Using ${CYAN}$memcache_memory_usage_mbytes MB${ENDC} of memory.\n" }
	} else {
		our $memcache_memory_usage_mbytes = 0;
	}

	# Detect PHP-FPM
	our $phpfpm_detected = 0;
	# Get PHP-FPM Memory Usage
	$phpfpm_detected = `ps -C php-fpm -o rss | grep -v RSS` || `ps -C php5-fpm -o rss | grep -v RSS` || 0;
	if ( $phpfpm_detected ) { 
		# Get PHP-FPM Memory Usage
		our $phpfpm = 0;
		our $phpfpm = `ps -C php-fpm -o rss | grep -v RSS`; 
		our $php5fpm = 0;
		our $php5fpm = `ps -C php5-fpm -o rss | grep -v RSS`; 
		if ( $phpfpm ) {
			if ( ! $NOINFO ) { show_info_box(); print "${CYAN}PHP-FPM${ENDC} Detected => " }
			our $phpfpm_memory_usage_mbytes = get_service_memory_usage_mbytes("php-fpm");
		} elsif ( $php5fpm ) {
			if ( ! $NOINFO ) { show_info_box(); print "${CYAN}PHP5-FPM${ENDC} Detected => " }
			our $phpfpm_memory_usage_mbytes = get_service_memory_usage_mbytes("php5-fpm");
		}
		our $phpfpm_memory_usage_mbytes;
		if ( ! $NOINFO ) { print "Using ${CYAN}$phpfpm_memory_usage_mbytes MB${ENDC} of memory.\n" }
	} else {
		our $phpfpm_memory_usage_mbytes = 0;
	}

	# Detect Gluster
	our $gluster_detected = 0;
	$gluster_detected = `ps -C glusterd -o rss | grep -v RSS`;
	if ( $gluster_detected ) { 
		if ( ! $NOINFO ) { show_info_box(); print "${CYAN}Gluster${ENDC} Detected => " }
		# Get Gluster Memory Usage
		our $glusterd_memory_usage_mbytes = get_service_memory_usage_mbytes("glusterd");
		our $glusterfs_memory_usage_mbytes = get_service_memory_usage_mbytes("glusterfs");
		our $glusterfsd_memory_usage_mbytes = get_service_memory_usage_mbytes("glusterfsd");
		our $gluster_memory_usage_mbytes = $glusterd_memory_usage_mbytes + $glusterfs_memory_usage_mbytes + $glusterfsd_memory_usage_mbytes;
		if ( ! $NOINFO ) { print "Using ${CYAN}$gluster_memory_usage_mbytes MB${ENDC} of memory.\n" }
	} else {
		our $gluster_memory_usage_mbytes = 0;
	}

}

########################
# BEGIN MAIN EXECUTION #
########################

# if the user has added the help flag, or if they have defined a port  
if ( $help eq 1 || $port eq 0 ) {
	usage();
	exit;
}

# print the header
print_header();

# do the preflight checks
preflight_checks();

our $hostname;
our $public_ip_address;
our @config_array;
our $apache_user;
our $model;
our $process_name;
our $available_mem;
our $maxclients;
our $threadsperchild;
our $serverlimit;
our $mysql_detected;
our $mysql_memory_usage_mbytes;
our $java_detected;
our $java_memory_usage_mbytes;
our $redis_detected;
our $redis_memory_usage_mbytes;
our $memcache_detected;
our $memcache_memory_usage_mbytes;
our $varnish_detected;
our $varnish_memory_usage_mbytes;
our $phpfpm_detected;
our $phpfpm_memory_usage_mbytes;
our $gluster_memory_usage_mbytes;

if ( ! $NOINFO ) { print "\n${PURPLE}Analyzing apache memory use...${ENDC}\n" }

# Detect httpd
our $httpd_detected = 0;
our $httpd_detected = `ps -C httpd -o rss | grep -v RSS`;
if ( $httpd_detected ) {
if ( ! $NOINFO ) { show_info_box(); print "${CYAN}httpd${ENDC} " }
        # Get httpd Memory Usage
        our $httpd_memory_usage_mbytes = get_service_memory_usage_mbytes("httpd");
        if ( ! $NOINFO ) { print "is currently using ${CYAN}$httpd_memory_usage_mbytes MB${ENDC} of memory.\n" }
} else {
        our $httpd_memory_usage_mbytes = 0;
}
# Detect apache2 
our $apache2_detected = 0;
our $apache2_detected = `ps -C apache2 -o rss | grep -v RSS`;
if ( $apache2_detected ) {
if ( ! $NOINFO ) { show_info_box(); print "${CYAN}apache2${ENDC} " }
        # Get apache2 Memory Usage
        our $apache2_memory_usage_mbytes = get_service_memory_usage_mbytes("apache2");
        if ( ! $NOINFO ) { print "is currently using ${CYAN}$apache2_memory_usage_mbytes MB${ENDC} of memory.\n" }
} else {
        our $apache2_memory_usage_mbytes = 0;
}

my $apache_proc_highest = get_memory_usage($process_name, $apache_user, 'high');
my $apache_proc_lowest = get_memory_usage($process_name, $apache_user, 'low');
my $apache_proc_average = get_memory_usage($process_name, $apache_user, 'average');


if ( $model eq "prefork") {
	if ( ! $NOINFO ) { show_info_box(); print "The smallest apache process is using ${CYAN}$apache_proc_lowest MB${ENDC} of memory\n" }
	if ( ! $NOINFO ) { show_info_box(); print "The average apache process is using ${CYAN}$apache_proc_average MB${ENDC} of memory\n" }
	if ( ! $NOINFO ) { show_info_box(); print "The largest apache process is using ${CYAN}$apache_proc_highest MB${ENDC} of memory\n" }

	if ( ! $NOINFO ) { print "\n${PURPLE}Results...${ENDC}\n" }
	my $average_potential_use = $maxclients * $apache_proc_average;
	$average_potential_use = round($average_potential_use);
	my $average_potential_use_pct = round(($average_potential_use/$available_mem)*100);
	# Calculate percentages of remaining RAM, after services considered:
	my $memory_remaining = $available_mem - $mysql_memory_usage_mbytes - $java_memory_usage_mbytes - $redis_memory_usage_mbytes - 
	$memcache_memory_usage_mbytes - $varnish_memory_usage_mbytes - $phpfpm_memory_usage_mbytes - $gluster_memory_usage_mbytes;
	my $average_potential_use_pct_remain = round(($average_potential_use/$memory_remaining)*100);
	if ( $average_potential_use_pct > 100  or $average_potential_use_pct_remain > 100 ) {
		show_crit_box();
		print "Going by the average Apache process, Apache can potentially use ${RED}$average_potential_use MB${ENDC} RAM:\n";
		if ( $average_potential_use_pct > 100 ) {
			print "\t\tWithout considering services: ${RED}$average_potential_use_pct \%${ENDC} of total installed RAM\n";
		} else {
			print "\t\tWithout considering services: ${CYAN}$average_potential_use_pct \%${ENDC} of total installed RAM\n";
		}
		if ( $average_potential_use_pct_remain > 100 ) {
			print "\t\tConsidering extra services: ${RED}$average_potential_use_pct_remain \%${ENDC} of remaining RAM\n";
		} else {
			print "\t\tConsidering extra services: ${CYAN}$average_potential_use_pct_remain \%${ENDC} of remaining RAM\n";
		}
	} else {
       		if ( ! $NOINFO ) {
			show_ok_box();
			print "Going by the average Apache process, Apache can potentially use ${CYAN}$average_potential_use MB${ENDC} RAM:\n" .
				"\t\tWithout considering services: ${CYAN}$average_potential_use_pct \%${ENDC} of total installed RAM\n" .
				"\t\tConsidering extra services: ${CYAN}$average_potential_use_pct_remain \%${ENDC} of remaining RAM\n";
		 }
	}

	my $highest_potential_use = $maxclients * $apache_proc_highest;
	$highest_potential_use = round($highest_potential_use);
	my $highest_potential_use_pct = round(($highest_potential_use/$available_mem)*100);
	# Calculate percentages of remaining RAM, after services considered:
	my $highest_potential_use_pct_remain = round(($highest_potential_use/$memory_remaining)*100);
	if ( $highest_potential_use_pct > 100  or $highest_potential_use_pct_remain > 100 ) {
		show_crit_box();
		print "Going by the largest Apache process, Apache can potentially use ${RED}$highest_potential_use MB${ENDC} RAM:\n";
		if ( $average_potential_use_pct > 100 ) {
			print "\t\tWithout considering services: ${RED}$highest_potential_use_pct \%${ENDC} of total installed RAM\n";
		} else {
			print "\t\tWithout considering services: ${CYAN}$highest_potential_use_pct \%${ENDC} of total installed RAM\n";
		}
		if ( $average_potential_use_pct_remain > 100 ) {
			print "\t\tConsidering extra services: ${RED}$highest_potential_use_pct_remain \%${ENDC} of remaining RAM\n";
		} else {
			print "\t\tConsidering extra services: ${CYAN}$highest_potential_use_pct_remain \%${ENDC} of remaining RAM\n";
		}
	} else {
	       	if ( ! $NOINFO ) { 
			show_ok_box();
			print "Going by the largest Apache process, Apache can potentially use ${CYAN}$highest_potential_use MB${ENDC} RAM:\n" .
				"\t\tWithout considering services: ${CYAN}$highest_potential_use_pct %${ENDC} of total installed RAM\n" . 
				"\t\tConsidering extra services: ${CYAN}$highest_potential_use_pct_remain %${ENDC} of remaining RAM\n"; 
		}
	}
}
if ( $model eq "worker") {
	if ( ! $NOINFO ) { show_info_box(); print "The largest apache process is using ${CYAN}$apache_proc_highest MB${ENDC} of memory\n" }
	if ( ! $NOINFO ) { show_info_box(); print "The smallest apache process is using ${CYAN}$apache_proc_lowest MB${ENDC} of memory\n" }
	if ( ! $NOINFO ) { show_info_box(); print "The average apache process is using ${CYAN}$apache_proc_average MB${ENDC} of memory\n" }
}

if ( ! $NOINFO ) { print "\n${PURPLE}Generating reports...${ENDC}\n" }
generate_standard_report($available_mem, $maxclients, $apache_proc_lowest, $apache_proc_average, $apache_proc_highest, $model, $threadsperchild, $mysql_memory_usage_mbytes, $java_memory_usage_mbytes, $redis_memory_usage_mbytes, $memcache_memory_usage_mbytes, $varnish_memory_usage_mbytes, $phpfpm_memory_usage_mbytes, $gluster_memory_usage_mbytes);
