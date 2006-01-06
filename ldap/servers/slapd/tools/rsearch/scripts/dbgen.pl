#!/usr/bin/perl

#------------------------------------------------------------------------
## Copyright 1997 - Netscape Communications Corporation
##
## NAME
##  dbgen
##
## DESCRIPTION
##  Random LDIF database creator, specially modified from DirectoryMark
##  Original weibe done by David Boreham in C++.   
##
##	Fixed random seed generator for uniqueness
##	Updated function MakeRandomName:
##		Changed default RDN type to UID and 
##		added -c option to enable CN type naming
##	Added personal_title and generationQualifier data
##	Added function to create randon SSN's if needed
##	Updated generation output to show total entries created regardless of -v option
##	Changed userPassword to be the same as UID.
##	Now, dc style namingcontext can be used.	
#------------------------------------------------------------------------


sub PrintUsage {
    print STDERR 
    	"Usage: $0 [options] -o output_file  -n number\n",
	"\t Where options are:\n",
	"\t -s suffix, default is 'dc=example,dc=com'\n",
	"\t -c for CN naming style RDN's : default is UID\n",
        "\t -O for organizationalPersons, default is inetOrgPerson\n",
	"\t -p for piranha style aci's, default is barracuda\n",
	"\t -r seed---seed number for random number generator\n",
	"\t -g print extra entries for orgchart\n",
	"\t -x suppress printing pre amble\n",
	"\t -y suppress printing organizational units\n",
	"\t -v verbose\n",
	"\t -q quiet\n",
	"\n";
    exit;
}

