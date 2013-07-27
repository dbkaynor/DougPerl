#!/bin/perl -w
use strict;
use warnings;

#use diagnostics;
use UtilsDBK qw(:all);
use POSIX;
use Tk;
use Tk::BrowseEntry;
use Tk::Checkbutton;
use Tk::Dialog;
use Tk::DialogBox;
use Tk::LabEntry;
use Tk::Pane;
use Tk::JPEG;
use Tk::PNG;
use Image::Magick;
use feature ':5.14';    # loads all features available in perl 5.14
use Time::HiRes qw/usleep/;

sub BackgroundColorSet;
sub BackgroundRandomColorSet;
sub GetDisplayParameters;
sub DrawButton;
sub CalcMovement;
sub DoTheMove;
sub LoopIt;
sub ChangeDirection;
sub DrawSquare($$$);
sub CollisionTest;
sub ClearButton;
sub LockControls($);
sub ShowCanvasArray;
sub Help;
sub PostScriptOut;
sub Log($);
sub DebugMode;
sub PhotoOnCanvas;

my $PerlNamePath = ( ( split( '\.',   $0 ) )[0] );
my $PerlName     = ( ( split( '\\\\', $PerlNamePath ) )[-1] );
my $LogFileName  = $PerlName . '.log';

#Directions constants
use constant N  => scalar 0b1;
use constant NW => scalar 0b10;
use constant W  => scalar 0b100;
use constant SW => scalar 0b1000;
use constant S  => scalar 0b10000;
use constant SE => scalar 0b100000;
use constant E  => scalar 0b1000000;
use constant NE => scalar 0b10000000;
my @DirectionArray = qw(N NW W SW S SE E NE);
my @CanvasArray    = ();

my $Direction        = 'N';
my $CurrentXLocation = 0;
my $CurrentYLocation = 0;
my $CurrentXLocationSave;
my $CurrentYLocationSave;

my $TextvariableDirection = '';
my $TextvariableYPosition = '';
my $TextvariableXPosition = '';

my $ForegroundColor     = 'White~#FFFFFF';
my $BackgroundColor     = 'Black~#000000';
my $FixedSize           = FALSE;
my $AutoForegroundColor = 'Never';
my $AutoBackgroundColor = FALSE;
my $AutoBlockSize       = FALSE;
my $NoWalls             = FALSE;
my $AutoClear           = TRUE;
my $LoopingComplete     = TRUE;
my $Photo               = FALSE;
my $Debug               = FALSE;
my $Speed               = 500;

use constant MinimumSpeed => scalar 0;
use constant MaximumSpeed => scalar 2000;

use constant MinimumBlockSize => scalar 2;
use constant MaximumBlockSize => scalar 100;
my $BlockSize = 20;

my $MaximumX = 0;    #This is pixels width
my $MaximumY = 0;    #This is pixels height

my $MaximumXBlocks = 0;    #This is blocks width
my $MaximumYBlocks = 0;    #This is blocks height
my $CanvasTotalBlocks;     #Total blocks

my $MainWindowGeometry;
my $Canvas;

my @ColorList = ();

my $MainWindow = MainWindow->new( '-title' => $PerlName );

$MainWindow->minsize( 400, 400 );
$MainWindow->maxsize( $MainWindow->screenwidth, $MainWindow->screenheight );

$MainWindow->geometry('1050x650+10+100');

$MainWindow->resizable( TRUE, TRUE );
$MainWindow->bind(
    '<Configure>',
    [
        sub {
            if ( $_[0] =~ /MainWindow/i ) {
                $MainWindowGeometry = $MainWindow->geometry();
                $MainWindow->title("$PerlName $MainWindowGeometry<<<");
                ( $MaximumX, my $y ) = split( /x/, $MainWindowGeometry );
                ($MaximumY) = split( /\+/, $y );
            }
          }
    ]
);

#---------------------------------------------------------------------------
my $Menu_frame =
  $MainWindow->Scrolled( qw/Pane -scrollbars osw/, -width => 250 )
  ->pack( -side => 'left', -fill => 'y', -expand => '0' );
my $Canvas_frame = $MainWindow->Frame()->pack( -side => 'left', -fill => 'both', -expand => '1' );

