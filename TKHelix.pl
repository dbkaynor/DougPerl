use strict;
use warnings;
use UtilsDBK qw(:all);
use Tk;
use Tk::BrowseEntry;
use Tk::Checkbutton;
use Tk::Pane;
use feature ':5.10'; # loads all features available in perl 5.10


sub Log($);
sub ConfigTools;
sub RandColor;
sub Round($);
sub GetPoint($);
sub GetHelixData;
sub DrawHelix;
sub PSOut;
sub Help;

use constant MAXLINEWIDTH => scalar 25;

my $PerlNamePath = ((split('\.',$0))[0]);
my $PerlName = ((split('\\\\',$PerlNamePath))[-1]);
my $LogFileName = $PerlName . '.log';

my $MaxMultiplier = 350;
my $Multiplier = $MaxMultiplier;

my $XOffset = 425;
my $XStep = 10;
my $YOffset = 250;
my $YStep = 10;

my $Degrees = 5;
my $FGColor = 'White';
my $BGColor = 'Black';
my $FixedSize = FALSE;
my $FixedXLocation = FALSE;
my $FixedYLocation = FALSE;
my $AutoFGColor = FALSE;
my $VaryFGColor = FALSE;
my $AutoBGColor = FALSE;
my $AutoDegrees = FALSE;
my $AutoLineWidth  = FALSE;
my $AutoClear = TRUE;
my $AutoRepeat = 0;
my $LineWidth = 1;
my $mwX = 0;
my $mwY = 0;
my $Horz_scaleMin = 0;
my $Horz_scaleMax = 100;
my $Vert_scaleMin = 0;
my $Vert_scaleMax = 100;
my $MWGeometry;
my $canvas;

my @BGColorChoices = ();
my @FGColorChoices = ();
my @ColorList = ();
my @Array = ();

my $mw = MainWindow->new( '-title' => $PerlName );
# $mw->minsize( 450, 300 );
# $mw->maxsize( 900, 600 );
$mw->geometry('1200x750+0+0');
$mw->resizable( TRUE, TRUE );
$mw->bind(
    '<Configure>',
    [
        sub {
            if ( $_[0] =~ /MainWindow/i ) {
                $MWGeometry = $mw->geometry();
                $mw->title( "$PerlName $MWGeometry<<<" );
                ($mwX , my $y) = split(/x/,$MWGeometry);
                ($mwY) = split(/\+/,$y);
                ConfigTools;
            }
          }
    ]
);
#---------------------------------------------------------------------------
# my $pane = $mw->Scrolled(qw/Pane -scrollbars osw/)->pack;
# my $Menu_frame = $mw->Frame( ) ->pack( -side => 'left' );
my $Menu_frame = $mw->Scrolled(qw/Pane -scrollbars osw/, -width => 250)->pack( -side => 'left' , -fill => 'y', -expand => '0' );
my $Canvas_frame = $mw->Frame( ) ->pack( -side => 'left', -fill => 'both', -expand => '1' );

my $One_frame = $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Two_frame = $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Three_frame = $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Four_frame = $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Five_frame = $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );
my $Six_frame = $Menu_frame->Frame( -borderwidth => 1, -relief => 'groove' )
  ->pack( -side => 'top', -fill => 'both', -expand => '1' );

my $B1_frame = $One_frame ->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );
$B1_frame->Button( -text => 'Draw', -command => \&Draw_bttn) ->pack(  );
$B1_frame->Button( -text => 'Clear', -command => \&Clear_bttn) ->pack( );

my $B2_frame = $One_frame ->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );
$B2_frame->Button(-text => 'Zoom 0.9', -command => sub {$canvas->scale('all',$XOffset,$YOffset,0.9,0.9)}) ->pack( -side => 'left', -fill => 'both', -expand => '1' );
$B2_frame->Button(-text => 'Zoom 1.1', -command => sub {$canvas->scale('all',$XOffset,$YOffset,1.1,1.1)}) ->pack( -side => 'left', -fill => 'both', -expand => '1' );

my $B3_frame = $One_frame ->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );
$B3_frame->Button(-text => 'Up', -command => sub {$canvas->addtag('everything', 'all');
  $canvas->move('all', 0, $mwY / 20 * -1)}) ->pack( -side => 'left', -fill => 'both', -expand => '1' );
