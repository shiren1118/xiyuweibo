repeat = (ms, func) -> setInterval func, ms

String::autoAt = ->
  pattern = /(@([^ :]+))/ig
  this.replace(pattern, "<a href='http://www.weibo.com/n/$2'>$1</a>")

Date::human = ->
  this.format("m月d日 hh:mm")

side_width = "500px"; 

doT.templateSettings = {
  evaluate:    /\[\[([\s\S]+?)\]\]/g,
  interpolate: /\[\[=([\s\S]+?)\]\]/g,
  encode:      /\[\[!([\s\S]+?)\]\]/g,
  use:         /\[\[#([\s\S]+?)\]\]/g,
  define:      /\]\]##\s*([\w\.$]+)\s*(\:|=)([\s\S]+?)#\]\]/g,
  varname:     'it',
  strip :      true,
  append:      true
};

check = (w) ->
  url = w.url()
  pattern = /#access_token=([^&]+)/
  if !pattern.test(w.url())
    _.delay(2000, -> check(w))
  else
    w.close()
    token = w.url().match(pattern)[1]
    statuses.init(token)

$ ->
  
  _last = null
  
  $(".main, .side").attr("style", "height: " + (window.innerHeight - 36) + "px")
  
  $(document).on "click", ".single_bo .content a", ->
    macgap.app.open($(this).attr("href"))
    return false
  
  $(window).resize ->
    $(".main, .side").attr("style", "height: " + (window.innerHeight - 36) + "px")
  
  $("#btn_fetch").click ->
    Tweets.fetch_local()
    # statuses.update_latest()
  
  # $("#btn_login").click ->
  #     l = macgap.window.open({url: "public/auth_sina.html", width: 640, height: 480})
  #     check(l);
  #     
    
