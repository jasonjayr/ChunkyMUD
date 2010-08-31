use strict;

###################################################
# defines.pl - Contains subroutines that are used #
# as global constants.                            #
# -malander 3/6/2001 tarael200@aol.com            #
###################################################

# Timer defines
sub D_PLAYER_SAVE { 60 }            # Save a single player every minute
sub D_LAGOUT { 300 }                # Run lagout timer check every 5 mins

# Lagout 
sub D_IDLELIMIT { 600 }             # Idle for 10 mins and out you go!

# Object Location Types
sub L_ROOM { 1 }
sub L_PLAYER { 2 }

# Command Defines
sub C_STANDARD { 1 } 								# All players have access
sub C_WIZARD { 2 }									# Wizard-only command
sub C_SOCIAL { 3 }									# Commands that are socials

1;