$B3_frame->Button(-text => 'Down', -command => sub {$canvas->addtag('everything', 'all');
  $canvas->move('all', 0,  $mwY / 20)}) ->pack( -side => 'left', -fill => 'both', -expand => '1' );

my $B4_frame = $One_frame ->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );
$B3_frame->Button(-text => 'Left', -command => sub {$canvas->addtag('everything', 'all');
  $canvas->move('all',  $mwX / 20 * -1, 0)}) ->pack( -side => 'left', -fill => 'both', -expand => '1' );

my $B5_frame = $One_frame ->Frame()->pack( -side => 'top', -fill => 'both', -expand => '1' );
$B5_frame->Button( -text => 'PS out', -command => \&PSOut)
    ->pack( -side => 'left', -fill => 'both', -expand => '1' );
$B5_frame->Button( -text => 'Help', -command =>  \&Help)
    ->pack( -side => 'left', -fill => 'both', -expand => '1' );

$One_frame->Checkbutton(-text => 'Auto clear', -variable => \$AutoClear) ->pack( -side => 'top', -fill => 'both', -expand => '1' );

my $Repeat_scale = $One_frame->Scale(-orient=>'horizontal', -variable => \$AutoRepeat, -width => 8, -label => 'Repeat count') ->pack( -side => 'top' );
$Repeat_scale -> configure( -from => 0, -to => 10);

my $Mult_scale = $Three_frame->Scale(-orient=>'horizontal', -variable => \$Multiplier, -width => 8, -label => 'Size multiplier') ->pack( -side => 'top' );
$Three_frame->Checkbutton(-text => 'Fixed size', -variable => \$FixedSize) ->pack( -side => 'top' );
my $Horz_scale = $Three_frame->Scale(-orient=>'horizontal', -variable => \$XOffset, -width => 8, -label => 'XOffset') ->pack( -side => 'top' );
my $Vert_scale = $Three_frame->Scale(-orient=>'horizontal', -variable => \$YOffset, -width => 8, -label => 'YOffset') ->pack( -side => 'top' );
$Three_frame->Checkbutton(-text => 'Fixed X location', -variable => \$FixedXLocation) ->pack( -side => 'top' );
$Three_frame->Checkbutton(-text => 'Fixed Y location', -variable => \$FixedYLocation) ->pack( -side => 'top' );
my @DegreesChoices = qw/1 2 3 4 5 6 8 9 10 12 15 18 20 24 30 36 40 45 60 72 90 120 180/;
$Four_frame->BrowseEntry(-label => "Degrees", -choices => \@DegreesChoices, -variable => \$Degrees, -width => 5)->pack( -side => 'top' );
$Four_frame->Checkbutton(-text => 'Auto Degrees', -variable => \$AutoDegrees) ->pack( -side => 'top' );

my $LW_scale = $Four_frame->Scale(-orient=>'horizontal', -variable => \$LineWidth, -width => 8, -label => 'Line width',-from => 1, -to => MAXLINEWIDTH ) ->pack( -side => 'top' );

$Four_frame->Checkbutton(-text => 'Auto line width', -variable => \$AutoLineWidth ) ->pack( -side => 'top' );

foreach $_ (<DATA>) {push @ColorList, Trim($_)};
push @FGColorChoices, @ColorList;
$Five_frame->BrowseEntry(-label => "FGC", -choices => \@FGColorChoices, -variable => \$FGColor, -width => 20,
    -browsecmd => \&FGColorSet, -listcmd => \&FGColorSet, -command => \&FGColorSet) -> pack( -side => 'top' );
$Five_frame->Checkbutton(-text => 'Auto FG color', -variable => \$AutoFGColor) ->pack( -side => 'top' );
$Five_frame->Checkbutton(-text => 'Vary FG color', -variable => \$VaryFGColor) ->pack( -side => 'top' );
sub FGColorSet {
    my $t = (split('~',$FGColor))[1];
    unless ($t) {$t = $FGColor};
    $canvas->itemconfigure('all', -fill => $t);
}

