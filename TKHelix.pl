#!/bin/perl -w

#Todo
# Auto size and Size multiplier are not right
# Repeat count does nothing
# Fixed X and Y do nothing
# Help does nothing
# Auto speed does nothing
#

use strict;
use warnings;

#use diagnostics;
use Carp;

our $VERSION = 1.00;
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
use Readonly;

sub GetDisplayParameters;
sub BackgroundColorSet;
sub BackgroundRandomColorSet;
sub DrawButton;
sub ClearButton;
sub GetPoint;
sub GetHelixData;
sub DrawHelix;
sub ConfigTools;
sub RandColor;
sub Round;
sub Help;
sub PostScriptOut;
sub Log;
sub DebugMode;
sub PhotoOnCanvas;

Readonly my $MAXLINEWIDTH => scalar 25;

my $PerlNamePath = ( ( split( m/[\\]/x, $0 ) )[0] );
my $PerlName     = ( ( split( m/\\\\/x, $PerlNamePath ) )[-1] );
my $LogFileName  = $PerlName . '.log';

my @DirectionChoices = qw(N NW W SW S SE E NE);
my $Direction        = 'N';

my $XOffset = 425;
my $XStep   = 10;
my $YOffset = 250;
my $YStep   = 10;

my $Degrees             = 5;
my $ForegroundColor     = 'White~#FFFFFF';
my $BackgroundColor     = 'Black~#000000';
my $AutoBackgroundColor = FALSE;
my $AutoDirection       = TRUE;

my $AutoSize         = TRUE;
my $FixedXLocation   = FALSE;
my $FixedYLocation   = FALSE;
my $AutoFGColor      = FALSE;
my $VaryFGColor      = FALSE;
my $AutoBGColor      = FALSE;
my $AutoDegrees      = TRUE;
my $AutoDrawSpeed    = FALSE;
my $AutoLineWidth    = FALSE;
my $AutoClear        = TRUE;
my $AutoHelixLoops   = FALSE;
my $AutoHelixPerInch = FALSE;
my $AutoRepeat       = 0;
my $LineWidth        = 1;
my $MainWindowX      = 0;
my $MainWindowY      = 0;

my $CanvasXPixels        = 0;
my $CanvasYPixels        = 0;
my $CanvasTotalPixels    = 0;
my $Multiplier           = 0;
my $MultiplierPercentage = 50;
my $Photo                = FALSE;
my $Debug                = FALSE;
my $DrawSpeed            = 1;
my $HelixLoops           = 10;
my $HelixPerInch         = 5;

Readonly my $MinimumDrawSpeed    => scalar 0;
Readonly my $MaximumDrawSpeed    => scalar 200;
Readonly my $MinimumHelixLoops   => scalar 5;
Readonly my $MaximumHelixLoops   => scalar 50;
Readonly my $MinimumHelixPerInch => scalar 1;
Readonly my $MaximumHelixPerInch => scalar 50;

my $MainWindowGeometry;
my $Canvas;

my @BackgroundColorChoices = ();
my @ForegroundColorChoices = ();
my @ColorList              = ();
my @Array                  = ();

my $MainWindow = MainWindow->new( '-title' => $PerlName );

$MainWindow->minsize( 400, 400 );
$MainWindow->maxsize( $MainWindow->screenwidth, $MainWindow->screenheight );
$MainWindow->geometry('1050x725+1400+375');
$MainWindow->resizable( TRUE, TRUE );
$MainWindow->bind(
    '<Configure>',
    [
        sub {

            if ( $_[0] =~ /MainWindow/i ) {
                $MainWindowGeometry = $MainWindow->geometry();
                $MainWindow->title("$PerlName $MainWindowGeometry<<<");
                ( $MainWindowX, my $y ) = split( /x/x, $MainWindowGeometry );
                ($MainWindowY) = split( /\+/x, $y );
                ConfigTools;
            }
          }
    ]
);

#---------------------------------------------------------------------------
my $Menu_frame =
  $MainWindow->Scrolled( qw/Pane -scrollbars osw/, -width => 300 )
  ->pack( -side => 'left', -fill => 'y', -expand => '0' );
