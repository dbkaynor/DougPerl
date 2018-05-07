package UtilsDBK;

use 5.6.1;
use strict;
use warnings;
use Carp;
#use Win32::OLE('in');
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION = '1.10';
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw(
  TRUE FALSE ON OFF YES NO PI
  Trim TrimArray
  RemoveBlanksArray RemoveDuplicatesArray
  PadL PadC PadR
  SortData
  UCArray LCArray
  ExcludeFromArray IncludeInArray
  Array2Textbox Textbox2Array
  Array2File File2Array
  AddPathSlash FixPathSlash
  FormatTime
  Bool2YesNo Bool2TrueFalse Bool2OnOff
  Commify SimplifySize
  BITS2Dec BIN2Dec OCT2Dec HEX2Dec DEC2Dec
  HEX2Bin HEX2Bits
  GetDOSTree GetDOSDir
  DriveList ParsePath StartUpInfo

);

%EXPORT_TAGS = ( all => [@EXPORT_OK] );

#----------------------------------
#Boolean constants
use constant TRUE  => scalar 1;
use constant FALSE => scalar 0;
use constant ON    => scalar 1;
use constant OFF   => scalar 0;
use constant YES   => scalar 1;
use constant NO    => scalar 0;

#The following are constants used for the directory functions
use constant ALL   => scalar 0;
use constant DIRS  => scalar 1;
use constant FILES => scalar 2;

#Other constants
use constant PI => 4 * atan2( 1, 1 );

#----------------------------------
sub Trim(@) {
    my @in = @_;
    chomp(@in);
    for (@in) {
        s/^\s+//;
        s/\s+$//;
    }
    return wantarray ? @in : $in[0];
}

#----------------------------------
sub TrimArray($) {
    my ($Array) = @_;
    chomp(@$Array);
    for (@$Array) {
        s/^\s+//;
        s/\s+$//;
    }
}

#----------------------------------
sub RemoveBlanksArray($) {
    my ($Array) = @_;
    my @out = ();
    foreach $_ (@$Array) {
        if ( length( Trim($_) ) != 0 ) {
            push @out, $_;
        }
    }
    @$Array = @out;
}

#----------------------------------
sub RemoveDuplicatesArray($) {
    my ($Array) = @_;
    my %Hash;
    foreach $_ (@$Array) {
        $Hash{"$_"} = '';
    }

    @$Array = ();
    while ( my ( $first, $last ) = each(%Hash) ) {
        push @$Array, $first;
    }
}

#----------------------------------
sub UCArray(@) {
    foreach (@_) {
        $_ = uc($_);
    }
    return wantarray ? @_ : $_[0];
}

#----------------------------------
sub LCArray(@) {
    foreach (@_) {
        $_ = lc($_);
    }
    return wantarray ? @_ : $_[0];
}

#----------------------------------
sub ExcludeFromArray($$) {
    my ( $Array, $Excludelist ) = @_;
    my @tmp = ();
    foreach my $A (@$Array) {
        my $cnt = 0;
        foreach my $E (@$Excludelist) {
            if ( $A =~ /$E/i ) { $cnt++ }
        }
        if ( $cnt == 0 ) { push( @tmp, $A ) }
    }
    @$Array = @tmp;
    @tmp    = ();
}

#----------------------------------
sub IncludeInArray($$) {
    my ( $Array, $Includelist ) = @_;
    my @tmp = ();
    foreach my $A (@$Array) {
        my $cnt = 0;
        foreach my $I (@$Includelist) {
            if ( $A =~ /$I/i ) { $cnt++ }
        }
        unless ( $cnt == 0 ) { push( @tmp, $A ) }
    }
    @$Array = @tmp;
    @tmp    = ();
}

#----------------------------------
# sub CheckForDupsInArray($$;$) {
# }
#----------------------------------
sub RandomizeData($) {
    my $Array = @_;
    use vars qw/@TS $a $b $c/;

    @TS = ();
    $c  = 0;
    for ( $a = 0 ; $a < @$Array ; $a++ ) {
        do {
            $c++;
            $b = int( rand(@$Array) );
        } until not defined( $TS[$b] );
        $TS[$b] = @$Array[$a];
    }
    @$Array = @TS;
}