push @BGColorChoices, @ColorList;
$Five_frame->BrowseEntry(-label => "BGC", -choices => \@BGColorChoices, -variable => \$BGColor, -width => 20,
   -browsecmd => \&BGColorSet, -listcmd => \&BGColorSet, -command => \&BGColorSet) -> pack( -side => 'top' );

sub BGColorSet {
    my $t = (split('~',$BGColor))[1];
    unless ($t) {$t = $BGColor};
    $canvas-> configure(-background => $t);
}

$Five_frame->Checkbutton(-text => 'Auto BG color', -variable => \$AutoBGColor) ->pack( -side => 'top' );
@ColorList = (); #Free the memory

$canvas = $Canvas_frame->Canvas( -cursor=>"crosshair",-background => $BGColor)->pack(-fill => 'both', -expand => '1' );

#---------------------------------------------------------------------------
srand(time ^ $$);

open LOG, ">" . $LogFileName;
close LOG;

sub BGColor {
    $BGColor = @BGColorChoices[int(rand(@BGColorChoices))];
    $canvas-> configure(-background => (split('~',$BGColor))[1]);
}
sub FGColor {
    $FGColor = @FGColorChoices[int(rand(@FGColorChoices))];
    $canvas->itemconfigure('all', -fill => (split('~',$FGColor))[1]);
}
$canvas->Tk::bind("<Button-1>", [ \&FGColor]);
$canvas->Tk::bind("<Button-3>", [ \&BGColor]);

Log("DBGVIEWCLEAR");
Log("PerlNamePath::$PerlNamePath\nPerlName::$PerlName\nLogFileName::$LogFileName");

MainLoop;
#---------------------------------------------------------------------------
sub Log($) {
    open LOG, ">>" . $LogFileName;
    say LOG $_[0];
    close LOG;
}
#---------------------------------------------------------------------------
sub ConfigTools {
    if ($XOffset < $YOffset)
        {$MaxMultiplier = int($mwX / 3)}
    else
        {$MaxMultiplier = int($mwY / 3)}

    unless ($FixedSize) {$Multiplier = int($MaxMultiplier / 2)};

    $Mult_scale -> configure( -from => 0, -to => $MaxMultiplier);

    $Horz_scaleMin = 200;
    $Horz_scaleMax = $mwX - 400;
    $Horz_scale -> configure( -from => $Horz_scaleMin, -to => $Horz_scaleMax);

    $Vert_scaleMin = 200;
    $Vert_scaleMax = $mwY - 200;
    $Vert_scale -> configure( -from => $Vert_scaleMin, -to => $Vert_scaleMax);
}
#---------------------------------------------------------------------------
sub RandColor {
    my $Color = sprintf("#%06X",(((rand(0xff) << 8) + rand(0xff) << 8) + rand(0xff)));
    return $Color;
}
#---------------------------------------------------------------------------
sub Round($) {
    my($number) = shift;
    return int($number + .5 * ($number <=> 0));
}
#---------------------------------------------------------------------------
sub GetPoint($)
{
    my ($AngleD) = @_;
    my $AngleR = $AngleD / 180 * PI;

    my @Out;
    $Out[0] = Round((cos($AngleR)*$Multiplier)+$XOffset);  #X value
    $Out[1] = Round((sin($AngleR)*$Multiplier)+$YOffset);  #Y value
    return @Out;
}
#---------------------------------------------------------------------------
sub GetHelixData {
   #Generate an array of circle values
   my @TArray = ();
   for (my $X = 0 ; $X < 360; $X += $Degrees )
    {
        my @tmp = GetPoint($X);
        push(@TArray ,@tmp);
    }

    my $x = @TArray;
    Log "$x $mwY  $mwX   ??? DBK";

    #Now pull the values and make them into a helix
    my $Xval = 1;
    my $Yval = 1;
    while (($Xval > 0) and ($Xval < $mwX) and ($Yval > 0) and ($Yval < $mwY))
    {
         my $count = 0;
         foreach $_ (@TArray)
          {
            # say sprintf " %d GetHelixData: %d %d --- %d %d" ,$count, $Xval, $mwX, $Yval, $mwY;
            # if (($Xval < 0) or ($Xval > $mwX) or ($Yval < 0) or ($Yval > $mwY)) {say "***";last};
             $count++;
             $Xval += 0.2;
             $Yval += 0.1;
             if ($count % 2 == 0)
                {push(@Array ,$_ + $Xval)}
             else
                {push(@Array ,$_ + $Yval)}
           # Log sprintf "GetHelixData: %d  %d   %d" ,$count, $Xval, $Yval;
          }
    }

}
#---------------------------------------------------------------------------
sub DrawHelix {
   my $tcolor = (split('~',$FGColor))[1];
   unless ($tcolor) {$tcolor = $FGColor};
   $canvas->createLine (@Array, -fill => $tcolor, -width => $LineWidth);
   $mw->update();
}
#---------------------------------------------------------------------------
sub Draw_bttn {
      Log("----- Draw BUTTON -----");
	  @Array = ();
	  LogAll();
	  if ($AutoClear) {Clear_bttn()};
	  if ($AutoLineWidth) {$LineWidth = int(rand(MAXLINEWIDTH))+1};
	  if ($AutoDegrees) {$Degrees = @DegreesChoices[int(rand(@DegreesChoices))]};
	  if ($AutoFGColor) {$FGColor = @FGColorChoices[int(rand(@FGColorChoices))]};
	  if ($AutoBGColor) {
	       $BGColor = @BGColorChoices[int(rand(@BGColorChoices))];
	       $canvas-> configure(-background => (split('~',$BGColor))[1]);
	   };
	  unless ($FixedSize) {$Multiplier = int(rand($MaxMultiplier))+5};
	  unless ($FixedXLocation) { $XOffset = int(rand($Horz_scaleMax))+$Horz_scaleMin};
	  unless ($FixedYLocation) { $YOffset = int(rand($Vert_scaleMax))+$Vert_scaleMin};
      #Log(sprintf("Multiplier:%4d XOffset:%4d XStep:%4d YOffset:%4d YStep:%4d",$Multiplier,$XOffset,$XStep,$YOffset,$YStep));
      #Log(sprintf "Degrees:%2d Points:%d FGColor:%-8s BGColor:%-8s",$Degrees,360/$Degrees,$FGColor,$BGColor);
      GetHelixData;
      DrawHelix;

      $mw->update();
}

