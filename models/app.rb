module Wecheat::Models

  class App < Hashie::Dash
    include Hashie::Extensions::IgnoreUndeclared
    include Concerns::Persistable
    extend Concerns::Findable

    property :id, required: true
    property :secret, required: true
    property :access_token, required: true
    property :label
    property :token, default: ''
    property :url,  default: ''
    property :users, default: []
    property :medias, default: []
    property :articles, default: []
    property :button

    def self.find_by_access_token token
      self.all.select{|app| app.access_token == token }.first
    end

    def initialize(attributes = {}, &block)
      attributes[:id] ||= Wecheat::Utils.rand_appid
      attributes[:secret] ||= Wecheat::Utils::rand_secret
      attributes[:access_token] ||= Wecheat::Utils.rand_token
      attributes[:button] ||= Wecheat::Models::Button.new
      super(attributes, &block)
    end

    def filename
      self.id
    end

    def base_url append_params = {}
      signed_params = Wecheat::Utils.sign_params({
        timestamp: Time.now.to_i,
        nonce: Wecheat::Utils.rand_secret
      }.merge(append_params), self.token)
      segments = [self.url, URI.encode_www_form(signed_params)]
      (self.url.to_s.include?('?') ? segments.join("&") : segments.join("?")).gsub(/(\?\&)|(\&\?)/,'?')
    end

    def url?
      self[:url].to_s.empty? == false
    end

    def label
      self[:label] || self.id
    end

    def user id
      find_resource :users, :openid, id
    end

    def media id
      find_resource :medias, :id, id
    end

    def medias_by_type type
      self.medias.select{|m| m.type.to_s == type.to_s }
    end

    def article id
      find_resource :articles, :id, id
    end

    private
    def find_resource name, key, value
      self[name].select{|o| o[key].to_s == value.to_s }.first
    end
  end
  
end