tinymce.PluginManager.requireLangPack 'yeti'
tinymce.create 'tinymce.plugins.yeti',
  init: (ed, url) ->
    ed.addCommand 'yeti', -> yeti.show()
    ed.addButton 'yeti', 
      title : 'Yeti YouTube Search'
      cmd : 'yeti'
      image: window.yeti_icon
    ed.addShortcut 'alt+shift+y', ed.getLang('yeti'), 'yeti'
  getInfo: ->
    longname: 'WordPress Yeti YouTube Search'
    author: 'Adam Mesha'
    authorurl: 'http://www.mesha.org'
    infourl: 'https://github.com/sagittarian/yeti'
    version: "0.1"

tinymce.PluginManager.add 'yeti', tinymce.plugins.yeti

# jquery-el plugin
jqel = ($) ->
  tagletters = 'a-zA-Z0-9'
  attrletters = tagletters + '_-'
  el = $.el = (tag='', attrs={}) ->
    classes = []
    split = tag.match ///^
      ([#{tagletters}]*)
      (([#.][#{attrletters}]+)*)
    $///
    tag = if split[1] then split[1] else 'div'
    if split[2]?
      signs = split[2].match ///([#.][#{attrletters}]+)///g
      if signs?
        for attr in signs 
          sigil = attr.slice 0, 1
          rest = attr.slice 1
          if sigil is '#' then id = rest else classes.push rest
    $el = $ document.createElement tag
    for cls in classes
      $el.addClass cls
    $el.attr 'id', id if id?
    for attr, val of attrs
      if attr is 'text' or attr is 'html' or attr is 'val'
        $el[attr] val 
      else 
        $el.attr attr, val 
    return $el
  
  $.fn.el = (tag, attrs) -> el(tag, attrs).appendTo this
  $.fn.appendEl = (tag, attrs) -> this.append el tag, attrs
  return el

yeti = do ($=jQuery) ->
  el = jqel $  
  iframe_width = 560
  iframe_height = 315
  default_max_results = 10

  apiurl = 'https://gdata.youtube.com/feeds/api/videos'
  query = 
    key: 'AI39si7j4ZTYLG5G7FETVf--y8c8PcPG2qLUzIoKEvlsxYxs0p6vSPjQG4Av_VZVA1XmJ_AHGSwaAI5xJ67H9D1BB_X4FCE3rw'
    v: 2
    alt: 'jsonc'
    q: ''
    'max-results': default_max_results 
    'start-index': 1
  $yeti = el('#yeti').appendTo 'body'
  $searchwidget = el('#yeti-searchwidget').appendTo $yeti
  $searchlabel = el('label', for: 'yeti-searchbox', text: 'Search:')
    .appendTo $searchwidget
  $searchbox = el('input#yeti-searchbox', type: 'text')
    .appendTo $searchwidget
  $searchbtn = el('input#yeti-searchbtn', type: 'submit')
    .appendTo $searchwidget
  $results = $yeti.appendEl('hr').el('#yeti-results').hide()
  $total = el 'span'
  $start = el 'span'
  $stop = el 'span'
  $resultinfo = $results.el('#yeti-result-info')
    .append('Results ', $start, ' - ', $stop, ' of ', $total)
  $results.appendEl 'hr'
  $resultarea = el('#yeti-results').appendTo $results
  $nextbtn = el 'button#yeti-next', text: 'Next'
  $prevbtn = el 'button#yeti-prev', text: 'Prev'
  $controls = $results.el('.controls').append($prevbtn, $nextbtn)
  
  $yeti_player = el('#yeti-player').appendTo 'body'
  $yeti_iframe = $yeti_player.el 'iframe#yeti-iframe',
    width: iframe_width
    height: iframe_height
    frameborder: 0
    allowfullscreen: ''
  $yeti_player.el('button#yeti-back', text: 'Back').click ->
    $yeti_player.dialog 'close'
    $yeti.dialog 'open'
  $yeti_player.el('button#yeti-insert', text: 'Insert').click ->
    vid = $yeti_player.data 'vid'
    $yeti_player.dialog 'close'
    s = "[embed]http://www.youtube.com/watch?v=#{vid}[/embed]"
    tinyMCE.activeEditor.selection.setContent s

  youtube_item = (item) ->
    $item = el '.yeti-item'
    $a = el('a', href: item.player.default)
      .data('vid', item.id)
      .appendTo($item)
      .appendEl 'img', src: item.thumbnail.sqDefault
    minutes = Math.floor(item.duration / 60)
    seconds = item.duration % 60
    rating = Math.round(item.rating * 100) / 100 
    $item.append """
      <ul>
        <li class="title">#{item.title}</li>
        <li>#{item.description}</li>
        <li><span class="label">Uploaded:</span> #{item.uploaded}</li>
        <li><span class="label">Uploader:</span> #{item.uploader}</li>
        <li><span class="label">Duration:</span> #{minutes}:#{seconds}</li>
        <li><span class="label">Rating:</span> #{rating}</li>
      </ul>"""
    return $item
    
  show_player = (ev) ->
    vid = $(ev.currentTarget).data 'vid'
    $yeti_player.data 'vid', vid
    src = "http://www.youtube.com/embed/#{vid}?rel=0"
    $yeti.dialog 'close'
    $yeti_player.dialog 'open'
    $yeti_iframe.attr 'src', src
    return no
    
  set_search_results = (data) ->
    $results.show()
    $total.text data.data.totalItems
    $start.text data.data.startIndex
    $stop.text data.data.startIndex + data.data.itemsPerPage - 1
    $resultarea.empty()
    for item in data.data.items
      $resultarea.append (youtube_item item), el 'hr'
    $resultarea.find('a').click show_player
    
  fetch_query = -> $.getJSON apiurl, query, set_search_results

  submitsearch = ->
    query.q = $searchbox.val() 
    query['start-index'] = 1
    fetch_query()

  $searchbtn.click submitsearch
  $searchbox.keypress (ev) -> submitsearch() if ev.keyCode is 13
    
  $prevbtn.click ->
    if query['start-index'] - query['max-results'] > 0
      query['start-index'] -= query['max-results']
      fetch_query()
  
  $nextbtn.click ->
    if query['start-index'] + query['max-results'] <= parseInt $total.text()
      query['start-index'] += query['max-results']
      fetch_query()

  $window = $(window)
  wheight = $window.height()
  wwidth = $window.width()

  $yeti.dialog
    autoOpen: no
    modal: yes
    width: wwidth * 0.8
    height: wheight * 0.8
    dialogClass: 'wp-dialog'
    title: 'Yeti Youtube Search'
    
  $yeti_player.dialog
    autoOpen: no
    modal: yes
    width: iframe_width + 100
    height: iframe_height + 120
    dialogClass: 'wp-dialog'
    title: 'Yeti Youtube Search'
    close: (event, ui) -> 
      $yeti_iframe.removeAttr 'src'
      $yeti_player.data 'vid', null

  show: -> $yeti.dialog('open')
