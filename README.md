# NAME

WWW::GooglePlay::Scraper - Get software rank/review/rate on Google Play.

# SYNOPSIS

    use WWW::GooglePlay::Scraper;
    use Data::Dumper;

    my $obj = WWW::GooglePlay::Scraper->new(wait => 5);

    my $info = $obj->app_info(
                              app => ['jp.co.fenrir.android.sleipnir'],
                              store => ['ja','en'],
                             );

    print Dumper $info;

    # result
    # $VAR1 = {
    #           'jp.co.fenrir.android.sleipnir' => {
    #                                                'en' => {
    #                                                          'store_name_jp' => "\x{82f1}\x{8a9e}",
    #                                                          'total_rank' => undef,
    #                                                          'new_rank' => undef,
    #                                                          'reviews' => [
    #                                                                         {
    #                                                                           'date' => ' on March 27, 2012',
    #                                                                           'title' => '...',
    #                                                                           'message' => ' ..... '
    #                                                                         },
    #                                                                         {
    #                                                                           'date' => ' on February 21, 2012',
    #                                                                           'title' => '***',
    #                                                                           'message' => ' .....'
    #                                                                         }
    #                                                                       ],
    #                                                          'genre_id' => 'COMMUNICATION',
    #                                                          'app_name' => 'Sleipnir Mobile - Web Browser',
    #                                                          'genre_rank' => 25,
    #                                                          'store_name' => 'English',
    #                                                          'store_info' => {
    #                                                                            'name_jp' => "\x{82f1}\x{8a9e}",
    #                                                                            'name' => 'English'
    #                                                                          },
    #                                                          'artist_id' => 'Fenrir Inc.',
    #                                                          'ratings' => {
    #                                                                         'detail' => [
    #                                                                                     '742',
    #                                                                                     '566',
    #                                                                                     '282',
    #                                                                                     '107',
    #                                                                                     '101'
    #                                                                                   ],
    #                                                                         'summary' => {
    #                                                                                      'average' => '4.0',
    #                                                                                      'votes' => '1798'
    #                                                                                    }
    #                                                                       },
    #                                                          'price' => '0',
    #                                                          'genre_name' => 'Communication'
    #                                                        },
    #                                                'ja' => {
    #                                                          'store_name_jp' => "\x{65e5}\x{672c}\x{8a9e}",
    #                                                          'total_rank' => undef,
    #                                                          'reviews' => [
    #                                                                         {
    #                                                                           'date' => '2012/03/27',
    #                                                                           'title' => '...',
    #                                                                           'message' => " ..... "
    #                                                                         },
    #                                                                         {
    #                                                                           'date' => '2012/03/27',
    #                                                                           'title' => "...",
    #                                                                           'message' => " ..... "
    #                                                                         }
    #                                                                       ],
    #                                                          'genre_id' => 'COMMUNICATION',
    #                                                          'app_name' => "Sleipnir Mobile - \x{30a6}\x{30a7}\x{30d6}\x{30d6}\x{30e9}\x{30a6}\x{30b6}",
    #                                                          'genre_rank' => 25,
    #                                                          'store_name' => "\x{65e5}\x{672c}",
    #                                                          'store_info' => {
    #                                                                            'name_jp' => "\x{65e5}\x{672c}\x{8a9e}",
    #                                                                            'name' => "\x{65e5}\x{672c}"
    #                                                                          },
    #                                                          'artist_id' => 'Fenrir Inc.',
    #                                                          'ratings' => {
    #                                                                         'detail' => [
    #                                                                                     '742',
    #                                                                                     '566',
    #                                                                                     '282',
    #                                                                                     '107',
    #                                                                                     '101'
    #                                                                                   ],
    #                                                                         'summary' => {
    #                                                                                      'average' => '4.0',
    #                                                                                      'votes' => '1798'
    #                                                                                    }
    #                                                                       },
    #                                                          'price' => '0',
    #                                                          'genre_name' => "\x{901a}\x{4fe1}"
    #                                                        }
    #                                              }
    #         };

# DESCRIPTION

# Methods

## new

    blah blah

    - wait

        set interval (second). per app, per store.

## app\_info

    Get application information.

    - app

        set application identifier code.

        ex.
          app => 'jp.co.fenrir.android.sleipnir',
          app => \['jp.co.fenrir.android.sleipnir', 'jp.co.fenrir.android.sleipnir\_black'\],
         ......

    - store

        set lang\_code. By default, get info from all languages.

        ex.
          store => 'ja',
          store => \['ja','en'\],
          ......

## app\_base\_info

Get application information without ranking.

## genre\_rank

Get ranking (genre).

NOTE: args is same as app\_info/app\_base\_info, but only one app/one store ('app' and 'store' is not array\_ref).

NOTE: all store returns same value.

ex.
  $obj->genre\_rank(
                   app => 'jp.co.fenrir.android.sleipnir',
                   store => 'ja'
                  );
  \# $VAR1 = 25;

## total\_rank

Get ranking (total)

ex.
  $obj->total\_rank(
                   app => 'com.skype.raider',
                   store => 'en'
                  );
  \# $VAR1 = 2;

# AUTHORS

KAWABATA, Kazumichi (Higemaru) <kawabata@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# SEE ALSO

Google Play: [https://play.google.com/store](https://play.google.com/store)


