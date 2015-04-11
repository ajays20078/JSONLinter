#!/usr/bin/perl
use enum;
use strict;
use Switch ;
use Scalar::Util qw(looks_like_number);
my $file="1.json";
open(FILEHANDLER,$file) or die "Cannot open $file \n";
my $CurrentState = "None";

#              OSAS  OSTS  ASAS  ASTS  CS   CMS  KS  VS  OPSS
#  OSAS         0     1     0     0     0    0   1   0    0
#  OSTS         0     0     0     0     0    0   0   0    0
#  OPSS         0     1     0     0     0    1   0   0    1
#  ASAS         0     0     0     1     0    0   0   1    0
#  ASTS         0     0     0     0     0    1   1   0    1
#  CS           1     0     1     0     0    0   0   1    0
#  KS           0     0     0     0     1    0   0   0    0
#  VS           0     0     0     0     0    1   0   0    1
#  CMS          0     0     0     0     0    0   1   1    0


use enum qw(START=-1 OBJECTSTARTSTATE=0 OBJECTSTOPSTATE=1 OBJECTPOSSIBLESTOPSTATE=2 ARRAYSTARTSTATE=3 ARRAYSTOPSTATE=4 COLONSTATE=5 KEYSTATE=6 VALUESTATE=7 COMMASTATE=8 );
my $linenumber=1; ##To Keep track of line numbers
my $currentline="";
my $current_pos = 0;
my $currentstate = START;
my $err="";
my $currentopenobject=0;	
my $char;
while(1) {
	seek(FILEHANDLER,$current_pos,0);
	read FILEHANDLER, $char, 1;
	print "reading $char : $current_pos :$currentstate \n";
	if(ord($char) eq 0 ){
		if($currentstate == OBJECTPOSSIBLESTOPSTATE and  $currentopenobject==0)
		{
			$currentstate=OBJECTSTOPSTATE;
		}
		last;
	}
	$currentline=$currentline.$char;
	if($char eq " ") { # ignore spaces
		$current_pos++;
		next;
	}
	if($char eq "\n") {
		$current_pos++;
		$linenumber=$linenumber+1;
		$currentline="";
		next;
	}
	$err = checkvalidstate($char);
	if($err ne "")
	{
		print "Error at LineNumber $linenumber - $currentline : $err";
		exit(0);
	}
}
if($currentstate != OBJECTSTOPSTATE) {
	print "Error at LineNumber $linenumber - $currentline : unexpected EOF!!";
	exit(0);
}

print "Valid JSON\n";

