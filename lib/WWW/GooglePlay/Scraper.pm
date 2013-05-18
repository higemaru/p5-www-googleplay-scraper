package WWW::GooglePlay::Scraper;

use strict;
use utf8;
use warnings;

use LWP::UserAgent;
use Web::Scraper;

our $VERSION = '0.11';

sub new {
    my $class = shift;
    my @args = @_;
    my $args_ref = ref $args[0] eq 'HASH' ? $args[0] : {@args};

    my $self = bless{}, ref $class || $class;

    $self->{__STORE_CODES} = _init_countries();
    $self->{__URL_PREF} = 'https://play.google.com/store/apps/';

    $self->{ua} = LWP::UserAgent->new();
    $self->{ua}->timeout(30);
    $self->{ua}->env_proxy;
    $self->{ua}->agent( $self->{__UA} );
    $self->{ua}->ssl_opts (verify_hostname => 0);
    $self->{__WAIT} = $args_ref->{wait} || '1';

    $self;
}

sub app_info {
    my $self = shift;
    my @args = @_;

    #
    # get info from app page
    #

    my $base = $self->app_base_info( @args );

    my $ret = {};
    my $genre_rank;
    my $total_rank;
    my $new_rank;
    for my $app ( keys %$base ) {
        for my $store ( keys %{$base->{$app}} ) {
            my $info = $base->{$app}->{$store};

	    #
	    # rank
	    #

	    if ( $info->{genre_id} and ! $genre_rank ) {
		$genre_rank = $self->genre_rank( app => $app, info => $info );
	    }
	    if ( ! $total_rank ) {
		$total_rank = $self->total_rank( app => $app, info => $info );
	    }
	    if ( ! $new_rank ) {
		$new_rank = $self->new_rank( app => $app, info => $info );
	    }

	    $ret->{$app}->{$store} = {
				      %$info,
				      genre_rank => $genre_rank,
				      total_rank => $total_rank,
				      new_rank => $new_rank,
				      store_name => $self->{__STORE_CODES}->{$store}->{name},
				      store_name_jp => $self->{__STORE_CODES}->{$store}->{name_jp},
				     };
            sleep $self->{__WAIT};
	}
    }

    $ret;
}

sub app_base_info {
    my $self = shift;
    my @args = @_;

    my $args = $self->_validate_args(@args);

    my $rule = scraper {
	process '//h1[@class="doc-banner-title"]', 'app_name' => 'TEXT';
	process '//a[@class="doc-header-link"]', 'artist' => 'TEXT';
	process '//meta[@itemprop="price"]','price' => '@content';
	process '//div[@class="doc-overview-reviews"]//div[@data-csstoken="user-reviews"]//tr/td/span[2]', 'rate[]' => 'TEXT';
	process '//div[@class="doc-overview-reviews"]//div[@class="average-rating-value"]', 'average' => 'TEXT';
	process '//div[@class="doc-overview-reviews"]//div[@class="votes"]', 'votes' => 'TEXT';
	process '//div[@class="doc-user-reviews-list"]//div[@class="doc-review"]', 'reviews[]' => scraper {
	    process '//h4[@class="review-title"]', title => 'TEXT';
	    process '//span[@class="doc-review-date"]', date => 'TEXT';
	    process '//p[@class="review-text"]', message => 'TEXT';
	};
    };

    my $ret = {};
    for my $app ( @{$args->{apps}} ) {
        for my $store ( keys %{$args->{stores}} ) {
	    my $uri = $self->{__URL_PREF} . 'details?id=' . $app . '&hl=' . $store;
	    my $html = $self->_get_html($uri);
	    next unless $html;

#https://play.google.com/store/getreviews?id=jp.co.fenrir.android.sleipnir&reviewSortOrder=2&reviewType=1&version&pageNum=9

	    my $genre_id;
	    my $genre_name;
	    if ( $html =~ m|<a href="/store/apps/category/([^?]+)(?:[^"]+)?">([^<]+)</a>| ) {
		$genre_id = $1;
		$genre_name = $2;
	    }

	    my $scrape;
	    eval { $scrape = $rule->scrape( $html ); };
	    if ( $@ ) {
		warn 'cannot scrape app info: ', $uri;
		next;
	    }
	    if ( $scrape->{votes} ) {
		$scrape->{votes} =~ s/[^\d]//g;
	    }
	    if ( $scrape->{rate} ) {
		map { s/[^\d]//g } @{$scrape->{rate}};
	    }

	    #
	    # reviews
	    #

	    my $reviews;

	    $ret->{$app}->{$store} = {
				      'store_info' => $args->{stores}->{$store},
#				      'review_number' => $args->{review_number},
				      'genre_id' => $genre_id,
				      'artist_id' => $scrape->{artist},
				      'app_name' => $scrape->{app_name},
				      'genre_name' => $genre_name,
				      'price' => $scrape->{price},
				      'ratings' => {
						    summary => {
								average => $scrape->{average},
								votes => $scrape->{votes},
							       },
						    detail => [ reverse @{$scrape->{rate}} ],
						   },
				      'reviews' => $scrape->{reviews},
				     };
	}
    }

    $ret;
}

