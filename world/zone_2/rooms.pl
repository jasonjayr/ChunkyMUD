#######################################################################
# This file is involved w/ the room system for ChunkyMUD.             #
#######################################################################
# This is a small village developed by myself, malander. I'm planning #
# on turning this into the main starting town at some point, but for  #
# now it's just a zone used to test the new world code. 3/5/2001      #
#######################################################################

my $desc;
my $znum = 2;

$main::World->z_newZone($znum, "Village of the Camel", "malander");

######################################################################
$main::World->z_setRoomTitle($znum, 1, 'On a dirt road');
$desc = <<"EOD";
    This dirt road is worn from the heels of many a weary traveler. To the north
lies a path to the sacred Village of the Camel. To the south lay a glowing red
portal - the Entrance to the Confex FuNhOuSe.
EOD

$main::World->z_setRoomDesc($znum, 1, $desc);
$main::World->z_setExits($znum, 1, 'n', 2);
$main::World->z_setExits($znum, 1, 's', '1:11'); # Link to the secret Portal room in Confex FuNhOuSe

######################################################################
$main::World->z_setRoomTitle($znum, 2, 'Before the Village');
$desc = <<"EOD";
    Well, this is the end of the line for now until Malander builds more rooms.
EOD

$main::World->z_setRoomDesc($znum, 2, $desc);
$main::World->z_setExits($znum, 2, 's', 1);