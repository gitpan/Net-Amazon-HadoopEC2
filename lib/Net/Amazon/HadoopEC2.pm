package Net::Amazon::HadoopEC2;
use Moose;
use Net::Amazon::EC2;
use Net::Amazon::HadoopEC2::Cluster;
use Net::Amazon::HadoopEC2::Group;
our $VERSION = '0.01';

has aws_access_key_id => ( is => 'ro', isa => 'Str', required => 1 );
has aws_secret_access_key => ( is => 'ro', isa => 'Str', required => 1 );
has aws_account_id => ( is => 'ro', isa => 'Str', required => 1 );

has _ec2 => ( 
    is => 'ro', 
    isa => 'Net::Amazon::EC2', 
    required => 1,
    lazy => 1,
    default => sub {
        Net::Amazon::EC2->new(
            AWSAccessKeyId => $_[0]->aws_access_key_id,
            SecretAccessKey => $_[0]->aws_secret_access_key,
        );
    }
);

no Moose;

sub launch_cluster {
    my ($self, $args) = @_;
    Net::Amazon::HadoopEC2::Group->new(
        {
            _ec2           => $self->_ec2,
            name           => $args->{name},
            aws_account_id => $self->aws_account_id,
        }
    )->ensure or return;
    my $cluster = Net::Amazon::HadoopEC2::Cluster->new(
        {
            _ec2     => $self->_ec2,
            name     => $args->{name},
            key_file => $args->{key_file},
        }
    );
    $cluster->launch_cluster( 
        { 
            slaves => $args->{slaves} || 2 ,
            image_id => $args->{image_id},
            key_name => $args->{key_name} || 'gsg-keypair',
        } 
    ) or return;
    return $cluster;
}

sub find_cluster {
    my ($self, $args) = @_;
    Net::Amazon::HadoopEC2::Group->new(
        {
            _ec2           => $self->_ec2,
            name           => $args->{name},
            aws_account_id => $self->aws_account_id,
        }
    )->find or return;
    my $cluster = Net::Amazon::HadoopEC2::Cluster->new(
        {
            _ec2 => $self->_ec2,
            name => $args->{name},
            key_file => $args->{key_file},
        }
    );
    $cluster->find_cluster or return;
    return $cluster;
}

1;

=pod

=head1 NAME

Net::Amazon::HadoopEC2 - perl interface to work with Hadoop-EC2

=head1 SYNOPSYS

    my $hadoop = Net::Amazon::HadoopEC2->new(
        {
            aws_account_id => 'your_aws_account',
            aws_access_key_id => 'your_key',
            aws_secret_access_key => 'your_secret',
        }
    );

    my $cluster = $hadoop->launch_cluster(
        {
            name           => 'hadoop',
            image_id       => 'ami-b0fe1ad9',
            slaves         => 2,
        }
    );

    my $result = $cluster->execute({command => 'ls'});
    warn $result->stdout;

    $cluster->terminate_cluster;

=head1 DESCRIPTION

This module is perl interface to work with Hadoop-EC2.

=head1 METHODS

=head2 new($hashref)

Constructor. Arguments are:

=over 4 

=item aws_access_key_id (required)

Your aws access key.

=item aws_secret_access_key (required)

Your aws secret key.

=item aws_account_id (required)

Your aws account id.

=back

=head2 launch_cluster($hashref)

launchs hadoop-ec2 cluster. Returns L<Net::Amazon::HadoopEC2::Cluster> instance
if launch process succeeded. Arguments are:

=over 4

=item name (required)

Name of the cluster.

=item image_id (required)

The image id (ami) of the cluster.

=item key_name (optional)

The key name to use when launching cluster. the default is 'gsg-keypair'.

=item key_file (required)

Location of the private key file associated with key_name.

=item slaves (optional)

The number of slaves. The default is 2.

=back

=head2 find_cluster($hashref)

finds running cluster satisfying the conditions given by the arguments.
Returns L<Net::Amazon::HadoopEC2::Cluster> instance if found.
Arguments are:

=over 4 

=item name (required)

Name of the cluster.

=item key_file (required)

Location of the private key file to login to the cluster instances.

=back

=head1 AUTHOR

Nobuo Danjou <nobuo.danjou@gmail.com>

=head1 SEE ALSO

L<Net::Amazon::HadoopEC2>

L<Net::Amazon::EC2>

Hadoop - L<http://hadoop.apache.org/>

Hadoop Wiki, AmazonEC2 L<http://wiki.apache.org/hadoop/AmazonEC2>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Net-Amazon-HadoopEC2/trunk Net-Amazon-HadoopEC2

The svn repository of this module is hosted at L<http://coderepos.org/share/>.
Patches and commits are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
