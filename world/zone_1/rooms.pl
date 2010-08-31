######################################################################
# This file is involved w/ the alpha-level room system for ChunkyMUD.#
######################################################################
# This zone is a silly rendition of the Confex Office. It is also a  #
# prototype.                                                         #
######################################################################

my $desc;
my $znum = 1;

$main::World->z_newZone($znum, "Confex FuNhOuSe", "malander/sandrews");

######################################################################
$main::World->z_setRoomTitle($znum, 1, 'Entrance to the Confex FuNhOuSe');
$desc = <<"EOD";
        Here you at the entrance to a Microsoft Competitor. We hate Microsoft.
Or perhaps the creator of this strange universe hates Microsoft... Anyway,
that's not important! What's important is that you happen to be standing in
a floating void with only one exit! How could that have gone unnoticed..?
Stepping through that aforementioned exit, has no way back.. How could you
have forgotten to say that... Wait... Does that make sense?... If you didn't
know that, how could you have said that.... Bork42! Bork42! Hut, hut, hike!
EOD

$main::World->z_setRoomDesc($znum, 1, $desc);
$main::World->z_setExits($znum, 1, 'e', 2);
$main::World->z_setExits($znum, 1, 'w', -11);

######################################################################
$main::World->z_setRoomTitle($znum, 2, 'A walkway in the office');
$desc = <<"EOD";
        A walkway into the Confex Office, ahead you can see blindingly bright
overhead lights on. Strange, considering there are COMPUTER MONITORS in this
office. In fact, these lights are Glare-o-Matic brand, designed for 100%
maximum screen glare creation. They're even XML-Optimized, Java-Compatible,
and Buzzzzzzzz-Word Compliant.

        Step into the light, Homer!
        OWWWWWWWWW!!

        You could checkout the closet to the south!
EOD

$main::World->z_setRoomDesc($znum, 2, $desc);
$main::World->z_setExits($znum, 2, 's', 3);
$main::World->z_setExits($znum, 2, 'e', 4);

######################################################################
$main::World->z_setRoomTitle($znum, 3, 'The office coat-storage facility aka The Closet');
$desc = <<"EOD";
      Pointer Error! - This room description was lost because Malander is a
  poopy-head!
EOD

$main::World->z_setRoomDesc($znum, 3, $desc);
$main::World->z_setExits($znum, 3, 'n', 2);

######################################################################
$main::World->z_setRoomTitle($znum, 4, 'A walkway in the office');
$desc = <<"EOD";
        The light is stronger here -- strong enough to make one's eyes
flinch. To the north is a broken window, that Building Maintenance has not
yet repaired. For a month. Confex employees have not put warning signs around
it, but rather, a Sharpie was used to scrawl the following on the wall near it:
        "Stressed from debugging? Out you go!"
EOD

$main::World->z_setRoomDesc($znum, 4, $desc);
$main::World->z_setExits($znum, 4, 'n', 5);
$main::World->z_setExits($znum, 4, 'e', 6);
$main::World->z_setExits($znum, 4, 'w', 2);

######################################################################
$main::World->z_setRoomTitle($znum, 5, 'Out a broken window!');
$desc = <<"EOD";
        Suicide is not the answer to fixing a bug!
Thy salvation lies within the statements, two - warn() and caller()!
If tis the Camel you seek, then go to the Cave of the Unix Sysadmin --
Richard's Desk, and thou shalt find it there!
EOD

$main::World->z_setRoomDesc($znum, 5, $desc);

######################################################################
$main::World->z_setRoomTitle($znum, 6, 'A wide-open office environment');
$desc = <<"EOD";
        You are in a wide-open office environment, comprising the open
communications philosophy of Confex. Have you registered your AIM name yet?
EOD

$main::World->z_setRoomDesc($znum, 6, $desc);
$main::World->z_setExits($znum, 6, 'w', 4);
$main::World->z_setExits($znum, 6, 's', 7);

######################################################################
$main::World->z_setRoomTitle($znum, 7, 'In front of a live airing of Jerry Springer...');
$desc = <<"EOD";
        Out of a strange mist, you see 'out of control' teenagers wearing
bowties and JAPH shirts with giant Camels on the back. Mr. Springer is
preaching faint banter about 'What a travesty these so-called Perl Users
are...', but you can barely make out what he is saying.
EOD

$main::World->z_setRoomDesc($znum, 7, $desc);
$main::World->z_setExits($znum, 7, 'n', 6);
$main::World->z_setExits($znum, 7, 's', 8);

######################################################################
$main::World->z_setRoomTitle($znum, 8, 'A path on the yellow brick road');
$desc = <<"EOD";
        The yellow brick road,
        the yellow brick road,
        follow it blindly,
        and you shan't find Gold Code.

        The yellow brick road,
        the yellow brick road,
        comment code kindly,
        and shiny code will appear in thy abode!
EOD

$main::World->z_setRoomDesc($znum, 8, $desc);
$main::World->z_setExits($znum, 8, 'n', 7);
$main::World->z_setExits($znum, 8, 'w', 9);

######################################################################
$main::World->z_setRoomTitle($znum, 9, "The road to the Grinch's House");
$desc = <<"EOD";
        You are on the road to the Grinch's House. Or maybe, you are
on the road away from it. It's the same freakin' road!

        But this code, be not gold,
        So it doesn't know,
        whether your bold,
        or your feet are cold!
EOD

$main::World->z_setRoomDesc($znum, 9, $desc);
$main::World->z_setExits($znum, 9, 'n', 10);
$main::World->z_setExits($znum, 9, 'e', 8);

######################################################################
$main::World->z_setRoomTitle($znum, 10, "oh NO IT'S THE GRINCH, RUN AWAY!");
$desc = <<"EOD";
        His name is Jeff. He gets flustered easily while debugging. Lusers
commonly assume him as the Unstoppable Generator of Entropy in the Computer
Software Universe. As a result, he has earned several titles:

        'Jeff, Bringer of Bugs', 'Coder of Catastrophes', 'Bearer of Bad
News Belating the Arrival of Bugs'..

        You don't want to get on his bad side. Or he might unlink() you.
EOD

$main::World->z_setRoomDesc($znum, 10, $desc);
$main::World->z_setExits($znum, 10, 's', 9);

######################################################################
$main::World->z_setRoomTitle($znum, 11, "This is a test");
$desc = <<"EOD";
        This is a test of the emergency "illusionary wall" code.
        Please stand by.
EOD

$main::World->z_setRoomDesc($znum, 11, $desc);
$main::World->z_setExits($znum, 11, 'e', -1);
$main::World->z_setExits($znum, 11, 'w', '2:1');   # Link to the Village