my $One_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Two_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Three_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Four_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Five_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Six_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );

my $B1_frame = $One_frame->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );

$B1_frame->Button( -text => 'Clear', -width => 10, -command => \&ClearButton )
  ->pack( -side => 'right' );
$B1_frame->Button( -text => 'Draw', -width => 10, -command => \&DrawButton )
  ->pack( -side => 'left' );

my $B3_frame = $One_frame->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Up_button = $B3_frame->Button(
    -text    => 'Up',
    -width   => 10,
    -command => sub {
        $Canvas->move( 'all', 0, $MaximumY / 20 * -1 );
    }
)->pack( -side => 'left' );

my $Down_button = $B3_frame->Button(
    -text    => 'Down',
    -width   => 10,
    -command => sub {
        $Canvas->move( 'all', 0, $MaximumY / 20 );
    }
)->pack( -side => 'right' );

my $B4_frame = $One_frame->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );

my $Left_button = $B4_frame->Button(
    -text    => 'Left',
    -width   => 10,
    -command => sub {
        $Canvas->move( 'all', $MaximumX / 20 * -1, 0 );
    }
)->pack( -side => 'left' );

my $Right_button = $B4_frame->Button(
    -text    => 'Right',
    -width   => 10,
    -command => sub {
        $Canvas->move( 'all', $MaximumX / 20, 0 );
    }
)->pack( -side => 'right' );

my $B5_frame = $One_frame->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $PostScriptOut_button = $B5_frame->Button(
    -text    => 'PS out',
    -width   => 10,
    -command => \&PostScriptOut
)->pack( -side => 'left' );
my $Help_button =
  $B5_frame->Button( -text => 'Help', -width => 10, -command => \&Help )->pack( -side => 'right' );

$One_frame->Checkbutton( -text => 'Auto clear', -variable => \$AutoClear )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );

my $LW_scale = $Four_frame->Scale(
    -orient   => 'horizontal',
    -variable => \$BlockSize,
    -width    => 8,
    -label    => 'Block size',
    -command  => sub { $AutoBlockSize = FALSE }
)->pack( -side => 'top' );
$LW_scale->configure( -from => MinimumBlockSize, -to => MaximumBlockSize );

my $Speed_scale = $Four_frame->Scale(
    -orient   => 'horizontal',
    -variable => \$Speed,
    -width    => 8,
    -label    => 'Speed',
    -from     => MinimumSpeed,
    -to       => MaximumSpeed
)->pack( -side => 'top' );

#$Speed_scale->configure( -from => MinimumSpeed, -to => MaximumSpeed );

$Four_frame->Checkbutton(
    -text     => 'Auto block size',
    -variable => \$AutoBlockSize
)->pack( -side => 'top' );

$Four_frame->Checkbutton(
    -text     => 'No walls',
    -variable => \$NoWalls
)->pack( -side => 'top' );

foreach $_ (<DATA>) { push @ColorList, Trim($_) }

$Five_frame->BrowseEntry(
    -label    => "FGC",
    -choices  => \@ColorList,
    -variable => \$ForegroundColor,
    -width    => 20,
)->pack( -side => 'top' );

$Five_frame->Radiobutton(
    -variable => \$AutoForegroundColor,
    -text     => 'Never',
    -value    => 'Never'
)->pack( -anchor => 'w' );

$Five_frame->Radiobutton(
    -variable => \$AutoForegroundColor,
    -text     => 'Start',
    -value    => 'Start'
)->pack( -anchor => 'w' );

$Five_frame->Radiobutton(
    -variable => \$AutoForegroundColor,
    -text     => 'Constant',
    -value    => 'Constant'
)->pack( -anchor => 'w' );

$Five_frame->Radiobutton(
    -variable => \$AutoForegroundColor,
    -text     => 'Collision',
    -value    => 'Collision'
)->pack( -anchor => 'w' );

#---------------------------------------------------------------------------
sub BackgroundColorSet {
    my $t = ( split( '~', $BackgroundColor ) )[1];
    unless ($t) { $t = $BackgroundColor }
    $Canvas->configure( -background => $t );
}

