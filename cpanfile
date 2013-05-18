requires 'LWP::UserAgent';
requires 'Web::Scraper';
requires 'perl', '5.008';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.59';
    requires 'Test::Base';
};
