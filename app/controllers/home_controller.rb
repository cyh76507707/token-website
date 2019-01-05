class HomeController < ApplicationController
  include ActionView::Helpers::NumberHelper
  require 'net/http'

  TEAM = [
    { name: "Sebastian Kim", role: "Founder, Developer", steemit: "tabris" },
    { name: "YoungWhi Cho", role: "Founder, Designer", steemit: "project7" }
  ]
  MODERATOR_ACCOUNTS = [
    'teamhumble', 'urbangladiator', 'dayleeo', 'fknmayhem', 'jayplayco', 'bitrocker2020', 'joannewong',
    'geekgirl', 'playitforward', 'monajam', 'pialejoana'
  ].map {|person| { name: person, role: "Moderator", steemit: person} }
  INFLUENCER_ACCOUNTS = [
    'vinzie1',
    'azwarrangkuti',
    'mawahab',
    'aamirijaz',
    'sanach',
    'calprut',
    'mrfringe',
    'acdevan',
    'karamyog',
    'rabeel',
    'hazelalex',
    'amar15',
    'abasifreke',
    'wiseeyes',
    'pavonj',
    'xabi',
    'krevasilis',
    'bbomber',
    'tornad',
    'iqbaladan'
  ].map {|person| { name: person, role: "Influencer", steemit: person} }

  THUMBNAIL_EXCLUSION = [
    'bramd', 'matildah'
  ]

  def index
    I18n.locale = I18n.available_locales.map(&:to_s).include?(params[:locale]) ? params[:locale] : 'en'

    @thumbnails = Rails.cache.fetch('thumbnails', expires_in: 30.minutes) do
      Post.select(:images).order(hunt_score: :desc).limit(200).map(&:thumbnail).reject { |t| t =~ /.*\.gif$/ }
    end
    @stats = Rails.cache.fetch('stats', expires_in: 1.minute) do
      {
        count: Post.all.count,
        value: Post.all.sum(:payout_value).round(2)
      }
    end
    @products_days = (Time.now.to_i - 1518784559) / 86400
    @team = TEAM
    @moderators = MODERATOR_ACCOUNTS
    @influencers = INFLUENCER_ACCOUNTS
    @total_funded = 0
    @delegators = JSON.parse(File.read('db/delegators.json')).map { |del|
      sp_worth = (del["sp"] * steem_price).round(2)
      @total_funded += sp_worth

      base = {
        name: del['delegator'],
        role: "delegated #{number_to_currency(sp_worth)}",
        steemit: del['delegator']
      }
      base[:no_thumbnail] = true if THUMBNAIL_EXCLUSION.include?(base[:steemit])

      base
    }
  end

  private
    def steem_price
      steem_usd = Rails.cache.fetch('steem_price', expires_in: 1.seconds) do
        res = Net::HTTP.get(URI("https://api.coinmarketcap.com/v2/ticker/1230/"))
        JSON.parse(res)["data"]["quotes"]["USD"]["price"]
      end
    end
end