#---------------------------------------------------------------------------
sub BackgroundColorSetRandom {
    $BackgroundColor = @ColorList[ int( rand( scalar(@ColorList) ) ) ];
    my $t = ( split( '~', $BackgroundColor ) )[1];
    unless ($t) { $t = $BackgroundColor }
    $Canvas->configure( -background => $t );
}

#---------------------------------------------------------------------------
$Five_frame->BrowseEntry(
    -label     => "BGC",
    -choices   => \@ColorList,
    -variable  => \$BackgroundColor,
    -browsecmd => \&BackgroundColorSet,
    -listcmd   => \&BackgroundColorSet,
    -command   => \&BackgroundColorSet,
    -width     => 20,
)->pack( -side => 'top' );

$Five_frame->Checkbutton(
    -text     => 'Auto BG color',
    -variable => \$AutoBackgroundColor
)->pack( -side => 'top' );

my $LabelDIR = $Five_frame->Label(
    -textvariable => \$TextvariableDirection,
    -relief       => 'sunken'
)->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $LabelXPosition = $Five_frame->Label(
    -textvariable => \$TextvariableXPosition,
    -relief       => 'sunken'
)->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $LabelYPosition = $Five_frame->Label(
    -textvariable => \$TextvariableYPosition,
    -relief       => 'sunken'
)->pack( -side => 'top', -fill => 'both', -expand => '1' );

$Five_frame->Checkbutton(
    -text     => 'Debug',
    -variable => \$Debug,
    -command  => \&DebugMode
)->pack( -side => 'top' );

$Five_frame->Checkbutton(
    -text     => 'Photo',
    -variable => \$Photo
)->pack( -side => 'top', -fill => 'both', -expand => '1' );

$Five_frame->Button(
    -text    => 'Show log',
    -width   => 10,
    -command => sub { system( "geany", $LogFileName ) }
)->pack( -side => 'top' );

$Canvas =
  $Canvas_frame->Canvas( -cursor => "crosshair", -background => 'black' )
  ->pack( -fill => 'both', -expand => '1' );

$Canvas->Tk::bind( "<Button-1>", [ \&BackgroundColorSetRandom ] );
$Canvas->Tk::bind( "<Button-3>", [ \&ClearButton ] );

#---------------------------------------------------------------------------
#Set the random seed
srand( time ^ $$ );

#Ersase the log file so we start fresh
open LOG, ">" . $LogFileName;
close LOG;

#If in debugber set debug mode
if ( defined &DB::DB ) {
    $Debug = TRUE;
    DebugMode;
}

#---------------------------------------------------------------------------

Log( __LINE__ . " PerlNamePath::$PerlNamePath  PerlName::$PerlName  LogFileName::$LogFileName" );

MainLoop;

