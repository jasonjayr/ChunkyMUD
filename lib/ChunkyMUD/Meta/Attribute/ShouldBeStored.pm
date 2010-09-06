package ChunkyMUD::Meta::Attribute::ShouldBeStored;
use Moose::Role;

has storable => (
		is        => 'ro',
		isa       => 'Bool',
		default	  => 1,
		);

package Moose::Meta::Attribute::Custom::Trait::ShouldBeStored;
sub register_implementation {'ChunkyMUD::Meta::Attribute::ShouldBeStored'}

1;
