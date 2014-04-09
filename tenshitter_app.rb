require 'nancy'
require 'nancy/render'
require './environment'
require './env'
require_relative 'models/user'


class TenshitterApp < Nancy::Base
  include Nancy::Render
  use Rack::Session::Cookie, secret: ENV['SECRET_TOKEN']
  use Rack::Static, :root => "public", :urls => ["/js", "/css", "/fonts", "/images"]

  get "/" do
    render "views/index.erb"
  end

  get "/users" do
    render "views/form.erb"
  end

  get "/timeline" do
    u = User.find(session["user_id"])
    followings = u.followings << u
    @tenshis = Tenshi.where(user_id: followings).order('created_at DESC').limit('20')
    render "views/timeline.erb"
  end

  post "/users" do
    user = User.create(name: params["name"], email: params["email"], password: params["password"], username: params["username"])
    begin
      User.find(user.id)
    rescue ActiveRecord::RecordNotFound
      session["error_form_message"] = "Missing or invalid data, please check the errors and try again"
      render "views/form.erb"
    else
      render "views/index.erb"
    end
  end

  post "/login" do
    if user = User.find_by(username: params["username"], password: params["password"])
      session["user_id"] = user.id
      response.redirect("/timeline")
    else
      session["error_index_message"] = "The username/password combination is wrong"
      render "views/index.erb"
    end

  end

  post "/timeline" do
    u= User.find(session["user_id"])
    if u.tenshee(params["tenshi"])
      response.redirect("/timeline")
    end
  end

end
