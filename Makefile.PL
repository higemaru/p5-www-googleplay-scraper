use inc::Module::Install;
name 'WWW-GooglePlay-Scraper';
author 'KAWABATA, Kazumichi (Higemaru) <kawabata@cpan.org>';
perl_version '5.008';
all_from 'lib/WWW/GooglePlay/Scraper.pm';

test_requires 'Test::Base';

requires 'LWP::UserAgent';
requires 'Web::Scraper';

WriteAll;