my $Canvas_frame = $MainWindow->Frame()->pack( -side => 'left', -fill => 'both', -expand => '1' );

my $One_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Two_frame =
  $Menu_frame->Frame( -borderwidth => $MinimumHelixLoops, -relief => 'groove' )
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
my $Seven_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Eight_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Nine_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Ten_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Eleven_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Twelve_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Thirteen_frame =
  $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );

my $B1_frame = $One_frame->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );
$B1_frame->Button( -text => 'Draw', -command => \&DrawButton )
  ->pack( -side => 'left', -expand => '1', -fill => 'x' );
$B1_frame->Button( -text => 'Clear', -command => \&ClearButton )
  ->pack( -side => 'left', -expand => '1', -fill => 'x' );
$B1_frame->Checkbutton( -text => 'Debug', -variable => \$Debug )
  ->pack( -side => 'left', -expand => '1', -fill => 'x' );

my $B2_frame = $One_frame->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );
$B2_frame->Button(
    -text    => 'Zoom 0.9',
    -command => sub { $Canvas->scale( 'all', $XOffset, $YOffset, 0.9, 0.9 ) }
)->pack( -side => 'left', -expand => '1', -fill => 'x' );
$B2_frame->Button(
    -text    => 'Zoom 1.1',
    -command => sub { $Canvas->scale( 'all', $XOffset, $YOffset, 1.1, 1.1 ) }
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

my $B3_frame = $One_frame->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );
$B3_frame->Button(
    -text    => 'Up',
    -command => sub {
        $Canvas->addtag( 'everything', 'all' );
        $Canvas->move( 'all', 0, $MainWindowY / 20 * -1 );
    }
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

$B3_frame->Button(
    -text    => 'Down',
    -command => sub {
        $Canvas->addtag( 'everything', 'all' );
        $Canvas->move( 'all', 0, $MainWindowY / 20 );
    }
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

$B3_frame->Button(
    -text    => 'Left',
    -command => sub {
        $Canvas->addtag( 'everything', 'all' );
        $Canvas->move( 'all', $MainWindowX / 20 * -1, 0 );
    }
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

$B3_frame->Button(
    -text    => 'Right',
    -command => sub {
        $Canvas->addtag( 'everything', 'all' );
        $Canvas->move( 'all', $MainWindowX / 20, 0 );
    }
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

my $B4_frame = $One_frame->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $B5_frame = $One_frame->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );
$B5_frame->Button( -text => 'PS out', -command => \&PSOut )
  ->pack( -side => 'left',, -expand => '1', -fill => 'x' );
$B5_frame->Button( -text => 'Help', -command => \&Help )
  ->pack( -side => 'left',, -expand => '1', -fill => 'x' );

my $Repeat_scale = $Two_frame->Scale(
    -orient   => 'horizontal',
    -variable => \$AutoRepeat,
    -width    => 10,
    -label    => 'Repeat count'
)->pack( -side => 'left', -expand => '1', -fill => 'x' );
$Repeat_scale->configure( -from => 0, -to => 10 );

$Two_frame->Checkbutton( -text => 'Auto clear', -variable => \$AutoClear )
  ->pack( -side => 'left', -expand => '1', -fill => 'x' );

my $Multiplier_Scale = $Three_frame->Scale(
    -orient   => 'horizontal',
    -variable => \$MultiplierPercentage,
    -width    => 8,
    -label    => 'Size multiplier %',
    -from     => 5,
    -to       => 100
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

$Three_frame->Checkbutton( -text => 'Auto size', -variable => \$AutoSize )
  ->pack( -side => 'left', -expand => '1', -fill => 'x' );

$Four_frame->Checkbutton(
    -text     => 'Fixed X location',
    -variable => \$FixedXLocation
)->pack( -side => 'left', -expand => '1', -fill => 'x' );
$Four_frame->Checkbutton(
    -text     => 'Fixed Y location',
    -variable => \$FixedYLocation
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

my $LW_scale = $Five_frame->Scale(
    -orient   => 'horizontal',
    -variable => \$LineWidth,
    -width    => 8,
    -label    => 'Line width',
    -from     => 1,
    -to       => $MAXLINEWIDTH
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

$Five_frame->Checkbutton(
    -text     => 'Auto line width',
    -variable => \$AutoLineWidth
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

my $DrawSpeed_scale = $Six_frame->Scale(
    -orient   => 'horizontal',
    -variable => \$DrawSpeed,
    -width    => 8,
    -label    => 'Draw speed',
    -from     => $MinimumDrawSpeed,
    -to       => $MaximumDrawSpeed
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

$Six_frame->Checkbutton( -text => 'Auto draw speed', -variable => \$AutoDrawSpeed )
  ->pack( -side => 'left', -expand => '1', -fill => 'x' );

my $HelixLoops_scale = $Seven_frame->Scale(
    -orient   => 'horizontal',
    -variable => \$HelixLoops,
    -width    => 8,
    -label    => 'Helix loops',
    -from     => $MinimumHelixLoops,
    -to       => $MaximumHelixLoops
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

$Seven_frame->Checkbutton( -text => 'Auto helix Loops', -variable => \$AutoHelixLoops )
  ->pack( -side => 'left', -expand => '1', -fill => 'x' );

my $HelixPerInch_scale = $Eight_frame->Scale(
    -orient   => 'horizontal',
    -variable => \$HelixPerInch,
    -width    => 8,
    -label    => 'Helix per inch',
    -from     => $MinimumHelixPerInch,
    -to       => $MaximumHelixPerInch
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

$Eight_frame->Checkbutton( -text => 'Auto helix per inch', -variable => \$AutoHelixPerInch )
  ->pack( -side => 'left', -expand => '1', -fill => 'x' );

my $HorizontalScale = $Nine_frame->Scale(
    -orient   => 'horizontal',
    -variable => \$XOffset,
    -width    => 8,
    -label    => 'XOffset %',
    -from     => 0,
    -to       => 100
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

my $VerticalScale = $Nine_frame->Scale(
    -orient   => 'horizontal',
    -variable => \$YOffset,
    -width    => 8,
    -label    => 'YOffset %',
    -from     => 0,
    -to       => 100
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

my @DegreesChoices = qw/1 2 3 4 5 6 8 9 10 12 15 18 20 24 30 36 40 45 60 72 90 120 180/;
$Ten_frame->BrowseEntry(
    -label    => "Degrees",
    -choices  => \@DegreesChoices,
    -variable => \$Degrees,
    -width    => 5
)->pack( -side => 'left', -expand => '1', -fill => 'x' );
$Ten_frame->Checkbutton( -text => 'Auto Degrees', -variable => \$AutoDegrees )
  ->pack( -side => 'left', -expand => '1', -fill => 'x' );

$Eleven_frame->BrowseEntry(
    -label    => "Direction",
    -choices  => \@DirectionChoices,
    -variable => \$Direction,
    -width    => 5
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

$Eleven_frame->Checkbutton( -text => 'Auto direction', -variable => \$AutoDirection )
  ->pack( -side => 'left', -expand => '1', -fill => 'x' );

# number of loops helix loops
# my $Step = 10; #Helixs per inch

while ( my $_ = <DATA> ) { push @ColorList, Trim($_) }

push @ForegroundColorChoices, @ColorList;
$Twelve_frame->BrowseEntry(
    -label     => "FGC",
    -choices   => \@ForegroundColorChoices,
    -variable  => \$ForegroundColor,
    -width     => 15,
    -browsecmd => \&FGColorSet,
    -listcmd   => \&FGColorSet,
    -command   => \&FGColorSet
)->pack( -side => 'left', -expand => '1', -fill => 'x' );
$Twelve_frame->Checkbutton(
    -text     => 'Auto',
    -variable => \$AutoFGColor
)->pack( -side => 'left', -expand => '1', -fill => 'x' );

$Twelve_frame->Checkbutton(
    -text     => 'Vary',
    -variable => \$VaryFGColor
)->pack( -side => 'top' );

sub FGColorSet {
    my $t = ( split( '~', $ForegroundColor ) )[1];
    unless ($t) { $t = $ForegroundColor }
    $Canvas->itemconfigure( 'all', -fill => $t );
    return;
}

push @BackgroundColorChoices, @ColorList;
$Thirteen_frame->BrowseEntry(
    -label     => "BGC",
    -choices   => \@BackgroundColorChoices,
    -variable  => \$BackgroundColor,
    -width     => 15,
    -browsecmd => \&BGColorSet,
    -listcmd   => \&BGColorSet,
    -command   => \&BGColorSet
)->pack( -side => 'left' );

sub BGColorSet {
    my $t = ( split( '~', $BackgroundColor ) )[1];
    unless ($t) { $t = $BackgroundColor }
    $Canvas->configure( -background => $t );
    return;
}

$Thirteen_frame->Checkbutton(
    -text     => 'Auto',
    -variable => \$AutoBGColor
)->pack( -side => 'left' );
@ColorList = ();    #Free the memory

$Canvas =
  $Canvas_frame->Canvas( -cursor => "crosshair", -background => 'black' )
  ->pack( -fill => 'both',, -expand => '1', -fill => 'both' );

#---------------------------------------------------------------------------
srand( time ^ $$ );

#Erase the log file so we start fresh
Log('ERASE');

#If in debugber set debug mode
if ( defined &DB::DB ) {
    $Debug = TRUE;
}

sub BGColor {
    $BackgroundColor = @BackgroundColorChoices[ int( rand(@BackgroundColorChoices) ) ];
    $Canvas->configure( -background => ( split( '~', $BackgroundColor ) )[1] );
    return;
}

sub FGColor {
    $ForegroundColor = @ForegroundColorChoices[ int( rand(@ForegroundColorChoices) ) ];
    $Canvas->itemconfigure( 'all', -fill => ( split( '~', $ForegroundColor ) )[1] );
    return;
}
$Canvas->Tk::bind( "<Button-1>", [ \&FGColor ] );
$Canvas->Tk::bind( "<Button-3>", [ \&BGColor ] );

Log("DBGVIEWCLEAR");
Log("PerlNamePath::$PerlNamePath\nPerlName::$PerlName\nLogFileName::$LogFileName");

MainLoop;

#---------------------------------------------------------------------------
#This gets the current display setting.
#It then calculates all of the required varibles needed to run.
sub GetDisplayParameters {
    $CanvasXPixels     = $Canvas->Width;                     #Canvas width in pixels
    $CanvasYPixels     = $Canvas->Height;                    #Canvas height in pixels
    $CanvasTotalPixels = $CanvasXPixels * $CanvasYPixels;    #Canvas total pixels
    return;
}

#---------------------------------------------------------------------------
sub Log {
    my ($String) = @_;
    my $LOG;
    if ( $String eq 'ERASE' ) {
        open( $LOG, '>', $LogFileName ) or carp 'Unable to open log file for write >';
    } else {
        open( $LOG, '>>', $LogFileName ) or carp 'Unable to open log file append >>';
    }
    say $LOG $String;
    close $LOG;
    return;
}

#---------------------------------------------------------------------------
sub ConfigTools {

    return;
}

#---------------------------------------------------------------------------
sub RandColor {
    my $Color = sprintf( "#%06X", ( ( ( rand(0xff) << 8 ) + rand(0xff) << 8 ) + rand(0xff) ) );
    return $Color;
}

#---------------------------------------------------------------------------
sub Round {
    my ($number) = shift;
    return int( $number + .5 * ( $number <=> 0 ) );
}

#---------------------------------------------------------------------------
#A decimal value goes in, pairs of screen points come out
sub GetPoints {
    my ($AngleD) = @_;
    my $AngleR = $AngleD / 180 * PI;

    my @Out;
    $Out[0] = Round( ( cos($AngleR) * $Multiplier ) + $CanvasXPixels / 2 );
    $Out[1] = Round( ( sin($AngleR) * $Multiplier ) + $CanvasYPixels / 2 );

    #say __LINE__ . ':   ' . $Out[0] . '  ' . $Out[1] . '  ' . $Multiplier;

    if ($Debug) {    #This plots the point created for test purposes
        $Canvas->createRectangle( $Out[0], $Out[1], $Out[0] + 5, $Out[1] + 5, -fill => 'white' );
        $MainWindow->update();
    }

    return @Out;
}

#---------------------------------------------------------------------------
#This routine creates the data to draw the helix with
sub GetHelixData {

    #Generate an array of circle values in @TempArray
    my @TempArray = ();
    for ( my $X = 0 ; $X < 360 ; $X += $Degrees ) {
        my @Out = GetPoints($X);
        push( @TempArray, @Out );
    }

    if ($Debug) {    #This plots the full circle constained in $TempArray
        $Canvas->createLine(
            @TempArray,
            -fill  => 'Blue',
            -width => '1',
            -arrow => 'first'
        );
        $MainWindow->update();
    }

    #Now pull the values out of @TempArray and make them into a helix in @Array

    if ($AutoHelixPerInch) {
        $HelixPerInch =
          int( rand( $MaximumHelixPerInch - $MinimumHelixPerInch ) ) + $MinimumHelixPerInch;
    }

    if ($AutoDirection) {
        $Direction = @DirectionChoices[ int( rand(@DirectionChoices) ) ];
    }

    if ($AutoHelixLoops) {
        $HelixLoops = int( rand( $MaximumHelixLoops - $MinimumHelixLoops ) ) + $MinimumHelixLoops;
    }

    if ($AutoDrawSpeed) {
        $DrawSpeed = int( rand( $MaximumDrawSpeed - $MinimumDrawSpeed ) ) + $MinimumDrawSpeed;
    }

    for ( my $x = 0 ; $x < $HelixLoops ; $x++ ) {    #Number of loops helix loops
        my $count = 0;
        my $Val;
        foreach my $InVal (@TempArray) {
            $count++;
            if ( $count % 2 == 0 ) {                 #This is the Y values
                given ($Direction) {

                    when ('N') {
                        $Val = Round( $InVal + ( $x * $HelixPerInch ) );
                        push( @Array, $Val );
                    };
                    when ('NE') {
                        $Val = Round( $InVal + ( $x * $HelixPerInch ) );
                        push( @Array, $Val );
                    };
                    when ('E') {
                        push( @Array, $InVal );
                    };
                    when ('SE') {
                        $Val = Round( $InVal - ( $x * $HelixPerInch ) );
                        push( @Array, $Val );
                    };
                    when ('S') {
                        $Val = Round( $InVal - ( $x * $HelixPerInch ) );
                        push( @Array, $Val );
                    };
                    when ('SW') {
                        $Val = Round( $InVal - ( $x * $HelixPerInch ) );
                        push( @Array, $Val );
                    };
                    when ('W') {
                        push( @Array, $InVal );
                    };
                    when ('NW') {
                        $Val = Round( $InVal + ( $x * $HelixPerInch ) );
                        push( @Array, $Val );
                    };
                    default { carp "Error! Invalid Direction: $Direction"; };
                }
            } else {
                given ($Direction) {    #This is the X values
                    when ('N') {
                        push( @Array, $InVal );
                    };
                    when ('NE') {
                        $Val = Round( $InVal - ( $x * $HelixPerInch ) );
                        push( @Array, $Val );
                    };
                    when ('E') {
                        $Val = Round( $InVal - ( $x * $HelixPerInch ) );
                        push( @Array, $Val );
                    };
                    when ('SE') {
                        $Val = Round( $InVal - ( $x * $HelixPerInch ) );
                        push( @Array, $Val );
                    }
                    when ('S') {
                        push( @Array, $InVal )
                    };
                    when ('SW') {
                        $Val = Round( $InVal + ( $x * $HelixPerInch ) );
                        push( @Array, $Val );
                    };
                    when ('W') {
                        $Val = Round( $InVal + ( $x * $HelixPerInch ) );
                        push( @Array, $Val );
                    };
                    when ('NW') {
                        $Val = Round( $InVal + ( $x * $HelixPerInch ) );
                        push( @Array, $Val );
                    };
                    default { carp "Error! Invalid Direction: $Direction"; };
                }
            }
        }
    }
    return;
}

#---------------------------------------------------------------------------
sub DrawHelix {
    my $LineColor = ( split( '~', $ForegroundColor ) )[1];

    #If speed is 0 we draw real fast by using a draw with an array
    #We cannot vary LineColor or LineWidth
    if ( $DrawSpeed == 0 ) {
        $Canvas->createLine(
            @Array,
            -fill  => $LineColor,
            -width => $LineWidth,
            -arrow => 'first'
        );
        $MainWindow->update();
    } else {    #Draw a segment at a time (slow)tk
        my $a1 = pop(@Array);
        my $a2 = pop(@Array);

        while ( $#Array > 0 ) {
            if ($VaryFGColor) {
                $ForegroundColor = @ForegroundColorChoices[ int( rand(@ForegroundColorChoices) ) ];
                $LineColor = ( split( '~', $ForegroundColor ) )[1];
            }
            my $a3 = pop(@Array);
            my $a4 = pop(@Array);
            $Canvas->createLine(
                $a1, $a2, $a3, $a4,
                -fill  => $LineColor,
                -width => $LineWidth
            );
            $MainWindow->update();
            usleep( $DrawSpeed * 100 );
            say __LINE__ . ' ' . $DrawSpeed;
            $a1 = $a3;
            $a2 = $a4;
        }
    }
    return;
}

#---------------------------------------------------------------------------
sub DrawButton {
    Log("----- Draw BUTTON -----");
    @Array = ();
    GetDisplayParameters;

    #LogAll();

    if ($AutoClear) { ClearButton }
    if ($AutoLineWidth) { $LineWidth = int( rand($MAXLINEWIDTH) ) + 1 }
    if ($AutoDegrees) {
        $Degrees = @DegreesChoices[ int( rand(@DegreesChoices) ) ];
    }
    if ($AutoFGColor) {
        $ForegroundColor = @ForegroundColorChoices[ int( rand(@ForegroundColorChoices) ) ];
    }

    if ($AutoBGColor) {
        $BackgroundColor = @BackgroundColorChoices[ int( rand(@BackgroundColorChoices) ) ];
        $Canvas->configure( -background => ( split( '~', $BackgroundColor ) )[1] );
    }

    # $XOffset = int( rand($HorizontalScaleMaximum) ) + $HorizontalScaleMinimum
    #   unless ($FixedXLocation);
    # $YOffset = int( rand($VerticleScaleMaximum) ) + $VerticleScaleMinimum
    #   unless ($FixedYLocation);
    if ($AutoSize) { $Multiplier = int( rand( $MultiplierPercentage * $CanvasXPixels / 200 ) ) }

    #say __LINE__ . '  ' . $MultiplierPercentage . '   ' . $Multiplier . '   ' . $CanvasXPixels;

    GetHelixData;
    DrawHelix;

    $MainWindow->update();
    return;
}

#---------------------------------------------------------------------------
sub ClearButton {
    Log("----- Clear BUTTON -----");
    $Canvas->addtag( 'everything', 'all' );
    $Canvas->delete( 'everything', 'all' );
    ConfigTools;
    return;
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
    return;
}

#---------------------------------------------------------------------------
sub PSOut {
    my $x = localtime;
    $x =~ s/[ :]//gix;    #remove spaces and : from the date
    $Canvas->postscript( -file => "$x.ps" );
    my $answer = $MainWindow->messageBox(
        -title   => 'File saved as PostScript file',
        -message => "File name:\n$x.ps",
        -type    => 'Ok',
        -icon    => 'info',
        -default => 'Ok'
    );
    return;
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
Crimson~#DC143C~<<<
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
Darkorange~#FF8C00
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
Fuchsia~#FF00FF~<<<
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
Indigo~#4B0082~<<<
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
Lime~#00FF00~<<<
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
Teal~#008080~<<<
Thistle~#D8BFD8
Tomato~#FF6347
Turquoise~#40E0D0
Violet~#EE82EE
Wheat~#F5DEB3
White~#FFFFFF
WhiteSmoke~#F5F5F5
Yellow~#FFFF00
YellowGreen~#9ACD32