close(FILEHANDLER);
sub checkvalidstate()
{
	my $char = shift;
	switch ($currentstate) 
	{
		case (START)  		{  
						if ($char ne "{") {
							return "Invalid JSON, missing { at the start";
						}
						$currentstate = OBJECTSTARTSTATE;
						$current_pos=$current_pos+1;
						$currentopenobject=$currentopenobject+1;
						return "";
					}
		case(OBJECTSTARTSTATE)  {
						if ($char ne '"' and $char ne "}") {
							return "Expecting Key or } found $char";
						}
						if($char eq "}") {
							$currentstate=OBJECTPOSSIBLESTOPSTATE;
							$current_pos=$current_pos+1;
							$currentopenobject=$currentopenobject-1;
							return "";
						}else{ # if char equals double quotes
							$currentstate=KEYSTATE;
							$current_pos=$current_pos+1;
                                                        return "";
						}
					}
		case(KEYSTATE)  	{
						my $firstchar=1;
						while($char ne "\n" and $char ne '"')
                                                {
								if($firstchar) {
									$firstchar=0;
								}else {
                                                                	$currentline=$currentline.$char;
								}
                                                                if($char eq "\n") {
                                                                        return "Unexpected newline before closing double quotes";
                                                                }
                                                                $current_pos=$current_pos+1;
                                                               
								seek(FILEHANDLER,$current_pos,0);
								read FILEHANDLER, $char, 1;
								if(ord($char) eq 0 ) { return "Unexpected EOF";}
								while($char eq " " || $char eq "\n") {
									if($char eq "\n")
									{
										$linenumber=$linenumber+1;
										$currentline="";
									}
									$currentline=$currentline.$char;
									$current_pos=$current_pos+1;
									seek(FILEHANDLER,$current_pos,0);
									read FILEHANDLER, $char, 1;
                                                                	if(ord($char) eq 0) { return "Unexpected EOF";}
								}

								
                                                }
						$currentline=$currentline.$char;
						$current_pos=$current_pos+1;
						seek(FILEHANDLER,$current_pos,0);
                                                read FILEHANDLER, $char, 1;
                                                if(ord($char) eq 0) { return "Unexpected EOF";}
						while($char eq " " || $char eq "\n") {
                                                	if($char eq "\n")
                                                        {
                                                          	$linenumber=$linenumber+1;
                                                           	 $currentline="";
                                                  	}
							$currentline=$currentline.$char;
                                                    	$current_pos=$current_pos+1;
                                                     	seek(FILEHANDLER,$current_pos,0);
                                                      	read FILEHANDLER, $char, 1;
                                                        if(ord($char) eq 0) { return "Unexpected EOF";}
                                                 }
						if($char eq ":")
						{
                                                	$current_pos=$current_pos+1;
							$currentline=$currentline.$char;
                                                	$currentstate = COLONSTATE;
                                                	return "";
						}
						return "Invalid JSON, Expecting :, found $char";
					}
		case(COLONSTATE)	{
						$currentstate = VALUESTATE;
                                                return "";
					}
		case(VALUESTATE)   	{
						my $firstchar=1;
                                                my $string="";
                                                while($char ne "," and $char ne "[" and $char ne "{" and $char ne "}" and $char ne '"')
                                                {
                                                        $string=$string+$char;
                                                        if($firstchar){ $firstchar=0;
                                                        }else {
                                                                $currentline=$currentline.$char;
                                                        }
                                                        $current_pos=$current_pos+1;
                                                        seek(FILEHANDLER,$current_pos,0);
							read FILEHANDLER, $char, 1;
                                                        if(ord($char) eq 0) { return "Unexpected EOF";}
							while($char eq " " || $char eq "\n") {
                                                                        if($char eq "\n")
                                                                        {
                                                                                $linenumber=$linenumber+1;
                                                                                $currentline="";
                                                                        }
                                                                        $current_pos=$current_pos+1;
									read FILEHANDLER, $char, 1;
                                                                        $char=<FILEHANDLER>;
									if(ord($char) eq 0) { return "Unexpected EOF";}
                                                       }
                                                }
                                                if ($string eq "true" || $string eq "false" || $string eq "" || $string eq "null" || looks_like_number($string) || ( (substr $string,0,1) eq '"' and (substr $string,-1,1) eq '"') ) {

                                                        if ($char eq ","){
                                                                $current_pos=$current_pos+1;
                                                                $currentstate=COMMASTATE;
                                                                return "";
                                                        }
                                                        if ($char eq "["){
                                                                $current_pos=$current_pos+1;
                                                                $currentstate=ARRAYSTARTSTATE;
                                                                return "";
                                                        }
							if($char eq '{'){
                                        	                $currentstate=OBJECTSTARTSTATE; 
                                                	        $current_pos=$current_pos+1;
                                                        	$currentopenobject=$currentopenobject+1;
                                                       	 	return "";
                                                	}
							if($char eq '}'){
								$currentstate=OBJECTPOSSIBLESTOPSTATE;
								$current_pos=$current_pos+1;
								$currentopenobject=$currentopenobject-1;
								return "";
							}
					
                                                        return "Invalid JSON , Unexpected char $char, expecting , or ]";
                                                }
                                                return "Invalid JSON, Array element not a number/string/boolean/null";
						
					}
		case (ARRAYSTARTSTATE)	{
						my $firstchar=1;
						my $string="";
						while($char ne "," and $char ne "]") 
						{
							$string=$string+$char;
							if($firstchar){ $firstchar=0;
							}else {
								$currentline=$currentline.$char;
							}
							$current_pos=$current_pos+1;
                                                        seek(FILEHANDLER,$current_pos,0);
							read FILEHANDLER, $char, 1;
							if(ord($char) eq 0) { return "Unexpected EOF";}
							while($char eq " " || $char eq "\n") {
                                                                        if($char eq "\n")
                                                                        {
                                                                                $linenumber=$linenumber+1;
                                                                                $currentline="";
                                                                        }
                                                                        $current_pos=$current_pos+1;
                                                                        seek(FILEHANDLER,$current_pos,0);
									read FILEHANDLER, $char, 1;
                                                                        if(ord($char) eq 0) { return "Unexpected EOF";}
                                                        }
						}
						if ($string eq "true" || $string eq "false" || $string eq "null" || looks_like_number($string) || ( (substr $string,0,1) eq '"' and (substr $string,-1,1) eq '"') )	             {

							if ($char eq ","){
								$current_pos=$current_pos+1;
								$currentstate=COMMASTATE;
								return "";
							}
							if ($char eq "]"){
								$current_pos=$current_pos+1;
								$currentstate=ARRAYSTOPSTATE;
								return "";
							}
							return "Invalid JSON , Unexpected char $char, expecting , or ]";
				   		}
						return "Invalid JSON, Array element not a number/string/boolean/null";
					}
		case (ARRAYSTOPSTATE)	{
						if($char eq ","){
								$current_pos=$current_pos+1;
								$currentstate=COMMASTATE;
								return "";
						}
						if($char eq "}") {
								$current_pos=$current_pos+1;
				  				$currentstate=OBJECTPOSSIBLESTOPSTATE ;
								$currentopenobject=$currentopenobject-1;
								return "";
						}
						return "Invalid JSON, Expecting } or , found $char ";
					}
		case (COMMASTATE)	{
						$current_pos=$current_pos+1;
						 seek(FILEHANDLER,$current_pos,0);
                                                        read FILEHANDLER, $char, 1;
                                                        if(ord($char) eq 0) { return "Unexpected EOF";}
                                                        while($char eq " " || $char eq "\n") {
                                                                        if($char eq "\n")
                                                                        {
                                                                                $linenumber=$linenumber+1;
                                                                                $currentline="";
                                                                        }
                                                                        $current_pos=$current_pos+1;
                                                                        seek(FILEHANDLER,$current_pos,0);
                                                                        read FILEHANDLER, $char, 1;
                                                                        if(ord($char) eq 0) { return "Unexpected EOF";}
                                                        }
						$currentstate=VALUESTATE;
						return ""
					}
		case (OBJECTPOSSIBLESTOPSTATE) {
							
						 if($currentopenobject eq 0 ) {
						 	$currentstate=OBJECTSTOPSTATE;
							return "";
						 }
						 if($char eq ","){
							 $current_pos=$current_pos+1;
							 $currentstate=COMMASTATE;
							 return "";
						}
						if($char eq "}") {
							$current_pos=$current_pos+1;
                                                                $currentstate=OBJECTPOSSIBLESTOPSTATE ;
                                                                $currentopenobject=$currentopenobject-1;
                                                                return "";
                                                }
						return "Invalid JOSN, Unexpect char $char ";
					}
	case (OBJECTSTOPSTATE)		{
						if($char) {
							return "Invalid JSON, Object already completed";
						}
					}

		


	}
}




