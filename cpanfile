requires 'LWP::UserAgent';
requires 'Web::Scraper';
requires 'perl', '5.008001';

on build => sub {
    requires 'Test::Base';
};