sub genre_rank {
    my $self = shift;
    my @args = @_;

    $self->_get_rank(@args);
}
sub total_rank {
    my $self = shift;
    my @args = @_;

    $self->_get_rank(@args);
}
sub new_rank {
    my $self = shift;
    my @args = @_;

    $self->_get_rank(@args);
}

sub _get_rank {
    my $self = shift;
    my @args = @_;

    my $args_ref = ref $args[0] eq 'HASH' ? $args[0] : {@args};
    my $caller =  (caller(1))[3];

    my $info;
    if ( $args_ref->{info} ) {
        $info = $args_ref->{info};
    }
    else {
        my $base_info = $self->app_base_info($args_ref);
        $info = $base_info->{ $args_ref->{app} }->{ $args_ref->{store} };
    }

    return unless $info->{genre_id};

    my $category = '';
    if ( $caller =~ /genre_rank$/ ) {
	$category = 'category/' .$info->{genre_id} . '/';
    }
    my $uri = $self->{__URL_PREF} . $category . 'collection/';
    $uri .= 'topselling';
    $uri .= '_new' if $caller =~ /new_rank$/;
    $uri .= $info->{price} ? '_paid' : '_free';

    my $rule = scraper {
	process '//ul[@class="snippet-list container-snippet-list"]/li', 'apps[]' => '@data-docid';
    };
    my $ret;
#    for my $i ( 0 .. int( $info->{review_number} / 24 ) + ( $info->{review_number} % 24 ? 0 : -1 ) ) {
    for my $i ( 0 .. int(200/24) ) {
	my $page = 'start=' . $i*24 . '&num=24';
	my $html = $self->_get_html( $uri . '?' . $page );
	next unless $html;
	my $scrape;
	eval { $scrape = $rule->scrape( $html ); };
	if ( $@ ) {
	    warn 'cannot scrape genre_rank info: ', $uri;
	    last;
	}
	next unless ( $scrape->{apps} and ref $scrape->{apps} eq 'ARRAY' );
	for my $j ( 0 .. scalar( @{ $scrape->{apps} } ) -1 ) {
	    if ( $scrape->{apps}->[$j] eq $args_ref->{app} ) {
		$ret = $i * 24 + $j + 1;
		last;
	    }
	}
	last if $ret;
    }

    $ret;
}

sub _validate_args {
    my $self = shift;
    my @args = @_;

    my $args_ref = ref $args[0] eq 'HASH' ? $args[0] : {@args};

    #
    # prepare array by target apps
    #

    die 'app code MUST be needed' unless $args_ref->{app};

    my @appcode = ref $args_ref->{app} eq 'ARRAY' ? @{$args_ref->{app}}
        : ($args_ref->{app});
    for (@appcode) {
        die 'app code is illegal: ',$_ unless m|^[-.\w]+$|;
    }
    my $apps_array = [@appcode];

    #
    # prepare array by target countries
    #

    my $stores_hash;
    if ( $args_ref->{store} ) {
        my @storename = ref $args_ref->{store} eq 'ARRAY' ? @{$args_ref->{store}}
            : ($args_ref->{store});
        for my $s ( @storename ) {
#            my $s = lc $_;
            if ( exists $self->{__STORE_CODES}->{ $s } ) {
                $stores_hash->{ $s } = $self->{__STORE_CODES}->{ $s };
            }
            else {
                die 'cannot found google play on "', $s, '"';
            }
        }
    }
    else {
        $stores_hash = $self->{__STORE_CODES};
    }

    #
    # prepare reviews max number
    #

#    my $review_number = ( exists $args_ref->{review_number} and $args_ref->{review_number} =~ /^\d+$/ ) ? $args_ref->{review_number} :24;

    return {
            apps => $apps_array,
            stores => $stores_hash,
#            review_number => $review_number,
           };
}

