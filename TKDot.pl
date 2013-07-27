use Tk;

$mw  = Tk::MainWindow->new;
$h   = 20;
$can = $mw->Canvas( -width => 320, -height => 240 )->pack();
$img = $mw->Photo( -width => 320, -height => 240, -palette => '256/256/256' );
$img->blank;
$can->createImage( 0, 0, -image => $img, -anchor => 'nw' );

$img->put(
    [
        '#6363ce', '#6363ce', '#9c9cff', '#9c9cff', '#ceceff', '#ceceff',
        '#efefef', '#efefef', '#efefef', '#efefef', '#efefef', '#efefef',
        '#ceceff', '#ceceff', '#9c9cff', '#9c9cff', '#6363ce', '#6363ce',
        '#31319c', '#31319c',
    ],
    -to => 102,
    80,
    4,
    $h
);

#$img->put('red', -to => 160, 120, 20, 100);
#printf "%6.6X", $img->get(160, 120);

MainLoop();