#---------------------------------------------------------------------------
#This gets the current display setting.
#It then calculates all of the required varibles needed to run.
sub GetDisplayParameters {
    my $CanvasXPixels     = $Canvas->Width;                     #Canvas width in pixels
    my $CanvasYPixels     = $Canvas->Height;                    #Canvas height in pixels
    my $CanvasTotalPixels = $CanvasXPixels * $CanvasYPixels;    #Canvas total pixels

    $MaximumXBlocks    = floor( $CanvasXPixels / $BlockSize );  #Canvas width in blocks
    $MaximumYBlocks    = floor( $CanvasYPixels / $BlockSize );  #Canvas height in blocks
    $CanvasTotalBlocks = $MaximumXBlocks * $MaximumYBlocks;     #Canvas total blocks
    if ($Debug) {
        Log(    __LINE__
              . ' DrawButton  2   Total canvas blocks:'
              . $CanvasTotalBlocks
              . '  X (blocks):'
              . $MaximumXBlocks
              . '  Y (blocks):'
              . $MaximumYBlocks
              . '  Block size:'
              . $BlockSize );
    }

    #Resize the array to hold all possible blocks
    $#CanvasArray = $CanvasTotalBlocks;
    @CanvasArray  = (0) x $CanvasTotalBlocks;
    if ($Debug) { Log( __LINE__ . ' CanvasArray: ' . $#CanvasArray ) }
}

#---------------------------------------------------------------------------
sub DrawButton {
    $LoopingComplete = !$LoopingComplete;
    if ($LoopingComplete) {
        LockControls('normal');
        return;
    } else {
        LockControls('disabled');
    }

    GetDisplayParameters;

    $TextvariableXPosition = 'XP: ' . $CurrentXLocation;
    $TextvariableYPosition = 'YP: ' . $CurrentYLocation;

    if ( $AutoForegroundColor eq 'Start' ) {
        $ForegroundColor = @ColorList[ int( rand( scalar(@ColorList) ) ) ];
    }

    if ($AutoBlockSize) {
        $BlockSize = int( rand( scalar(MaximumBlockSize) ) );
    }

    if ($AutoBackgroundColor) {
        BackgroundRandomColorSet;
    }

    Log(
        __LINE__ . " Draw Button
     FixedSize:$FixedSize
     AutoForegroundColor:$AutoForegroundColor
     AutoBackgroundColor:$AutoBackgroundColor
     AutoBlockSize:$AutoBlockSize
     AutoClear:$AutoClear
     BlockSize:$BlockSize
     CanvasTotalBlocks:$CanvasTotalBlocks
     MaximumXBlocks:$MaximumXBlocks
     MaximumYBlocks:$MaximumYBlocks
     MaximumX:$MaximumX
     MaximumY:$MaximumY
     CurrentXLocation:$CurrentXLocation
     CurrentYLocation:$CurrentYLocation
     BackgroundColor:$BackgroundColor
     ForegroundColor:$ForegroundColor
     MWGeometry:$MainWindowGeometry"
    );

    if ($AutoClear) { ClearButton() }
    if ($Photo)     { PhotoOnCanvas }

    $Canvas->createText(
        20, $MaximumY / 2,
        -fill => 'white',
        -text => 'East'
    );

    $Canvas->createText(
        $MaximumX - 310, $MaximumY / 2,
        -fill => 'white',
        -text => "West $MaximumX"
    );
    $Canvas->createText(
        ( $MaximumX / 2 ) - 150, 20,
        -fill => 'white',
        -text => "North"
    );
    $Canvas->createText(
        ( $MaximumX / 2 ) - 150, $MaximumY - 20,
        -fill => 'white',
        -text => "South $MaximumY"
    );

    if ($Debug) {
        DebugMode;
    }

    LoopIt;

    ShowCanvasArray;

    LockControls('normal');

}

#---------------------------------------------------------------------------

sub LoopIt {
    DrawSquare( 'Green~#00FF00', $CurrentYLocation, $CurrentXLocation );   #This is the first square

    while ( !$LoopingComplete ) {
        usleep( $Speed * 100 );
        CalcMovement;
        DoTheMove;
    }

    DrawSquare( 'Red~#FF0000', $CurrentYLocation, $CurrentXLocation );     #This is the last square

}

#---------------------------------------------------------------------------
sub ChangeDirection {
    my $DirectionSave = $Direction;

    do {
        $Direction = @DirectionArray[ int( rand( scalar(@DirectionArray) ) ) ];
    } until $Direction ne $DirectionSave;

    Log( __LINE__ . ' ' . $DirectionSave . ' ' . $Direction );
}

#----------------------------------------------------------------------------
#This section calculates the new location using last location and direction
sub CalcMovement {

    #If a collision occurs we can restore the position before the collision
    $CurrentXLocationSave = $CurrentXLocation;
    $CurrentYLocationSave = $CurrentYLocation;

    if ( $Direction eq 'N' ) {
        $CurrentYLocation -= 1;
    } elsif ( $Direction eq 'S' ) {
        $CurrentYLocation += 1;
    } elsif ( $Direction eq 'E' ) {
        $CurrentXLocation += 1;
    } elsif ( $Direction eq 'W' ) {
        $CurrentXLocation -= 1;
    }

    elsif ( $Direction eq 'NW' ) {
        $CurrentXLocation -= 1;
        $CurrentYLocation -= 1;
    } elsif ( $Direction eq 'SW' ) {
        $CurrentXLocation -= 1;
        $CurrentYLocation += 1;
    } elsif ( $Direction eq 'NE' ) {
        $CurrentXLocation += 1;
        $CurrentYLocation -= 1;
    } elsif ( $Direction eq 'SE' ) {
        $CurrentXLocation += 1;
        $CurrentYLocation += 1;
    }

    else {
        die "Error! Invalid Direction: $Direction";
    }
}

#---------------------------------------------------------------------------
#This section handles the move
sub DoTheMove {
    my $Retries    = 0;
    my $MaxRetries = 50;

    my $CollisionResult = CollisionTest;

    #No collision

    if ( $CollisionResult ne 'none' ) {

        #Draw a collision square in the returned color
        DrawSquare( $CollisionResult, $CurrentYLocationSave, $CurrentXLocationSave );

        #Here we loop until we find direction to go or we give up
        do {
            $CurrentXLocation = $CurrentXLocationSave;
            $CurrentYLocation = $CurrentYLocationSave;
            ChangeDirection;
            CalcMovement;
            $Retries += 1;
            if ( $Retries >= $MaxRetries ) {    #Give up
                $LoopingComplete = TRUE;
                Log(    __LINE__
                      . '  Retries '
                      . $Retries . '  X '
                      . $CurrentXLocation . '  Y '
                      . $CurrentYLocation
                      . '  Dir '
                      . $Direction );
                return;
            }
            $CollisionResult = CollisionTest;

            if ( $AutoForegroundColor eq 'Collision' ) {
                $ForegroundColor = @ColorList[ int( rand( scalar(@ColorList) ) ) ];
            }

        } until ( ( $CollisionResult eq 'none' ) || $LoopingComplete );
    }

    if ( $AutoForegroundColor eq 'Constant' ) {
        $ForegroundColor = @ColorList[ int( rand( scalar(@ColorList) ) ) ];
    }
    DrawSquare( $ForegroundColor, $CurrentYLocation, $CurrentXLocation );

    #Save the current location in CanvasArray
    $CanvasArray[ ( $MaximumXBlocks * $CurrentYLocation ) + $CurrentXLocation ] = 1;
}

#----------------------------------------------------------------------------
#This section checks for a collision
#Returns a status string
sub CollisionTest() {
    if ($Debug) {
        DrawSquare( 'GoldenRod~#DAA520', $CurrentYLocation, $CurrentXLocation );
    }

    #First check for wall collisions, if $NoWalls is false
    #---------------
    if ( $CurrentXLocation < 0 ) {    # Left wall
        if ($NoWalls) {
            $CurrentXLocation = $MaximumXBlocks - 1;
        } else {
            $CurrentXLocation = 0;
            Log(    __LINE__
                  . ' Collision on left (W < 0)  RED  '
                  . $CurrentXLocation . '   '
                  . $CurrentYLocation . '   '
                  . $Direction );
            return 'DarkRed~#8B0000~left';
        }
    }

    #---------------
    if ( $CurrentXLocation > $MaximumXBlocks - 1 ) {    # Right wall
        if ($NoWalls) {
            $CurrentXLocation = 0;
        } else {
            $CurrentXLocation = $MaximumXBlocks - 1;
            Log(    __LINE__
                  . ' Collision on Right (W > $MaximumXBlocks)  Blue  '
                  . $CurrentXLocation . '   '
                  . $CurrentYLocation . '   '
                  . $Direction );
            return 'DeepSkyBlue~#00BFFF~right';
        }
    }

    #---------------
    if ( $CurrentYLocation < 0 ) {    # Top
        if ($NoWalls) {
            $CurrentYLocation = $MaximumYBlocks - 1;
        } else {
            $CurrentYLocation = 0;
            Log(    __LINE__
                  . ' Collision on top (H < 0 ) ORANGE  '
                  . $CurrentXLocation . '   '
                  . $CurrentYLocation . '   '
                  . $Direction );
            return 'DarkOrange~#FF8C00~top';
        }
    }

    #---------------
    if ( $CurrentYLocation > $MaximumYBlocks - 1 ) {    # Bottom
        if ($NoWalls) {
            $CurrentYLocation = 0;
        } else {
            $CurrentYLocation = $MaximumYBlocks - 1;
            Log(    __LINE__
                  . ' Collision on bottom (H > $MaximumYBlocks-1)  PINK  '
                  . $CurrentXLocation . '   '
                  . $CurrentYLocation . '   '
                  . $Direction );
            return 'DeepPink~#FF1493~bottom';
        }
    }

    #---------------
    #Now check for canvas collisions
    my $CanvasArrayPosition =
      $CanvasArray[ ( $MaximumXBlocks * $CurrentYLocation ) + $CurrentXLocation ];
    if ( $CanvasArrayPosition == 1 ) {
        Log(    __LINE__
              . ' Collision on canvas  Grey  '
              . $CurrentXLocation . '   '
              . $CurrentYLocation . '   '
              . $Direction );
        return 'DarkGrey~#A9A9A9~canvas';
    }
    return 'none';    #No collision
}

#----------------------------------------------------------------------------
#The color is passed in first and then the Ypos and Xpos
sub DrawSquare($$$) {
    my $Color     = ( split( '~', $_[0] ) )[1];
    my $YPosition = $_[1];
    my $XPosition = $_[2];
    $Canvas->createRectangle(    #Color is passed in
        $XPosition * $BlockSize,
        $YPosition * $BlockSize,
        ( $XPosition * $BlockSize ) + $BlockSize,
        ( $YPosition * $BlockSize ) + $BlockSize,
        -fill => $Color
    );

    #Update the status boxes
    $TextvariableDirection = 'Direction: ' . $Direction;
    $TextvariableYPosition = 'YP: ' . $YPosition;
    $TextvariableXPosition = 'XP: ' . $XPosition;
    $MainWindow->update;
}

#----------------------------------------------------------------------------
sub LockControls($) {

    #Disable or enable controls that cause problems while running
    $Up_button->configure( -state => $_[0] );
    $Down_button->configure( -state => $_[0] );
    $Left_button->configure( -state => $_[0] );
    $Right_button->configure( -state => $_[0] );
    $PostScriptOut_button->configure( -state => $_[0] );
    $Help_button->configure( -state => $_[0] );
    $LW_scale->configure( -state => $_[0] );
    if ( $_[0] eq 'enable' ) {
        $MainWindow->resizable( FALSE, FALSE );
    } else {
        $MainWindow->resizable( TRUE, TRUE );
    }
    $MainWindow->update();
}

#----------------------------------------------------------------------------
sub ClearButton {
    Log( __LINE__ . " Clear Button" );

    $Canvas->delete('X');
    $Canvas->delete( 'everything', 'all' );
    GetDisplayParameters;

    $#CanvasArray = $CanvasTotalBlocks;
    @CanvasArray  = (0) x $CanvasTotalBlocks;
    Log(    __LINE__
          . ' CanvasArray: '
          . $#CanvasArray . ' '
          . $CanvasTotalBlocks . '  '
          . $MaximumXBlocks . ' '
          . $MaximumYBlocks );
}

#---------------------------------------------------------------------------
sub ShowCanvasArray {
    my $cnt   = 0;
    my $TLine = '';
    foreach my $i (@CanvasArray) {
        $TLine .= $i;
        $cnt++;
        if ( $cnt > $MaximumXBlocks - 1 ) {
            Log($TLine);
            $cnt   = 0;
            $TLine = '';
        }
    }
}

#---------------------------------------------------------------------------
sub Help {
    my $HelpMessage = "Move to center\n" . "Presets\n";
    my $answer      = $MainWindow->messageBox(
        -title   => "Help $PerlName",
        -message => $HelpMessage,
        -type    => 'Ok',
        -icon    => 'info',
        -default => 'Ok'
    );
}

#---------------------------------------------------------------------------
sub PostScriptOut {
    my $x = localtime;
    $x =~ s/[ :]//gi;    #remove spaces and : from the date
    $Canvas->posts711 CanvasArray : 1215 1216 38 32 cript( -file => "$x.ps" );
    my $answer = $MainWindow->messageBox(
        -title   => 'File saved as PostScript file',
        -message => "File name:\n$x.ps",
        -type    => 'Ok',
        -icon    => 'info',
        -default => 'Ok'
    );
}

#---------------------------------------------------------------------------
sub Log($) {
    open LOG, ">>" . $LogFileName;
    say LOG $_[0];
    close LOG;
}

#---------------------------------------------------------------------------
sub DebugMode {

    #if (! $Canvas) {return};
    #Draw a test pattern
    $CurrentYLocation = 20;
    my @height = ( 20, 21, 22, 23, 20, 21, 22, 23, 23 );
    my @width  = ( 20, 20, 20, 20, 22, 22, 22, 22, 21 );
    for my $index ( 0 .. $#height ) {
        DrawSquare( 'Brown~#A52A2A', $height[$index], $width[$index] );

        #Save the test location in CanvasArray
        $CanvasArray[ ( $MaximumXBlocks * $height[$index] ) + $width[$index] ] = 1;
    }

    #Test direction and starting location
    $Direction        = 'S';
    $CurrentXLocation = 21;
    $CurrentYLocation = 18;
    $MainWindow->update();
    DrawSquare( 'Aqua~#00FFFF', $CurrentYLocation, $CurrentXLocation );

    #Update the status boxes
    $TextvariableDirection = 'Direction: ' . $Direction;
    $TextvariableYPosition = 'YP: ' . $CurrentYLocation;
    $TextvariableXPosition = 'XFP: ' . $CurrentXLocation;
    $MainWindow->update;
}

#---------------------------------------------------------------------------
sub PhotoOnCanvas {
    state $topdir = '';
    my $topdir1 = '/home/ceg/Pictures/';
    my $topdir2 = '/home/doug/Pictures/';

    if    ( -e $topdir )  { }
    elsif ( -e $topdir1 ) { $topdir = $topdir1 }
    elsif ( -e $topdir2 ) { $topdir = $topdir2 }
    else {
        my $db = $MainWindow->DialogBox(
            -title          => 'No valid path to pictures',
            -buttons        => [ 'Ok', 'Cancel' ],
            -default_button => 'Ok'
        );
        $db->add(
            'LabEntry',
            -textvariable => \$topdir,
            -width        => 20,
            -label        => 'Path to pictures',
            -labelPack    => [ -side => 'left' ]
        )->pack;
        my $answer = $db->Show();

        if ( $answer eq "Ok" ) {
            Log("Path = $topdir");
        } else {
            return;
        }
    }
    if ( !-e $topdir ) {
        my $d = $MainWindow->Dialog(
            -title => "Invalid picture path",
            -text  => "$topdir is not a valid picture path."
        );
        $d->Show;

        return;
    }

    my @dirsdone  = ();
    my @filesdone = ();

    GetTree( $topdir, \@dirsdone, \@filesdone );
    my $Picture = @filesdone[ int( rand( scalar(@filesdone) ) ) ];
    $Picture = FixPathSlash($Picture);
    Log( __LINE__ . ' PhotoOnCanvas:' . $Picture );

    my $imageM = Image::Magick->new( size => $MaximumX . 'x' . $MaximumY );
    my $x = $imageM->Read($Picture);
    warn "$x" if "$x";
    $x = $imageM->Resize( geometry => $MaximumX . 'x' . $MaximumY );
    $x = $imageM->Write('x.jpg');
    my $image = $Canvas->Photo( -file => 'x.jpg' );
    $Canvas->create( 'image', 1, 1, -anchor => 'nw', -image => $image );

    undef $imageM;
}

#---------------------------------------------------------------------------
__DATA__
AliceBlue~#F0F8FF
AntiqueWhite~#FAEBD7
Aqua~#00FFFF
Aquamarine~#7FFFD4
Azure~#F0FFFF
Beige~#F5F5DC
Bisque~#FFE4C4
Black~#000000
BlanchedAlmond~#FFEBCD
Blue~#0000FF
BlueViolet~#8A2BE2
Brown~#A52A2A
BurlyWood~#DEB887
CadetBlue~#5F9EA0
Chartreuse~#7FFF00
Chocolate~#D2691E
Coral~#FF7F50
CornflowerBlue~#6495ED
Cornsilk~#FFF8DC
Crimson~#DC143C
Cyan~#00FFFF
DarkBlue~#00008B
DarkCyan~#008B8B
DarkGoldenRod~#B8860B
DarkGray~#A9A9A9
DarkGrey~#A9A9A9
DarkGreen~#006400
DarkKhaki~#BDB76B
DarkMagenta~#8B008B
DarkOliveGreen~#556B2F
DarkOrange~#FF8C00
DarkOrchid~#9932CC
DarkRed~#8B0000
DarkSalmon~#E9967A
DarkSeaGreen~#8FBC8F
DarkSlateBlue~#483D8B
DarkSlateGray~#2F4F4F
DarkSlateGrey~#2F4F4F
DarkTurquoise~#00CED1
DarkViolet~#9400D3
DeepPink~#FF1493
DeepSkyBlue~#00BFFF
DimGray~#696969
DimGrey~#696969
DodgerBlue~#1E90FF
FireBrick~#B22222
FloralWhite~#FFFAF0
ForestGreen~#228B22
Fuchsia~#FF00FF
Gainsboro~#DCDCDC
GhostWhite~#F8F8FF
Gold~#FFD700
GoldenRod~#DAA520
Gray~#808080
Grey~#808080
Green~#008000
GreenYellow~#ADFF2F
HoneyDew~#F0FFF0
HotPink~#FF69B4
IndianRed~#CD5C5C
Indigo~#4B0082
Ivory~#FFFFF0
Khaki~#F0E68C
Lavender~#E6E6FA
LavenderBlush~#FFF0F5
LawnGreen~#7CFC00
LemonChiffon~#FFFACD
LightBlue~#ADD8E6
LightCoral~#F08080
LightCyan~#E0FFFF
LightGoldenRodYellow~#FAFAD2
LightGray~#D3D3D3
LightGrey~#D3D3D3
LightGreen~#90EE90
LightPink~#FFB6C1
LightSalmon~#FFA07A
LightSeaGreen~#20B2AA
LightSkyBlue~#87CEFA
LightSlateGray~#778899
LightSlateGrey~#778899
LightSteelBlue~#B0C4DE
LightYellow~#FFFFE0
Lime~#00FF00
LimeGreen~#32CD32
Linen~#FAF0E6
Magenta~#FF00FF
Maroon~#800000
MediumAquaMarine~#66CDAA
MediumBlue~#0000CD
MediumOrchid~#BA55D3
MediumPurple~#9370D8
MediumSeaGreen~#3CB371
MediumSlateBlue~#7B68EE
MediumSpringGreen~#00FA9A
MediumTurquoise~#48D1CC
MediumVioletRed~#C71585
MidnightBlue~#191970
MintCream~#F5FFFA
MistyRose~#FFE4E1
Moccasin~#FFE4B5
NavajoWhite~#FFDEAD
Navy~#000080
OldLace~#FDF5E6
Olive~#808000~<<<
OliveDrab~#6B8E23
Orange~#FFA500
OrangeRed~#FF4500
Orchid~#DA70D6
PaleGoldenRod~#EEE8AA
PaleGreen~#98FB98
PaleTurquoise~#AFEEEE
PaleVioletRed~#D87093
PapayaWhip~#FFEFD5
PeachPuff~#FFDAB9
Peru~#CD853F
Pink~#FFC0CB
Plum~#DDA0DD
PowderBlue~#B0E0E6
Purple~#800080
Red~#FF0000
RosyBrown~#BC8F8F
RoyalBlue~#4169E1
SaddleBrown~#8B4513
Salmon~#FA8072
SandyBrown~#F4A460
SeaGreen~#2E8B57
SeaShell~#FFF5EE
Sienna~#A0522D
Silver~#C0C0C0
SkyBlue~#87CEEB
SlateBlue~#6A5ACD
SlateGray~#708090
SlateGrey~#708090
Snow~#FFFAFA
SpringGreen~#00FF7F
SteelBlue~#4682B4
Tan~#D2B48C
Teal~#008080
Thistle~#D8BFD8
Tomato~#FF6347
Turquoise~#40E0D0
Violet~#EE82EE
Wheat~#F5DEB3
White~#FFFFFF
WhiteSmoke~#F5F5F5
Yellow~#FFFF00
YellowGreen~#9ACD32