&PrintUsage if ($#ARGV == -1);

@EmployeeTypes = ("Manager", "Normal", "Peon");


@personal_title = ("Mr",
                   "Mrs",
                   "Miss",
                   "Senior",
                   "Junior",
                   "III",
                   "Cool");

@generationQ = ("I", 
		"II", 
		"III", 
		"IV", 
		"V", 
		"VI", 
		"VII");		   

@title_ranks = ("Senior", 
		"Master", 
		"Associate", 
		"Junior", 
		"Chief", 
		"Supreme",
		"Elite");

@positions   =("Accountant", 
	       "Admin", 
	       "Architect", 
	       "Assistant", 
	       "Artist", 
	       "Consultant", 
	       "Czar", 
	       "Dictator",
	       "Director", 
	       "Diva",
	       "Dreamer",
	       "Evangelist", 
	       "Engineer", 
	       "Figurehead", 
	       "Fellow",
	       "Grunt", 
	       "Guru",
	       "Janitor", 
	       "Madonna", 
	       "Manager", 
	       "Pinhead",
	       "President",
	       "Punk", 
	       "Sales Rep", 
	       "Stooge", 
	       "Visionary", 
	       "Vice President", 
	       "Writer", 
	       "Warrior", 
	       "Yahoo");

@localities = ("Mountain View", "Redmond", "Redwood Shores", "Armonk",
	       "Cambridge", "Santa Clara", "Sunnyvale", "Alameda",
	       "Cupertino", "Menlo Park", "Palo Alto", "Orem",
	       "San Jose", "San Francisco", "Milpitas", "Hartford", "Windsor",
	       "Boston", "New York", "Detroit", "Dallas", "Denver");

@area_codes = ("303", "415", "408", "510", "804", "818",
	       "213", "206", "714");

my $mycert =
"usercertificate;binary:: MIIBvjCCASegAwIBAgIBAjANBgkqhkiG9w0BAQQFADAnMQ8wDQYD\n VQQDEwZjb25maWcxFDASBgNVBAMTC01NUiBDQSBDZXJ0MB4XDTAxMDQwNTE1NTEwNloXDTExMDcw\n NTE1NTEwNlowIzELMAkGA1UEChMCZnIxFDASBgNVBAMTC01NUiBTMSBDZXJ0MIGfMA0GCSqGSIb3\n DQEBAQUAA4GNADCBiQKBgQDNlmsKEaPD+o3mAUwmW4E40MPs7aiui1YhorST3KzVngMqe5PbObUH\n MeJN7CLbq9SjXvdB3y2AoVl/s5UkgGz8krmJ8ELfUCU95AQls321RwBdLRjioiQ3MGJiFjxwYRIV\n j1CUTuX1y8dC7BWvZ1/EB0yv0QDtp2oVMUeoK9/9sQIDAQABMA0GCSqGSIb3DQEBBAUAA4GBADev\n hxY6QyDMK3Mnr7vLGe/HWEZCObF+qEo2zWScGH0Q+dAmhkCCkNeHJoqGN4NWjTdnBcGaAr5Y85k1\n o/vOAMBsZePbYx4SrywL0b/OkOmQX+mQwieC2IQzvaBRyaNMh309vrF4w5kExReKfjR/gXpHiWQz\n GSxC5LeQG4k3IP34\n";

%ceo =
(
	"uid" => "ceo",
	"givenname" => "John",
	"sn" => "Budd",
	"title" => "CEO",
	"cn" => "",
	"dn" => ""
);

%ep0 =
(
	"uid" => "exec_president0",
	"givenname" => "Paul",
	"sn" => "Grant",
	"title" => "Exective President",
	"cn" => "",
	"dn" => ""
);
%ep1 =
(
	"uid" => "exec_president1",
	"givenname" => "Jill",
	"sn" => "Peterson",
	"title" => "Exective President",
	"cn" => "",
	"dn" => ""
);
@exective_presidents = (\%ep0, \%ep1);

%p0 =
(
	"uid" => "president0",
	"givenname" => "Pete",
	"sn" => "Dunne",
	"title" => "President",
	"cn" => "",
	"dn" => ""
);
%p1 = 
(
	"uid" => "president1",
	"givenname" => "Jannet",
	"sn" => "Keys",
	"title" => "President",
	"cn" => "",
	"dn" => ""
);
%p2 = 
(
	"uid" => "president2",
	"givenname" => "Kathy",
	"sn" => "Yang",
	"title" => "President",
	"cn" => "",
	"dn" => ""
);
%p3 = 
(
	"uid" => "president3",
	"givenname" => "Anne",
	"sn" => "Meissner",
	"title" => "President",
	"cn" => "",
	"dn" => ""
);
@presidents = (\%p0, \%p1, \%p2, \%p3);

%vp0 = 
(
	"uid" => "vice_president0",
	"givenname" => "Jack",
	"sn" => "Cho",
	"title" => "Vice President",
	"cn" => "",
	"dn" => ""
);
%vp1 =
(
	"uid" => "vice_president1",
	"givenname" => "Diane",
	"sn" => "Smith",
	"title" => "Vice President",
	"cn" => "",
	"dn" => ""
);
%vp2 =
(
	"uid" => "vice_president2",
	"givenname" => "Alex",
	"sn" => "Merrells",
	"title" => "Vice President",
	"cn" => "",
	"dn" => ""
);
%vp3 =
(
	"uid" => "vice_president3",
	"givenname" => "Yumi",
	"sn" => "Mehta",
	"title" => "Vice President",
	"cn" => "",
	"dn" => ""
);
%vp4 =
(
	"uid" => "vice_president4",
	"givenname" => "Michael",
	"sn" => "Natkovich",
	"title" => "Vice President",
	"cn" => "",
	"dn" => ""
);
%vp5 =
(
	"uid" => "vice_president5",
	"givenname" => "Keith",
	"sn" => "Lucus",
	"title" => "Vice President",
	"cn" => "",
	"dn" => ""
);
@vice_presidents = (\%vp0, \%vp1, \%vp2, \%vp3, \%vp4, \%vp5);

%d0 =
(
	"uid" => "director0",
	"givenname" => "Chris",
	"sn" => "Harrison",
	"title" => "Director",
	"cn" => "",
	"dn" => ""
),
%d1 = 
(
	"uid" => "director1",
	"givenname" => "Jane",
	"sn" => "Baker",
	"title" => "Director",
	"cn" => "",
	"dn" => ""
);
%d2 = 
(
	"uid" => "director2",
	"givenname" => "Ed",
	"sn" => "Becket",
	"title" => "Director",
	"cn" => "",
	"dn" => ""
);
%d3 = 
(
	"uid" => "director3",
	"givenname" => "Will",
	"sn" => "Stevenson",
	"title" => "Director",
	"cn" => "",
	"dn" => ""
);
%d4 =
(
	"uid" => "director4",
	"givenname" => "Kieran",
	"sn" => "Beckham",
	"title" => "Director",
	"cn" => "",
	"dn" => ""
);
%d5 =
(
	"uid" => "director5",
	"givenname" => "Greg",
	"sn" => "Emerson",
	"title" => "Director",
	"cn" => "",
	"dn" => ""
);
%d6 =
(
	"uid" => "director6",
	"givenname" => "Ian",
	"sn" => "Parker",
	"title" => "Director",
	"cn" => "",
	"dn" => ""
);
%d7 =
(
	"uid" => "director7",
	"givenname" => "Liem",
	"sn" => "Olson",
	"title" => "Director",
	"cn" => "",
	"dn" => ""
);
%d8 =
(
	"uid" => "director8",
	"givenname" => "George",
	"sn" => "Cruise",
	"title" => "Director",
	"cn" => "",
	"dn" => ""
);
%d9 =
(
	"uid" => "director9",
	"givenname" => "Yoshiko",
	"sn" => "Tucker",
	"title" => "Director",
	"cn" => "",
	"dn" => ""
);
@directors = (\%d0, \%d1, \%d2, \%d3, \%d4, \%d5, \%d6, \%d7, \%d8, \%d9);

%m0 =
(
	"uid" => "manager0",
	"givenname" => "Teresa",
	"sn" => "Chan",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m1 =
(
	"uid" => "manager1",
	"givenname" => "Tom",
	"sn" => "Anderson",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m2 =
(
	"uid" => "manager2",
	"givenname" => "Olga",
	"sn" => "Young",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m3 =
(
	"uid" => "manager3",
	"givenname" => "Bill",
	"sn" => "Graham",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m4 =
(
	"uid" => "manager4",
	"givenname" => "Todd",
	"sn" => "Hoover",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m5 =
(
	"uid" => "manager5",
	"givenname" => "Ken",
	"sn" => "Hamilton",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m6 =
(
	"uid" => "manager6",
	"givenname" => "Christine",
	"sn" => "Jobs",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m7 =
(
	"uid" => "manager7",
	"givenname" => "Joanna",
	"sn" => "Lake",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m8 =
(
	"uid" => "manager8",
	"givenname" => "Kim",
	"sn" => "Remley",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m9 =
(
	"uid" => "manager9",
	"givenname" => "Nick",
	"sn" => "Pennebaker",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m10 =
(
	"uid" => "manager10",
	"givenname" => "Ted",
	"sn" => "Hardy",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m11 =
(
	"uid" => "manager11",
	"givenname" => "Tanya",
	"sn" => "Nielsen",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m12 =
(
	"uid" => "manager12",
	"givenname" => "Sam",
	"sn" => "Madams",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m13 =
(
	"uid" => "manager13",
	"givenname" => "Judy",
	"sn" => "Stewart",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m14 =
(
	"uid" => "manager14",
	"givenname" => "Martha",
	"sn" => "Kidman",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m15 =
(
	"uid" => "manager15",
	"givenname" => "Leo",
	"sn" => "Knuth",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m16 =
(
	"uid" => "manager16",
	"givenname" => "Cecil",
	"sn" => "Guibas",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
%m17 =
(
	"uid" => "manager17",
	"givenname" => "Jay",
	"sn" => "Hows",
	"title" => "Manager",
	"cn" => "",
	"dn" => ""
);
@managers = (\%m0, \%m1, \%m2, \%m3, \%m4, \%m5, \%m6, \%m7, \%m8, \%m9, \%m10, \%m11, \%m12, \%m13, \%m14, \%m15, \%m16, \%m17);

require "flush.pl";
require "getopts.pl";
&Getopts('n:o:s:r:cOvpqgxy');

$Number_To_Generate = $opt_n;
$Verbose = $opt_v;
$Quiet = $opt_q;
$Output_File_Name = $opt_o;
$Random_Seed = $opt_r || 0xdbdbdbdb;
$TargetServer = $opt_t;
$debug = $opt_d;
$Suffix = $opt_s || 'dc=example,dc=com';
$NamingType = "cn" if ($opt_c);
$NamingType = "uid" if (!$opt_c);
$inetOrgPerson = "objectClass: inetOrgPerson\n" if (!$opt_O);
$PrintOrgChartDat = $opt_g;
$printpreamble = 1;
if ("" != $opt_x)
{
    $printpreamble = 0;
}
$printorgunit = 1;
if ("" != $opt_y)
{
    $printorgunit = 0;
}

if ($Suffix =~ /o=/) {
    ($Organization) = $Suffix =~ /o=([^,]+)/;
    $objectvalue = "organization";
    $line = "o: $Organization";
    if ($Organization =~ /\s+/) {
        ($Organization) = $Organization =~ /([^\s]+)/;
        $Organization .= ".com";
    } elsif ($Organization !~ /\.com|\.net|\.org/) {
            $Organization .= ".com";
      }
} elsif ($Suffix =~ /dc=/) {
    $Organization = $Suffix;
    $Organization =~ s/,\s*dc=/./g;
    ($domain) = $Organization =~ /dc=([^\.]+)/;
    $Organization =~ s/dc=//;
    $objectvalue = "domain";
    $line = "dc: $domain";
}

# Print help message if user doesn't know how many entries to make
# or no output file specified
if ( (!$Number_To_Generate) || (!$Output_File_Name)) {
    &PrintUsage;
}

srand($Random_Seed);

print "Loading Name Data...\n" if $Verbose;

$DATADIR = "../data";
$GivenNamesFile = "$DATADIR/dbgen-GivenNames";
$FamilyNamesFile = "$DATADIR/dbgen-FamilyNames";
$OrgUnitsFile    = "$DATADIR/dbgen-OrgUnits";
&ReadGivenNames;
&ReadFamilyNames;
&ReadOrgUnits;

print "Done\n" if $Verbose;


if ($printpreamble)
{
	if ($piranha) {
    	&PrintPreAmblePiranha($Output_File_Name);
	}
	else {
    	&PrintPreAmbleBarracuda($Output_File_Name);
	}
}

open (OUTPUT_FILE, ">>$Output_File_Name") || 
    die "Error---Can't open output file $Output_File_Name\n";

if ($printorgunit)
{
	&PrintOrganizationalUnits;
}

if ($PrintOrgChartDat)
{
	# CEO
	&PrintManagers(\%ceo, "", $ceo{"dn"});
	
	for (my $j = 0; $j < @exective_presidents; $j++)
	{
		&PrintManagers($exective_presidents[$j], &MakeRandomOrgUnit, $ceo{"dn"});
	}
	
	# Presidents
	for (my $j = 0; $j < @presidents; $j++)
	{
		my $who = int rand @exective_presidents;
		&PrintManagers($presidents[$j],
		    &MakeRandomOrgUnit, $exective_presidents[$who]{"dn"});
	}
	
	# Vice Presidents
	for (my $j = 0; $j < @vice_presidents; $j++)
	{
		my $who = int rand @presidents;
		&PrintManagers($vice_presidents[$j],
			&MakeRandomOrgUnit, $presidents[$who]{"dn"});
	}
	
	# Directors
	for (my $j = 0; $j < @directors; $j++)
	{
		my $who = int rand @vice_presidents;
		&PrintManagers($directors[$j],
			&MakeRandomOrgUnit, $vice_presidents[$who]{"dn"});
	}
	
	# Managers
	for (my $j = 0; $j < @managers; $j++)
	{
		my $who = int rand @directors;
		&PrintManagers($managers[$j],
			&MakeRandomOrgUnit, $directors[$who]{"dn"});
	}
}

print "Generating $Number_To_Generate entries, please wait\n";

print "Progress: ";
# We don't want people with duplicate names, so for each name generated,
# add it to "TheMap", which is an associative array with the
# name as the key. If there's a duplicate, throw the name out and
# try again. 

$dups = 0;

# Generate Number_To_Generate distinct entries. If a duplicate
# is created, toss it out and try again.


# CHANGED: updated to allow for uid naming style or cn style. Check the RDN for uniqueness
for ($x= 0; $x < $Number_To_Generate; $x++) {

    ($givenName, $sn, $cn, $uid, $rdn,) = &MakeRandomName;
    if (&AddAndCheck($rdn)) {
        print "Duplicate: $rdn...\n" if $debug;
        &flush(STDOUT);
        $dups++;
        $x--;
        next;
    }
    $OrgUnit          = &MakeRandomOrgUnit;
    $facsimileTelephoneNumber = &MakeRandomTelephone;
    $postalAddress    = &MakeRandomPostalAddress (
                                                  int rand 1000, 
                                                  int rand 1000,
                                                  $OrgUnit);
    $postOfficeBox    = int rand 10000;
    $telephoneNumber  = &MakeRandomTelephone;
    $title        = &MakeRandomTitle($OrgUnit);
#    $userPassword = reverse ($cn);
#    $userPassword =~ s/\s//g;
#    $userPassword = substr($userPassword, 0, 10);
    $locality     = &MakeRandomLocality;
#   $desc  = "[0] This is $cn" . "'s description.";
    $fourdigit = int rand 10000;
    $desc  = "2;$fourdigit;CN=Red Hat CS 71GA Demo,O=Red Hat CS 71GA Demo,C=US;CN=RHCS Agent - admin01,UID=admin01,O=redhat,C=US";

	my $z = 1;
#   for (; $z < 1024; $z++)
	for (; $z < 2; $z++)
	{
		$desc = $desc . " [$z] This is $cn" . "'s description.";
	}
	$description = $desc;
    $mail         = &MakeMailAddress($givenName, $sn, $Organization);
    


    if ($inetOrgPerson) {
        $carLicense        = "carLicense: " . &MakeRandomCarLicense . "\n";
        $departmentNumber  = "departmentNumber: " . (int rand 10000) . "\n";
        $employeeType      = "employeeType: " . &MakeRandomEmployeeType . "\n";
        $homePhone         = "homePhone: " . &MakeRandomTelephone . "\n";
        $initials          = "initials: " . &MakeInitials ($givenName, $sn) . "\n";
        $mobile            = "mobile: " . &MakeRandomTelephone . "\n";
        $pager             = "pager: "  . &MakeRandomTelephone . "\n";
        if ($PrintOrgChartDat) {
            $managerCn    = $managers[int rand @managers]{"dn"};
        } else {
            $managerCn    = $managers[int rand @managers]{"givenname"} . " " .
                            $managers[int rand @managers]{"sn"};
        }
        ($junk, $junk, $secretary_cn) = &MakeRandomName;
        $manager           = "manager: $managerCn " . "\n";
        $secretary         = "secretary: $secretary_cn" . "\n";
        $roomNumber        = "roomNumber: " . (int rand 10000) . "\n";
        $userPassword      = "$uid\n";
    }
    
 if ($PrintOrgChartDat) {
   $dnstr = "dn: $NamingType=$rdn, ou=People, $Suffix\n",
 } else {
   $dnstr = "dn: $NamingType=$rdn, ou=$OrgUnit, $Suffix\n";
 }

 print OUTPUT_FILE
             $dnstr,
             "objectClass: top\n",
             "objectClass: person\n",
             "objectClass: organizationalPerson\n",
             $inetOrgPerson, 
             "cn: $cn\n",
             "sn: $sn\n",
             "uid: $uid\n",
             "givenName: $givenName\n",
             "description: $description\n",
             "userPassword: $userPassword",
             $departmentNumber,
             $employeeType,
             $homePhone,
             $initials,
             "telephoneNumber: $telephoneNumber\n",
             "facsimileTelephoneNumber: $facsimileTelephoneNumber\n",
             $mobile,
             $pager,
             $manager,
             $secretary,
             $roomNumber,
             $carLicense,
             "l: $locality\n",
             "ou: $OrgUnit\n",
             "mail: $mail\n",
             "postalAddress: $postalAddress\n",
             "title: $title\n",
             $mycert,
             "\n";
    
    if (!$Quiet) {
        if ($x % 1000  == 0) {
            print ".";
            &flush(STDOUT);
        }
    }
  
}

print "\n";
print "Generated $x entries\n";

if ($Verbose) {
    print "$dups duplicates skipped\n";
}

exit 0;
	       

sub ReadOrgUnits {
    open (ORG_UNITS, $OrgUnitsFile) ||
	die "Bad news, failed to open Org Units, $OrgUnitsFile: $!\n";
    while(<ORG_UNITS>) {
	chop;
	push (@OrganizationalUnits, $_);
    }
    close ORG_UNITS;
}


sub ReadGivenNames {
    open (GIVEN_NAMES, $GivenNamesFile) || 
	die "Bad News, failed to load given names. $GivenNamesFile\n";
    $i = 0;
    while (<GIVEN_NAMES>) {
	chop;
	$given_names[$i++] = $_;
    }
    close GIVEN_NAMES;
}

sub ReadFamilyNames {
    open (FAMILY_NAMES, $FamilyNamesFile) ||
	die "Bad News, failed to load Family Names. $FamilyNamesFile\n";
    
    $i = 0;
    while (<FAMILY_NAMES>) {
	chop;
	$family_names[$i++] = $_;
    }
    close FAMILY_NAMES;
}



sub PrintPreAmblePiranha {
    local($output_file) = @_;

    open (OUTPUT_FILE, ">$output_file") || die "Can't open $output_file for writing $!\n";
    print OUTPUT_FILE<<End_Of_File
dn: $Suffix
objectClass: top
objectClass: $objectvalue
$line
subtreeaci: +(&(privilege=write)(target=ldap:///self))
subtreeaci: +(privilege=compare)
subtreeaci: +(|(privilege=search)(privilege=read))

End_Of_File
    ;
    
    close (OUTPUT_FILE);
    
}

sub PrintPreAmbleBarracuda {
    local($output_file) = @_;

    open (OUTPUT_FILE, ">$output_file") || die "Can't open $output_file for writing $!\n";
    
    print OUTPUT_FILE<<End_Of_File
dn: $Suffix
objectClass: top
objectClass: $objectvalue
$line
aci: (target=ldap:///$Suffix)(targetattr=*)(version 3.0; acl "acl1"; allow(write) userdn = "ldap:///self";) 
aci: (target=ldap:///$Suffix)(targetattr=*)(version 3.0; acl "acl2"; allow(write) groupdn = "ldap:///cn=Directory Administrators, $Suffix";)
aci: (target=ldap:///$Suffix)(targetattr=*)(version 3.0; acl "acl3"; allow(read, search, compare) userdn = "ldap:///anyone";)

End_Of_File
    ;
    close (OUTPUT_FILE);
}

sub PrintPreAmbleNoACI {
    local($output_file) = @_;

    open (OUTPUT_FILE, ">$output_file") || die "Can't open $output_file for writing $!\n";
 
    print OUTPUT_FILE<<End_Of_File
dn: $Suffix
objectClass: top
objectClass: organization
o: $Organization

End_Of_File
    ;
    close (OUTPUT_FILE);
    
}



sub PrintOrganizationalUnits {
    foreach $ou (@OrganizationalUnits) {
        print OUTPUT_FILE 
            "dn: ou=$ou, $Suffix\n",
            "objectClass: top\n",
            "objectClass: organizationalUnit\n",
            "ou: $ou\n\n";
    }
	if ($PrintOrgChartDat) {
        print OUTPUT_FILE 
            "dn: ou=People, $Suffix\n",
            "objectClass: top\n",
            "objectClass: organizationalUnit\n",
            "ou: People\n\n";
	}
}

sub PrintManagers {
    my ($obj, $orgUnit, $managerCn) = @_;

	my $rdn = $$obj{"$NamingType"};
    my $uid = $$obj{"uid"};
    my $givenName = $$obj{"givenname"};
    my $sn = $$obj{"sn"};
    my $title = $$obj{"title"};
    $$obj{"cn"} = "$givenName $sn";
    my $cn = $$obj{"cn"};

    $facsimileTelephoneNumber = &MakeRandomTelephone;
    $postalAddress    = &MakeRandomPostalAddress (
                          int rand 1000, 
                          int rand 1000,
                          $OrgUnit);
    $postOfficeBox    = int rand 10000;
    $telephoneNumber  = &MakeRandomTelephone;
    $locality     = &MakeRandomLocality;
    $description  = "This is $cn" . "'s description";
    $mail         = &MakeMailAddress($givenName, $sn, $Organization);

	$$obj{"dn"} = "$NamingType=$rdn, ou=People, $Suffix";

    if ($inetOrgPerson) {
        $carLicense        = "carLicense: " . &MakeRandomCarLicense . "\n";
        $departmentNumber  = "departmentNumber: " . (int rand 10000) . "\n";
        $employeeType      = "employeeType: " . $title . "\n";
        $homePhone         = "homePhone: " . &MakeRandomTelephone . "\n";
        $initials          = "initials: " . &MakeInitials ($givenName, $sn) . "\n";
        $mobile            = "mobile: " . &MakeRandomTelephone . "\n";
        $pager             = "pager: "  . &MakeRandomTelephone . "\n";
        ($junk, $junk, $secretary_cn) = &MakeRandomName;
		if ("" ne $managerCn) {
        	$manager           = "manager: $managerCn\n";
		}
        $secretary         = "secretary: $secretary_cn" . "\n";
        $roomNumber        = "roomNumber: " . (int rand 10000) . "\n";
        $userPassword      = "$uid\n";
    }
    
    $dnstr = "dn: $NamingType=$rdn, ou=People, $Suffix\n";
    if ("" ne $orgUnit) {
        $oustr = "ou: $orgUnit\n";
    }

 print OUTPUT_FILE
         $dnstr,
         "objectClass: top\n",
         "objectClass: person\n",
         "objectClass: organizationalPerson\n",
         $inetOrgPerson, 
         "cn: $cn\n",
         "sn: $sn\n",
         "uid: $uid\n",
         "givenName: $givenName\n",
         "description: $description\n",
         "userPassword: $userPassword",
         $departmentNumber,
         $employeeType,
         $homePhone,
         $initials,
         "telephoneNumber: $telephoneNumber\n",
         "facsimileTelephoneNumber: $facsimileTelephoneNumber\n",
         $mobile,
         $pager,
         $manager,
         $secretary,
         $roomNumber,
         $carLicense,
         "l: $locality\n",
         $oustr,
         "mail: $mail\n",
         "postalAddress: $postalAddress\n",
         "title: $title\n",
         $mycert,
         "\n";
}

sub MakeRandomTitle {
    local($org_unit) = @_;
    return 
	"$title_ranks[rand @title_ranks] $org_unit $positions[rand @positions]";
}

sub MakeRandomLocality {
    return $localities[rand @localities];
}
    

    
sub MakeRandomName {
    local($Given_Name, $Surname, $Full_Name, $UID, $uniq, $first, $last, $RDN);
    # Get the unique number depending if a seed was set or not.
    $uniq = int rand($Random_Seed) if ($opt_r);
    $uniq = $x if (!$opt_r);

    $Given_Name   = $given_names[rand @given_names];
    $Surname      = $family_names[rand @family_names];
    $Full_Name = "$Given_Name $Surname";
    
    # Create the uid based on the DN naming type defined
    if ($NamingType eq "uid") {
	    $first = substr($Given_Name, 0,1);
	    $last = substr($Surname, 0,8);
	    $UID = $first . $last . "$uniq";
	    $RDN = $UID;
    }
    else
    {
	    $first = substr($Given_Name, 0,1);
	    $last = substr($Surname, 0,8);
	    $UID = $first . $last . "$uniq";
    	    $RDN = $Full_Name;
    }

    
    return ($Given_Name, $Surname, $Full_Name, $UID, $RDN);
}


sub MakeRandomOrgUnit {
    return $OrganizationalUnits[rand @OrganizationalUnits];
}


sub MakeRandomTelephone {
    local($prefix, $suffix, $Phone_Number);
    $prefix = int rand(900) + 100; 
    $suffix = int rand(9000) + 1000;

    return $Phone_Number = "+1 " . $area_codes[rand @area_codes] . " " .
	"$prefix-$suffix";

}

sub MakeRandomSSN {
    local($one, $two, $three, $SSN);
    $one = int rand(900) +99; 
    $two = int rand(90) +9;
    $three = int rand(9000) + 999;

    return $SSN = "$one-$two-$three";

}
    
sub MakeRandomEmployeeType {
    return $EmployeeTypes[rand @EmployeeTypes];
}

sub MakeRandomPersonalTitle {
    return $personal_title[rand @personal_title];
}

sub MakeRandomCarLicense {
    local ($rand_char_index, $ascii_value, $license);
 
    for (1..7) {
        $rand_char_index = int rand 36;
        $ascii_value = ($rand_char_index > 9) ? $rand_char_index + 55 : 
	    $rand_char_index + 48;
        $license .= pack ("c", $ascii_value);
    }
    return $license;
}

# All entries are added to TheMap which checks to see
# if the name is already there
sub AddAndCheck {
    local($RDN) = @_;
    # now isn't this better than STL?
    if ($TheMap{$RDN}) {
	return 1;
    }
    else {
	$TheMap{$RDN} = 1;
	return 0;
    }
}

sub MakeMailAddress {
    local($given_name, $sur_name, $Organization) = @_;
    
    return "$given_name". "_$sur_name\@$Organization";
}
       

sub MakeRandomPostalAddress {
    local ($org, $departmentNumber,$roomNumber, $OrgUnit) = @_;
    return "$org, $OrgUnit Dept \#$departmentNumber, Room\#$roomNumber";
}


sub MakeInitials {
    local ($givenName, $sn) = @_;
    local ($first, $last);
    
    ($first) = $givenName =~ /^(\w).*/;
    ($last)  = $sn        =~ /^(\w).*/;
    return "$first" . ". " . "$last" . ".";
}