#----------------------------------
sub SortData($$$) {
    my ( $Array, $Reverse, $Case ) = @_;

    if ( $Reverse == TRUE ) {    # Do a reverse sort
        if ( $Case == TRUE ) {
            @$Array = sort { $b cmp $a } @$Array;
        }
        else {
            @$Array = sort { uc($b) cmp uc($a) } @$Array;
        }
    }
    else {
        if ( $Case == TRUE )     # Do a normal sort
        {
            @$Array = sort { $a cmp $b } @$Array;
        }
        else {
            @$Array = sort { uc($a) cmp uc($b) } @$Array;
        }
    }
}

#----------------------------------
sub PadL($$;$) {
    my ( $instr, $outlength, $padcharacter ) = @_;
    unless ($padcharacter) { $padcharacter = ' ' }
    my $inlength = length($instr);
    if ( $inlength >= $outlength ) { return $instr }
    my $t = $padcharacter x ( $outlength - $inlength );
    return $t . $instr;
}

#----------------------------------
sub PadC($$;$) {
    my ( $instr, $outlength, $padcharacter ) = @_;
    unless ($padcharacter) { $padcharacter = ' ' }
    my $inlength = length($instr);
    if ( $inlength >= $outlength ) { return $instr }
    my $t = $padcharacter x ( ( $outlength - $inlength ) / 2 );
    my $u = $t . $instr . $t;
    return PadL( $u, $outlength, $padcharacter );
}

#----------------------------------
sub PadR($$;$) {
    my ( $instr, $outlength, $padcharacter ) = @_;
    unless ($padcharacter) { $padcharacter = ' ' }
    my $inlength = length($instr);
    if ( $inlength >= $outlength ) { return $instr }
    my $t = $padcharacter x ( $outlength - $inlength );
    return $instr . $t;
}

#----------------------------------
sub AddPathSlash($) {
    my $s = $_[0];
    if ( $s =~ /\\$/ ) {
        return $s;
    }
    else {
        return $s . '\\';
    }
}

#----------------------------------
sub FixPathSlash($) {
    my $s = $_[0];
    $s =~ s/\//\\/g;      #reverse backwards slashes
    $s =~ s/\\\\/\\/g;    #remove duplicate slases
    return $s;
}

#----------------------------------
sub FormatTime($) {
    my $Seconds = shift;
    my $Days    = int( $Seconds / 86400 );
    $Seconds -= $Days * 86400;
    my $Hours = int( $Seconds / 3600 );
    $Seconds -= $Hours * 3600;
    my $Minutes = int( $Seconds / 60 );
    $Seconds -= $Minutes * 60;
    return sprintf( '%2d days %2d hours %2d minutes %2d seconds',
        $Days, $Hours, $Minutes, $Seconds );
}

#----------------------------------
sub Bool2YesNo($) {
    if    ( $_[0] == TRUE )  { return 'YES' }
    elsif ( $_[0] == FALSE ) { return 'NO ' }
    else { return 'Bool2YesNo error' }
}

#----------------------------------
sub Bool2TrueFalse($) {
    if    ( $_[0] == TRUE )  { return 'TRUE ' }
    elsif ( $_[0] == FALSE ) { return 'FALSE' }
    else { return 'Bool2TrueFalse error' }
}

#----------------------------------
sub Bool2OnOff($) {
    if    ( $_[0] == TRUE )  { return 'ON ' }
    elsif ( $_[0] == FALSE ) { return 'OFF' }
    else { return 'Bool2OnOff error' }
}

