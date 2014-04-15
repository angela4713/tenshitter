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

  get "/users/new" do
    render "views/form.erb"
  end

  get "/tenshis" do
    u = User.find(session["user_id"])
    @username = u.username
    followings = u.followings << u
    @tenshis = Tenshi.where(user_id: followings, deleted_at: nil).order('created_at DESC').limit('30')
    session["last_tenshi_id"] = @tenshis.first.id if u.tenshis.count != 0
    render "views/tenshis.erb"
  end

  get "/username" do
    u = User.find(session["user_id"])
    @tenshis = Tenshi.where(user_id: u, deleted_at: nil).order('created_at DESC').limit('30')
    render "views/username.erb"
  end

  get "/tenshis/news" do
    render "views/tenshis_news.erb"
  end

  get "/username/edit" do
    @u = User.find(session["user_id"])
    render "views/edit.erb"
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
    if user = User.find_by(username: params["username"], password: params["password"], deleted_at: nil)
      session["user_id"] = user.id
      response.redirect("/tenshis")
    else
      session["error_index_message"] = "The username/password combination is wrong"
      render "views/index.erb"
    end

  end

  post "/tenshis" do
    u = User.find(session["user_id"])
    if u.tenshee(params["tenshi"])
      response.redirect("/tenshis")
    end
  end

  post "/tenshis/:tenshi_id/retenshee" do
    u = User.find(session["user_id"])
    u.retenshee(params["tenshi_id"])
  end

  post "/tenshis/:reply_id/reply" do
    u = User.find(session["user_id"])
    u.reply(params["message"], params["reply_id"])
  end

  delete "/tenshis/:id" do
    id = Tenshi.find(params["delete_id"])
    id.update(deleted_at: Date.today)
  end

  post "/username/signout" do
    session["user_id"] = nil
  end

  post "/tenshis/news" do
    u = User.find(session["user_id"])
    last_tenshi_id = session["last_tenshi_id"]
    followings = u.followings << u
    @tenshis_news = Tenshi.where(user_id: followings, deleted_at: nil).where("id > ?", last_tenshi_id).order('created_at DESC')
    response.headers["Content-Type"] = "text/html"
    render "views/tenshis_news.erb"
  end

  delete "/:username" do
    id = User.find(params["user_id"])
    id.update(deleted_at: Date.today)
  end

  post "/username/edit" do
    u = User.find(session["user_id"])
    u.update(name: params["name_edit"], email: params["email_edit"], password: params["password_edit"], username: params["username_edit"])
    response.redirect("/username")
  end
end