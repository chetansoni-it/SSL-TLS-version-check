#!/usr/bin/env perl

use strict;
use Test::More;
use Data::Dumper;
use JSON;

my $tests = 0;

my (
	$out,
	$json,
	$found,
);
# OK
pass("Running testssl.sh against ssl.sectionzero.org"); $tests++;
$out = `./testssl.sh -H --jsonfile tmp.json --color 0 ssl.sectionzero.org`;
$json = json('tmp.json');

# It is better to have findings in a hash
# Look for a leaf cert match in the process.
my $found = 0;
my %findings;
foreach my $f ( @$json ) {
	$findings{$f->{id}} = $f;
	if ( $f->{finding} =~ /matches the leaf certificate/ ) {
		$found++;
	}
}
is($found,1,"We found 1 'matches the leaf certificate' finding"); $tests++;
like($out,'/Leaf cert match/',"There is a 'Leaf cert match' in the text output"); $tests++;

# Sub CA match
ok( exists $findings{"hpkp_YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg"},"We have a finding for key YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg"); $tests++;
like($findings{"hpkp_YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg"}->{finding},'/Intermediate CA key matches a key pinned in the HPKP header/',"We have our Sub CA finding"); $tests++;
is($findings{"hpkp_YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg"}->{severity}, "OK", "The finding is ok"); $tests++;
like($out,'/Sub  CA   match \: YLh1dUR9y6Kja30RrAn7JKnbQG\/uEtLMkBgFF2Fuihg/',"There is a 'Sub CA match' in the text output"); $tests++;

# Root CA match Lets encrypt
ok( exists $findings{"hpkp_Vjs8r4z+80wjNcr1YKepWQboSIRi63WsWXhIMN+eWys"},"We have a finding for key Vjs8r4z+80wjNcr1YKepWQboSIRi63WsWXhIMN+eWys"); $tests++;
like($findings{"hpkp_Vjs8r4z+80wjNcr1YKepWQboSIRi63WsWXhIMN+eWys"}->{finding},'/Root CA key matches a key pinned in the HPKP header/',"This is a Root CA finding"); $tests++;
like($findings{"hpkp_Vjs8r4z+80wjNcr1YKepWQboSIRi63WsWXhIMN+eWys"}->{finding},'/DST Root CA X3/',"Correct Root CA"); $tests++;
like($findings{"hpkp_Vjs8r4z+80wjNcr1YKepWQboSIRi63WsWXhIMN+eWys"}->{finding},'/The CA is part of the chain/',"CA is indeed part of chain"); $tests++;
is($findings{"hpkp_Vjs8r4z+80wjNcr1YKepWQboSIRi63WsWXhIMN+eWys"}->{severity}, "OK", "The finding is ok"); $tests++;
like($out,'/Root CA   match \: Vjs8r4z\+80wjNcr1YKepWQboSIRi63WsWXhIMN\+eWys/',"There is a 'Root CA match' in the text output"); $tests++;

# Root CA StartCom
ok( exists $findings{"hpkp_5C8kvU039KouVrl52D0eZSGf4Onjo4Khs8tmyTlV3nU"},"We have a finding for key 5C8kvU039KouVrl52D0eZSGf4Onjo4Khs8tmyTlV3nU"); $tests++;
like($findings{"hpkp_5C8kvU039KouVrl52D0eZSGf4Onjo4Khs8tmyTlV3nU"}->{finding},'/Root CA key matches a key pinned in the HPKP header/',"This is a Root CA finding"); $tests++;
like($findings{"hpkp_5C8kvU039KouVrl52D0eZSGf4Onjo4Khs8tmyTlV3nU"}->{finding},'/StartCom Certification Authority/',"Correct Root CA"); $tests++;
like($findings{"hpkp_5C8kvU039KouVrl52D0eZSGf4Onjo4Khs8tmyTlV3nU"}->{finding},'/The CA is not part of the chain/',"CA is indeed NOT part of chain"); $tests++;
is($findings{"hpkp_5C8kvU039KouVrl52D0eZSGf4Onjo4Khs8tmyTlV3nU"}->{severity}, "OK", "The finding is ok"); $tests++;
like($out,'/Root CA   match \: 5C8kvU039KouVrl52D0eZSGf4Onjo4Khs8tmyTlV3nU/',"There is a 'Root CA match' in the text output"); $tests++;

# Bad PIN
ok( exists $findings{"hpkp_123bad123bad123bad123bad123bad123bd123bad12"},"We have a finding for key 123bad123bad123bad123bad123bad123bd123bad12"); $tests++;
like($findings{"hpkp_123bad123bad123bad123bad123bad123bd123bad12"}->{finding},'/doesn\'t match anything/',"It doesn't match indeed"); $tests++;
is($findings{"hpkp_123bad123bad123bad123bad123bad123bd123bad12"}->{severity}, "WARN", "The finding is ok"); $tests++;
like($out,'/Unmatched key   : 123bad123bad123bad123bad123bad123bd123bad12/',"There is an 'unmatched key' in the text output"); $tests++;

like($findings{hpkp_keys}->{finding},'/5 keys pinned/',"5 keys pinned in json"); $tests++;
like($out,'/\# of keys: 5/',"5 keys pinned in text output"); $tests++;

like($findings{hpkp_age}->{finding},'/90 days/',"90 days in json"); $tests++;
like($out,'/90 days/',"90 days in text output"); $tests++;

like($findings{hpkp_subdomains}->{finding},'/this domain only/',"this domain only in json"); $tests++;
like($out,'/just this domain/',"just this domain text output"); $tests++;

like($findings{hpkp_preload}->{finding},'/NOT marked for/',"no preloading in json"); $tests++;

done_testing($tests);

sub json($) {
	my $file = shift;
	$file = `cat $file`;
	unlink $file;
	return from_json($file);
}