#----------------------------------
sub Commify($) {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

#----------------------------------
sub SimplifySize($) {
    my $x       = 0;
    my $sizeval = '';
    my $size    = $_[0];

    while ( ( $size >= 1024 ) && ( $x < 4 ) ) {
        $size /= 1024;
        $x++;
    }

    if    ( $x == 0 ) { $sizeval = ' B' }
    elsif ( $x == 1 ) { $sizeval = ' KB' }
    elsif ( $x == 2 ) { $sizeval = ' MB' }
    elsif ( $x == 3 ) { $sizeval = ' GB' }
    elsif ( $x == 4 ) { $sizeval = ' TB' }

    return Commify( int( $size * 100 ) / 100 ) . $sizeval;
}

#----------------------------------
# numeric conversions
sub BITS2Dec($) {
    my $result = 0;
    my @list = split( /\D/, substr( Trim(@_), 4 ) );
    foreach (@list) {
        if (/\d/) {
            $result += 2**$_;
        }
    }
    return $result;
}

#----------------------------------
sub BIN2Dec($) {
    my $result = 0;
    my $count  = 0;
    my @list   = split( //, substr( Trim(@_), 4 ) );
    foreach ( reverse(@list) ) {
        if (/[^ ,0,1]/) {
            $result = -1;
            return ($result);
        }
        if (/[0,1]/) {
            $result += 2**$count * $_;
            $count++;
        }
    }
    return "$result";
}

#----------------------------------
sub OCT2Dec($) {
    my $result = 0;
    my $count  = 0;
    my @list   = split( //, substr( Trim(@_), 4 ) );
    foreach ( reverse(@list) ) {
        if (/[^ ,0-7]/) {
            $result = -1;
            return ($result);
        }
        if (/[0-7]/) {
            $result += $_ * ( 8**$count );
            $count++;
        }
    }
    return "$result";
}

#----------------------------------
sub HEX2Dec($) {
    my $result = 0;
    my $count  = 0;
    my @list   = split( //, substr( Trim(@_), 4 ) );
    foreach ( reverse(@list) ) {
        if (/[^ ,0-9,A-F,a-f]/) {
            $result = -1;
            return ($result);
        }
        if (/[0-9,A-F,a-f]/) {
            $result += hex($_) * ( 16**$count );
            $count++;
        }
    }
    return "$result";
}

#----------------------------------
sub DEC2Dec($) {
    my $result = 0;
    my $count  = 0;
    my @list   = split( //, substr( Trim(@_), 4 ) );
    foreach ( reverse(@list) ) {
        if (/[^ ,0-9,.,\,]/) {
            $result = -1;
            return ($result);
        }
        if (/[0-9]/) {
            $result += $_ * ( 10**$count );
            $count++;
        }
    }
    return "$result";
}

#----------------------------------
sub HEX2Bin($) {
    my $result = '';
    my @list = split( //, Trim(@_) );
    foreach (@list) {
        if (/[^ ,0-9,A-F,a-f]/) {
            $result = -1;
            return ($result);
        }
        if    (/0/i) { $result .= '0000 ' }
        elsif (/1/i) { $result .= '0001 ' }
        elsif (/2/i) { $result .= '0010 ' }
        elsif (/3/i) { $result .= '0011 ' }
        elsif (/4/i) { $result .= '0100 ' }
        elsif (/5/i) { $result .= '0101 ' }
        elsif (/6/i) { $result .= '0110 ' }
        elsif (/7/i) { $result .= '0111 ' }
        elsif (/8/i) { $result .= '1000 ' }
        elsif (/9/i) { $result .= '1001 ' }
        elsif (/a/i) { $result .= '1010 ' }
        elsif (/b/i) { $result .= '1011 ' }
        elsif (/c/i) { $result .= '1100 ' }
        elsif (/d/i) { $result .= '1101 ' }
        elsif (/e/i) { $result .= '1110 ' }
        elsif (/f/i) { $result .= '1111 ' }
        else { $result .= ' ' }
    }
    return Trim($result);
}

#----------------------------------
sub HEX2Bits($) {
    my $result = '';
    my $count  = 0;
    my $tmp    = HEX2Bin( Trim(@_) );
    print "$tmp\n";
    my @list = split( //, $tmp );
    foreach ( reverse(@list) ) {
        if (/[01]/) {
            if (/1/) {
                $result .= " $count";
            }
            $count++;
        }
    }
    return Trim($result);
}

#----------------------------------
#recursive (used by GetDOSTree)
sub GetDOSDirs($$$) {
    my ( $working_dir, $tmparray, $control ) = @_;

    #   print "GetDOSDirs>>>$working_dir<<<>>>$$control<<<\n";
    unless ( opendir DIR, $working_dir ) {
        warn "Unable to open $working_dir $!";
        return;
    }
    while ( readdir DIR ) {
        if ( $$control ne 'run' ) { last }
        foreach $_ ( readdir DIR ) {
            if ( ( -d $working_dir . '\\' . $_ ) && ( $_ ne '..' ) ) {
                push @$tmparray, $working_dir . '\\' . $_;
            }    #if
        }    #foreach
    }    #while
    closedir DIR;
}    #sub

#----------------------------------
#recursively gets all directories and files under topdir (uses GetDOSDirs)
sub GetDOSTree($$$;$) {
    my ( $topdir, $DOSdirsdone, $DOSfilesdone, $control ) = @_;
    my $ControlText = 'run';
    unless ($control) { $control = \$ControlText }

    #  print "GetDOSTree>>>$topdir<<<>>>$$control<<<\n";
    my @DOSDirectoriesTemp =
      ();    #This is used to store new directories when found
    push @$DOSdirsdone, $topdir;
    GetDOSDirs( $topdir, \@DOSDirectoriesTemp, $control );

    while (@DOSDirectoriesTemp) {
        if ( $$control ne 'run' ) { last }
        $a = pop @DOSDirectoriesTemp;
        push @$DOSdirsdone, $a;
        GetDOSDirs( $a, \@DOSDirectoriesTemp, $control );
    }        #while

    @$DOSdirsdone = sort @$DOSdirsdone;

    foreach my $dir (@$DOSdirsdone) {
        if ( $$control ne 'run' ) { last }
        unless ( opendir DIR, $dir ) {
            warn "Unable to open $dir $!";
            next;
        }
        while ( readdir DIR ) {
            if ( $$control ne 'run' ) { last }
            foreach $_ ( readdir DIR ) {
                unless ( -d $dir . '\\' . $_ ) {
                    push @$DOSfilesdone, $dir . '\\' . $_;
                }
            }    #foreach
        }    #while
        closedir DIR;
    }
    @$DOSfilesdone      = sort @$DOSfilesdone;
    @DOSDirectoriesTemp = ();
}

#----------------------------------
#not recursive
sub GetDOSDir($$;$$) {
    my ( $topdir, $DOSfilesdone, $control, $IncludeOptions ) = @_;
    unless ($IncludeOptions) { $IncludeOptions = ALL }
    unless ($control)        { $control        = 'run' }
    unless ( opendir DIR, $topdir ) {
        warn "ERROR: GetDOSFiles. Unable to open $topdir $!";
        return "ERROR: GetDOSFiles. Unable to open $topdir $!";
    }
    unless ( $IncludeOptions eq FILES ) { push @$DOSfilesdone, $topdir }
    while ( readdir DIR ) {
        if ( $control ne 'run' ) { last }
        foreach $_ ( readdir DIR ) {
            if (   ( $IncludeOptions == ALL )
                || ( ( $IncludeOptions == DIRS ) && ( -d $topdir . '\\' . $_ ) )
                || (   ( $IncludeOptions == FILES )
                    && ( !-d $topdir . '\\' . $_ ) ) )
            {
                push @$DOSfilesdone, $topdir . '\\' . $_;
            }
        }    #foreach
    }    #while
    closedir DIR;
    @$DOSfilesdone = sort @$DOSfilesdone;
}

#----------------------------------
# Options
#  0 = drive letter only (undefined also)
#  1 = formated
#  2 = raw
sub DriveList($;$) {
    my ( $DriveList, $Option ) = @_;
    unless ($Option) { $Option = 0 }

    use constant wbemFlagReturnImmediately => 0x10;
    use constant wbemFlagForwardOnly       => 0x20;

    my $computer      = ".";
    my $objWMIService =
      Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2")
      or die "WMI connection failed.\n";
    my $colItems = $objWMIService->ExecQuery( "SELECT * FROM Win32_LogicalDisk",
        "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly );

    foreach my $objItem ( in $colItems) {
        unless ( $objItem->{FileSystem} ) { $objItem->{FileSystem} = 'none' }
        ;    #prevent warning for no disk
        unless ( $objItem->{Size} )      { $objItem->{Size}      = 0 }
        unless ( $objItem->{FreeSpace} ) { $objItem->{FreeSpace} = 0 }
        if ( $Option == 0 ) {    # drive letter only
            push( @$DriveList, sprintf $objItem->{Name} );
        }
        elsif ( $Option == 1 ) {    # Formated
            my $ts = sprintf "%-2s %-5s %-25s %16s %16s", $objItem->{Name},
              $objItem->{FileSystem}, $objItem->{Description},
              Commify( $objItem->{Size} ), Commify( $objItem->{FreeSpace} );
            push( @$DriveList, $ts );

            # print "$ts\n";
        }
        elsif ( $Option == 2 ) {    # Raw  seperated by ~ tilde
            my $ts = sprintf "%s~%s~%s~%s~%s", $objItem->{Name},
              $objItem->{FileSystem}, $objItem->{Description}, $objItem->{Size},
              $objItem->{FreeSpace};
            push( @$DriveList, $ts );

            # print "$ts\n";
        }
        else {                      # Unknown option
            push( @$DriveList, 'Unknown option at Drivelist: ' . $Option );
        }
    }
}

#----------------------------------
sub ParsePath($) {
    my $FullPathName = $_[0];
    my $Drive        = ( split( '\\\\', $FullPathName ) )[0];
    my $NameExt      = ( split( '\\\\', $FullPathName ) )[-1];
    my $Ext          = ( split( '\.', $NameExt ) )[-1];
    my $Name = substr( $NameExt, 0, length($NameExt) - length($Ext) - 1 );
    my $Path =
      substr( $FullPathName, 0, length($FullPathName) - length($NameExt) );
    return ( $FullPathName, $Drive, $Path, $NameExt, $Name, $Ext );
}    #----------------------------------

sub Array2Textbox($$) {
    my ( $ListBox, $Array ) = @_;
    $ListBox->delete( '0.0', 'end' );
    foreach (@$Array) {
        $_ = Trim($_);
        if ( length($_) > 0 ) {
            $ListBox->insert( 'end', $_ . "\n" );
        }
    }
}

#----------------------------------
sub Textbox2Array($$) {
    my ( $ListBox, $Array ) = @_;
    @$Array = ();

    my $end = ( split( /\./, $ListBox->index('end') ) )[0];

    #  print ">>$end<<\n";

    for ( my $X = 0 ; $X < $end ; $X++ ) {
        my $C = Trim( $ListBox->get( "$X.0", "$X.end" ) );
        if ($C) {
            push( @$Array, $C );
        }
    }
}

#----------------------------------
sub Array2File($$) {
    my ( $FileName, $Array ) = @_;
    open FILE, ">$FileName";
    print FILE join "\n", @$Array;
    close FILE;
}

#----------------------------------
sub File2Array($$) {
    my ( $FileName, $Array ) = @_;
    open FILE, "$FileName";
    @$Array = <FILE>;
    close FILE;
}

#----------------------------------

sub StartUpInfo {
    my %Res = ();
    my @T   = split( '\\\\', $0 );
    my $d   = pop(@T);

    $Res{'StartDIR'}   = Trim(`cd`);
    $Res{'StartDrive'} = ( split ':', Trim(`cd`) )[0];

    # my $TempDir = $ENV{TEMP};
    $Res{'ScriptNameExt'} = $d;

    my @z = split '\.', $d;
    $Res{'ScriptName'} = $z[0];
    $Res{'ScriptExt'}  = $z[1];
    my $sp = join '\\', @T;
    unless ($sp) { $sp = '.' }
    $Res{'ScriptPath'}  = $sp;
    $Res{'ScriptDrive'} = ( split ':', $sp )[0];

    return \%Res;

}

#----------------------------------
return TRUE;

#----------------------------------
__END__

=pod

=head1 NAME

UtilsDBK.pm - Various utilities (mostly string related)

=head2 SYNOPSIS

use UtilsDBK qw(:all);				#Imports all functions
use UtilsDBK qw(Trim UCArray);		#Imports specific functions
use UtilsDBK 'Trim';				#Imports a function

=head2 DESCRIPTION

This module is consists of various utilities for perl. Mostly string related.

=head2 Constants

Booleans
TRUE 1
FALSE 0
ON 1
OFF 0
YES 1
NO 0
PI 3.1415....

=head2 Trim

Returns the input string with leading and trailing white spaces and CR/LF removed.

=head2 TrimArray

Trim all lines from an array of strings. Accepts a pointer to an array.

=head2 RemoveBlanksArray

Remove all blank lines from an array of strings. Accepts a pointer to an array.


=head2 RemoveDuplicatesArray

Remove all duplicate lines from an array of lines.  Accepts a pointer to an array.

=head2 PadL PadC PadR

Pads the input argument. All three functions take as inputs an input string, a length value and an optional pad character. If the pad character is not included spaces will be used.

=head2 UCArray LCArray

Convert an entire array (list) of strings or characters to either upper or lower case.

=head2 ExcludeFromArray

Takes two parameters, a pointer to an array of data and a pointer to an array of exclude items. Removes any strings that match the specified exclude list from the array. Supports regular expressions and is not case sensitive.

=head2 IncludeInArray

Takes two parameters, a pointer to an array of data and a pointer to an array of include items. Includes strings that match the specified include list in the array. Supports regular expressions and is not case sensitive.

=head2 RemoveDuplicatesFromArray

Removes exact duplicate lines from a sorted array of strings

=head2 SortData

Does a sort the data in an array. Takes three parameters, a pointer to an array of data, reverse and case. If reverse is true the data is reverse sorted. If the case parameter is true the sort is case sensitive.

=head2 RandomizeData

Randomizes the data in an array. Takes a pointer to an array of data.

=head2 AddPathSlash

Adds a trailing slash (\) to the end of the argument if needed and returns the resulting string.

=head2 FixPathSlash

Reverses backwards slashes.
Removes duplicate slases.
Returns the resulting string

=head2 FormatTime

Returns a formated time string. More details to come.

=head2 Bool2YesNo Bool2TrueFalse Bool2OnOff

Three functions that return a string consisting of Yes/No, True/False or On/Off depending on the value passed to the function.

=head2 Commify

Accepts a decimal number string and returns the decimal number string with commas added where appropriate.

=head2 SimplifySize

Accepts a decimal number string and returns a simplified string. More to come

=head2 BITS2Dec BIN2Dec OCT2Dec

BITS2Dec LSB is 0. More to come

=head2 HEX2Dec

Accepts a string of hexadecimal characters and returns a decimal value. The input string may include spaces, commas and/or periods which are all ignored. Other characters will cause the subroutine to return -1.

=head2 DEC2Dec

Accepts a string of decimal characters and returns a decimal value. The input string may include spaces, commas and periods which are ignored. It basically cleans up the input string. The input must equate to a positive integer value. Other characters or values will cause the subroutine to return -1. Currently the subroutine does not accept scientific notation.

=head2 Hex2Bin

Accepts a string of hexadecimal characters and returns a binary string. The input string may include spaces, commas and periods which are inserted into the output string as spaces.

=head2 HEX2Bits

Accepts a string of hexadecimal characters and returns a string of numbers corresponding to the bits that are equal to one. The input string may include spaces, commas and periods which are ignored. LSB is 0.

=head2 GetDOSTree

Accepts a path string, pointers to two arrays and an optional control string. The path string may be absolute or relative. The pointer arrrays are as follows: the first points to a sorted list of directories and the second is a sorted list of files in those directories. Be sure to clear the arrays before calling so as not to get duplicate items.

=head2 GetDOSDir

Accepts a path string, a pointer to one array and an option. The path string may be absolute or relative. The array will contain a sorted list of directories and\or files in the directory pointed to by the path string. The option may be empty or one of the following: ALL, DIRS or FILES. It defaults to ALL. GetDOSDir is non-recursive. Be sure to clear the arrays before calling so as not to get duplicate items.

=head2 DriveList

Accepts a pointer to an array and one option. The array is a sorted list of logical disk drives with description and file system type. Options are as follows
#  0 = drive letter only (undefined also)
#  1 = formated
#  2 = raw

=head2 ParsePath

Accepts a path name and returns an array of the parts.
A list of caveats follows: TBD more to come

=head2 Textbox2Array

TBD more to comE

=head2 Array2Textbox

TBD more to comE

=head2 StartUpInfo
Accepts a pointer to a hash. Returns the hash filled with script startup information.
The keys are StartDIR, StartDrive, ScriptNameExt, ScriptName, ScriptExt, ScriptPath, ScriptDrive

=head2 AUTHOR

Doug Kaynor <doug@kaynor.net>

=cut
