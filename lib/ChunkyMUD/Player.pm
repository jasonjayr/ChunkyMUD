package ChunkyMUD::Player;
use strict;
use warnings;
use Moose;
use File::Slurp qw(read_file write_file);
use ChunkyMUD::Meta::Attribute::ShouldBeStored;
use File::Path qw(mkpath);

use JSON;

#@persist_fields = qw(Name Gender Curzone Curroom Level Abbrev Autoexit Title Brief);
#@fields = (@persist_fields,qw(LastCmd LastCmdHack));

has Name      => (is=>'ro', isa=>'Str', writer=>'_set_name', required=>1, traits=>[qw/ShouldBeStored/]);
has Gender    => (is=>'rw', isa=>'Str', default=>'n', traits=>[qw/ShouldBeStored/] );
has Curzone   => (is=>'rw', isa=>'Int', default=>2, traits=>[qw/ShouldBeStored/]  );
has Curroom   => (is=>'rw', isa=>'Int', default=>1, traits=>[qw/ShouldBeStored/]   );
has Level     => (is=>'rw', isa=>'Int', default=>1, traits=>[qw/ShouldBeStored/]   );
has Abbrev    => (is=>'rw', isa=>'Int', default=>0, traits=>[qw/ShouldBeStored/]   );
has Autoexit  => (is=>'rw', isa=>'Int', default=>1, traits=>[qw/ShouldBeStored/]   );

has Title     => (is=>'rw', isa=>'Str', traits=>[qw/ShouldBeStored/] );
has Brief     => (is=>'rw', isa=>'Int', traits=>[qw/ShouldBeStored/] );

# This is probably a session Cmd.
has LastCmd   => (is=>'rw', isa=>'Str');
has State     => (is=>'rw', isa=>'Str');

# weak because the Session has a ref back to the player too.
has Session =>   (is=>'rw', isa=>'ChunkyMUD::Session', weak_ref=>1);

around BUILDARGS=> sub  {
	my $orig = shift;
	my $class = shift;

	my $name = shift;

	if(defined($name)) { 
		$class->$orig(Name=>$name);
	} else { 
		$class->$orig($name,@_);
	}
};


sub NormalizedName { 
	my ($self) = @_;

	my $name = lc $self->Name;
	$name =~ s/\W//g;
	
	return $name
}

sub pfile_path { 
	my ($self) = @_;
	
	my $name = $self->NormalizedName;

	return sprintf('players/%1.1s', $name);
}

sub pfile_name { 
	my ($self) = @_;
	
	my $name = $self->NormalizedName;

	return sprintf('%s/%s.js', $self->pfile_path, $name);
}


sub Load {
	my ($self) = @_;

	my $file = $self->pfile_name();

	if(-e $file) {  
		my @lines = read_file $file; 
		my $hash = from_json(join('',@lines));

		foreach my $field (keys %$hash) { 
			my $writer = $self->meta->find_attribute_by_name($field)->get_write_method;
			if($writer) { 
				$self->$writer($hash->{$field}) if (defined($hash->{$field}));
			}
		}
		# return true that we were able to read and set values;
		return 1;
	}
}

sub Save { 
	my ($self) = @_;

	my %tosave;

	my $meta = $self->meta;
	for my $attribute ( 
			map { $meta->get_attribute($_) } sort $meta->get_attribute_list ) {

		if($attribute->does('ChunkyMUD::Meta::Attribute::ShouldBeStored')) { 
			my $name = $attribute->get_read_method;
			$tosave{$attribute->name} =	$self->$name;
		}
	}
	mkpath($self->pfile_path);

	write_file $self->pfile_name(),
			   to_json(\%tosave, {pretty=>1});

	return 1;
}



__PACKAGE__->meta->make_immutable;




1;