sub _get_html {
    my $self = shift;
    my $uri = shift;

    my $res = $self->{ua}->get( $uri );

    # Error Check
    unless ( $res->is_success ) {
        warn 'request failed: ', $uri, ': ', $res->status_line;
        return;
    }
    unless ( $res->headers->header('Content-Type') =~ m|/html| ) {
        warn 'content is not html: ', $uri, ': ', $res->headers->header('Content-Type');
        return;
    }

    $res->decoded_content;
}

sub _init_countries {
    my $c = {
	     cs => {
		    name => 'Čeština‬',
		    name_jp => 'チェコ語',
		   },
	     da => {
		    name => 'Dansk',
		    name_jp => 'デンマーク語',
		   },
	     de => {
		    name => 'Deutsch',
		    name_jp => 'ドイツ語',
		   },
	     en => {
		    name => 'English',
		    name_jp => '英語',
		   },
	     es => {
		    name => 'Español',
		    name_jp => 'スペイン語',
		   },
	     es_419 => {
			name => 'Español (Latinoamérica)',
			name_jp => 'スペイン語 ()',
		       },
	     fr => {
		    name => 'Français',
		    name_jp => 'フランス語',
		   },
	     it => {
		    name => 'Italiano',
		    name_jp => 'イタリア語',
		   },
	     nl => {
		    name => 'Nederlands',
		    name_jp => 'オランダ語',
		   },
	     no => {
		    name => 'Norsk',
		    name_jp => 'ノルウェー語',
		   },
	     pl => {
		    name => 'Polski',
		    name_jp => 'ポーランド語',
		   },
	     pt_BR => {
		       name => 'Português (Brasil)',
		       name_jp => 'ポルトガル語 (ブラジル)',
		      },
	     pt_PT => {
		       name => 'Português (Portugal)',
		       name_jp => 'ポルトガル語 (ポルトガル)',
		      },
	     fi => {
		    name => 'Suomi',
		    name_jp => 'フィンランド語',
		   },
	     sv => {
		    name => 'Svenska',
		    name_jp => 'スウェーデン語',
		   },
	     tr => {
		    name => 'Türkçe',
		    name_jp => 'トルコ語',
		   },
	     el => {
		    name => 'Ελληνικά‬',
		    name_jp => 'ギリシャ語',
		   },
	     ru => {
		    name => 'Русский',
		    name_jp => 'ロシア語',
		   },
	     ko => {
		    name => '한국어',
		    name_jp => '韓国語',
		   },
	     zh_CN => {
		       name => '中文（简体）',
		       name_jp => '中国語 (中国)',
		      },
	     ja => {
		    name => '日本',
		    name_jp => '日本語',
		   },
	     zh_TW => {
		       name => '繁體中文',
		       name_jp => '中国語 (台湾)',
		      },
	    };
}

1;
__END__

=head1 NAME

WWW::GooglePlay::Scraper - Get software rank/review/rate on Google Play.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

=head1 Methods

=head2 new

=over 4

blah blah

=over 4

=item wait

set interval (second). per app, per store.

=back

=back

=head2 app_info

=over 4

Get application information.

=over 4

=item app

set application identifier code.

ex.
  app => 'jp.co.fenrir.android.sleipnir',
  app => ['jp.co.fenrir.android.sleipnir', 'jp.co.fenrir.android.sleipnir_black'],
 ......

=item store

set lang_code. By default, get info from all languages.

ex.
  store => 'ja',
  store => ['ja','en'],
  ......

=back

=back

=head2 app_base_info

Get application information without ranking.

=head2 genre_rank

Get ranking (genre).

NOTE: args is same as app_info/app_base_info, but only one app/one store ('app' and 'store' is not array_ref).

NOTE: all store returns same value.

ex.
  $obj->genre_rank(
                   app => 'jp.co.fenrir.android.sleipnir',
                   store => 'ja'
                  );
  # $VAR1 = 25;

=head2 total_rank

Get ranking (total)

ex.
  $obj->total_rank(
                   app => 'com.skype.raider',
                   store => 'en'
                  );
  # $VAR1 = 2;

=head1 AUTHORS

KAWABATA, Kazumichi (Higemaru) E<lt>kawabata@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

=head1 SEE ALSO

Google Play: L<https://play.google.com/store>


=cut