#---------------------------------------------------------------------------
sub Clear_bttn {
   Log("----- Clear BUTTON -----");
   $canvas->addtag('everything', 'all');
   $canvas->delete('everything', 'all');
   ConfigTools;
  # system('cls');
}
#---------------------------------------------------------------------------
sub Help {
      my $HelpMessage = "Move to center\n".
                        "Presets\n";
      my $answer = $mw->messageBox(
                -title   => "Help $PerlName",
                -message => $HelpMessage,
                -type    => 'Ok',
                -icon    => 'info',
                -default => 'Ok'
       )
}
#---------------------------------------------------------------------------
sub PSOut {
      my $x = localtime;
      $x =~ s/[ :]//gi; #remove spaces and : from the date
      $canvas->postscript(-file => "$x.ps");
      my $answer = $mw->messageBox(
                -title   => 'File saved as PostScript file',
                -message => "File name:\n$x.ps",
                -type    => 'Ok',
                -icon    => 'info',
                -default => 'Ok'
       )
}
#---------------------------------------------------------------------------
sub LogAll {
Log("MaxMultiplier::$MaxMultiplier\nDegrees::$Degrees\nFixedSize::$FixedSize\nFixedXLocation::$FixedXLocation\nFixedYLocation::$FixedYLocation\nAutoFGColor::$AutoFGColor\nVaryFGColor::$VaryFGColor\nAutoBGColor::$AutoBGColor\nAutoDegrees::$AutoDegrees\nAutoLW::$AutoLineWidth \nAutoClear::$AutoClear\nAutoRepeat::$AutoRepeat\nLineWidth::$LineWidth\nmwX::$mwX\nmwY::$mwY\nHorz_scaleMin::$Horz_scaleMin\nHorz_scaleMax::$Horz_scaleMax\nVert_scaleMin::$Vert_scaleMin\nVert_scaleMax::$Vert_scaleMax\nMWGeometry::$MWGeometry");
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
