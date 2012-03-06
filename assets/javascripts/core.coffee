api_prefix = "https://api.weibo.com"

$ ->
  AccessToken = Backbone.Model.extend({
    defaults: -> 
      {created_at: new Date}
  })

  window.AccessTokenList = Backbone.Collection.extend({
    model: AccessToken,
    
    initialize: ->
      this.bind("add", this.activate, this)
    
    activate: ->
      this.pick(this.at(0).get("token"))
    
    pick: (val)-> # use a give in token
      this.trigger("token:activate", val)
  })
  
  window.Tokens = new AccessTokenList
  
  User = Backbone.Model.extend({})
  UserList = Backbone.Collection.extend({
    model: User
  })
  
  Users = new UserList
  
  Tweet = Backbone.Model.extend({})
  TweetList = Backbone.Collection.extend({
    model: Tweet,
    min_id: 0,
    max_id: 0,
    api: "#{api_prefix}/2/statuses/home_timeline.json"
    
    initialize: ->
      this.bind("add", this.updateUser, this)
      Tokens.bind("token:activate", this.updateToken, this)
    
    updateToken: (t)->
      @token = t
      this.update_latest()
    
    updateUser: (s)->
      json = s.toJSON()
      user1 = json["user"]
      if json["retweeted_status"] then user2 = json["retweeted_status"]["user"]
      this._updateUser(user1)
      if user2 then this._updateUser(user2)
    
    _updateUser: (json) ->
      u = Users.get(json["id"])
      if u
        u.set json # TODO: skip the id
      else
        Users.add(new User(json))
    
    update_latest: ->
      console.log("Updating from server...> #{@max_id} using token: #{@token}")
      $.getJSON @api, {access_token: @token, since_id: @max_id}, (data) =>
        this.add(data["statuses"].reverse())
        @min_id = this.at(0).id
        @max_id = this.at(this.length - 1).id
  
    fetch_local: ->
      $.getJSON "home_timeline.json", (data) =>
        this.add(data["statuses"].reverse())
  
  });

  window.Tweets = new TweetList
  
  Comment = Backbone.Model.extend({})
  CommentList = Backbone.Collection.extend({
    model: Comment,
    api: "#{api_prefix}/2/comments/show.json",
    fetch_local: ->
      $.getJSON "status_comments.json", (data) =>
        this.add(data["comments"].reverse())
  })
  
  window.Comments = new CommentList

  _last = null

  TweetView = Backbone.View.extend({
    tagName: 'li'
    className: 'bo_container'
    events: 
      "click .avatar": "show_user",
      "click .user_link": "show_user_link",      
      "click .reply": "reply",
      "click .retweet": "retweet",
      "click": "show_detail"
    template: doT.template($("#template").text())
    
    initialize: ->
      Tokens.bind("token:activate", this.updateToken, this)
    
    updateToken: (t)->
      @token = t
      $("#logo").hide()
    
    render: ->
      $(this.el).html(this.template(this.model.toJSON()))
      return this
    
    show_detail: -> 
      if _last != null 
        if _last == this then return
        $(_last.el).removeClass("selected")
      
      $(this.el).addClass("selected")
      _last = this
      Routes.navigate("tweets/#{this.model.id}", {trigger: true})
    
    show_user_link: (el)->
      location.href=$(el.target).attr("href")
      return false;
    
    reply: ->
      return false
      
    retweet: ->
      return false
      
    
    show_user: ->
      Routes.navigate("users/#{this.model.get("user").id}", {trigger: true})
      return false
  }) 
  
  TweetDetailView = Backbone.View.extend({
    el: $("#inner")
    side_width: "500px"
    template: doT.template($("#template_full").text())
    comment_template: doT.template($("#comments_template").text())
    
    render: ->
      _this = this
      $(this.el).scrollTop(0)
      $(this.el).css("width", parseInt(this.side_width) * 2 + "px");
      $(this.el).find(".anim_block").each ->
        $(this).css("width", _this.side_width);
        if $(this).css("left") != "0px"
          $(this).html(_this.template(_this.model.toJSON()))
          # comments = Comments.select (c) -> c.status.id == _this.model.id
          $(this).find(".recent_comments").html(_this.comment_template(Comments.toJSON()))
      
      this._animate()
          
    _animate: ->
      _this = this
      $(this.el).animate {"left": "+#{this.side_width}"}, "fast", -> 
        $(_this.el).find(".anim_block").each (el) ->
          old = $(this).css("left")
          if old == "0px" then new_width = "-#{_this.side_width}" else new_width = "0px"
          $(this).css("left", new_width)
          $(_this.el).css("left", "0px")
  })
  
  UserDetailView = TweetDetailView.extend({
    template: doT.template($("#user_detail_template").text())
  })
  
  TweetsView = Backbone.View.extend({
    el: $("#tweets_list")
    initialize: -> 
      Tweets.bind('add', this.addOne, this)
      Tokens.bind("token:activate", this.updateUI, this)
      
    updateUI: ->
      $(".nav_buttons").show("slow")
      $("#logo").hide("fast");
      
    addOne: (s)->
      view = new TweetView({model: s, id:"status-#{s.id}", attributes: {"data-id" : s.id}})
      $("#tweets_list").prepend(view.render().el); #TODO: only scroll when nessary
    showTweet: (id) ->
      view = new TweetDetailView({model: Tweets.get(parseInt(id))})
      view.render()
      
    showUser: (id) ->
      new UserDetailView({model: Users.get(parseInt(id))}).render()
  })

  ListView = new TweetsView
  
  NewStatusView = Backbone.View.extend({
    el: $("#new_status")
    events: {
      "click .cancel" : "cancel",
      "click .submit" : "submit"
    }
    
    initialize: ->
      Tokens.bind("token:activate", this.updateToken, this)
    
    updateToken: (t)->
      @token = t
    
    render: ->
      $(this.el).animate({"top": "80px"}, "fast")
      $(this.el).find("textarea").focus()
      $("#overlay").css("z-index", "150");
    
    cancel: ->
      $(this.el).animate {"top": "-100px"}, "fast"
      $("#overlay").css("z-index", "-1");
      
    submit: ->
      api = "https://api.weibo.com/2/statuses/update.json"
      $.post api, {access_token: @token, status: $("#new_status_content").val()}, ->
        $("#new_status_content").val("")
      
      $(this.el).animate {"top": "-100px"}, "fast"
      $("#overlay").css("z-index", "-1");
  })
  
  window.NewStatus = new NewStatusView

  # Router
  Workspace = Backbone.Router.extend({
    routes: 
      "tweets/:id":     "show_tweet",  
      "users/:id":      "show_user" 
  
    show_tweet: (id)->
      if Tweets.length > 0
        ListView.showTweet(id)
  
    show_user: (id) ->
      if Users.length > 0
        ListView.showUser(id)
  })

  Routes = new Workspace
  Backbone.history.start()
