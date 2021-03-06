# Based on Rack::ShowExceptions
#
# Copyright (c) 2007, 2008, 2009, 2010 Christian Neukirchen <purl.org/net/chneukirchen>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'erb'
require 'ostruct'

module Cramp
  class ExceptionHandler

    attr_reader :env, :exception

    def initialize(env, exception)
      @env = env
      @exception = exception
      @template = ERB.new(TEMPLATE)
    end

    def dump_exception
      string = "#{exception.class}: #{exception.message}\n"
      string << exception.backtrace.map { |l| "\t#{l}" }.join("\n")
      string
    end

    def pretty
      req = Rack::Request.new(env)

      # This double assignment is to prevent an "unused variable" warning on
      # Ruby 1.9.3.  Yes, it is dumb, but I don't like Ruby yelling at me.
      path = path = (req.script_name + req.path_info).squeeze("/")

      # This double assignment is to prevent an "unused variable" warning on
      # Ruby 1.9.3.  Yes, it is dumb, but I don't like Ruby yelling at me.
      frames = frames = exception.backtrace.map { |line|
        frame = OpenStruct.new
        if line =~ /(.*?):(\d+)(:in `(.*)')?/
          frame.filename = $1
          frame.lineno = $2.to_i
          frame.function = $4

          begin
            lineno = frame.lineno-1
            lines = ::File.readlines(frame.filename)
            frame.pre_context_lineno = [lineno-CONTEXT, 0].max
            frame.pre_context = lines[frame.pre_context_lineno...lineno]
            frame.context_line = lines[lineno].chomp
            frame.post_context_lineno = [lineno+CONTEXT, lines.size].min
            frame.post_context = lines[lineno+1..frame.post_context_lineno]
          rescue
          end

          frame
        else
          nil
        end
      }.compact

      [@template.result(binding)]
    end

    def h(obj)                  # :nodoc:
      case obj
      when String
        Rack::Utils.escape_html(obj)
      else
        Rack::Utils.escape_html(obj.inspect)
      end
    end

# adapted from Django <djangoproject.com>
# Copyright (c) 2005, the Lawrence Journal-World
# Used under the modified BSD license:
# http://www.xfree86.org/3.3.6/COPYRIGHT2.html#5
TEMPLATE = <<'HTML'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <meta name="robots" content="NONE,NOARCHIVE" />
  <title><%=h exception.class %> at <%=h path %></title>
  <style type="text/css">
    html * { padding:0; margin:0; }
    body * { padding:10px 20px; }
    body * * { padding:0; }
    body { font:small sans-serif; }
    body>div { border-bottom:1px solid #ddd; }
    h1 { font-weight:normal; }
    h2 { margin-bottom:.8em; }
    h2 span { font-size:80%; color:#666; font-weight:normal; }
    h3 { margin:1em 0 .5em 0; }
    h4 { margin:0 0 .5em 0; font-weight: normal; }
    table {
        border:1px solid #ccc; border-collapse: collapse; background:white; }
    tbody td, tbody th { vertical-align:top; padding:2px 3px; }
    thead th {
        padding:1px 6px 1px 3px; background:#fefefe; text-align:left;
        font-weight:normal; font-size:11px; border:1px solid #ddd; }
    tbody th { text-align:right; color:#666; padding-right:.5em; }
    table.vars { margin:5px 0 2px 40px; }
    table.vars td, table.req td { font-family:monospace; }
    table td.code { width:100%;}
    table td.code div { overflow:hidden; }
    table.source th { color:#666; }
    table.source td {
        font-family:monospace; white-space:pre; border-bottom:1px solid #eee; }
    ul.traceback { list-style-type:none; }
    ul.traceback li.frame { margin-bottom:1em; }
    div.context { margin: 10px 0; }
    div.context ol {
        padding-left:30px; margin:0 10px; list-style-position: inside; }
    div.context ol li {
        font-family:monospace; white-space:pre; color:#666; cursor:pointer; }
    div.context ol.context-line li { color:black; background-color:#ccc; }
    div.context ol.context-line li span { float: right; }
    div.commands { margin-left: 40px; }
    div.commands a { color:black; text-decoration:none; }
    #summary { background: #ffc; }
    #summary h2 { font-weight: normal; color: #666; }
    #summary ul#quicklinks { list-style-type: none; margin-bottom: 2em; }
    #summary ul#quicklinks li { float: left; padding: 0 1em; }
    #summary ul#quicklinks>li+li { border-left: 1px #666 solid; }
    #explanation { background:#eee; }
    #template, #template-not-exist { background:#f6f6f6; }
    #template-not-exist ul { margin: 0 0 0 20px; }
    #traceback { background:#eee; }
    #requestinfo { background:#f6f6f6; padding-left:120px; }
    #summary table { border:none; background:transparent; }
    #requestinfo h2, #requestinfo h3 { position:relative; margin-left:-100px; }
    #requestinfo h3 { margin-bottom:-1em; }
    .error { background: #ffc; }
    .specific { color:#cc3300; font-weight:bold; }
  </style>
  <script type="text/javascript">
  //<!--
    function getElementsByClassName(oElm, strTagName, strClassName){
        // Written by Jonathan Snook, http://www.snook.ca/jon;
        // Add-ons by Robert Nyman, http://www.robertnyman.com
        var arrElements = (strTagName == "*" && document.all)? document.all :
        oElm.getElementsByTagName(strTagName);
        var arrReturnElements = new Array();
        strClassName = strClassName.replace(/\-/g, "\\-");
        var oRegExp = new RegExp("(^|\\s)" + strClassName + "(\\s|$$)");
        var oElement;
        for(var i=0; i<arrElements.length; i++){
            oElement = arrElements[i];
            if(oRegExp.test(oElement.className)){
                arrReturnElements.push(oElement);
            }
        }
        return (arrReturnElements)
    }
    function hideAll(elems) {
      for (var e = 0; e < elems.length; e++) {
        elems[e].style.display = 'none';
      }
    }
    window.onload = function() {
      hideAll(getElementsByClassName(document, 'table', 'vars'));
      hideAll(getElementsByClassName(document, 'ol', 'pre-context'));
      hideAll(getElementsByClassName(document, 'ol', 'post-context'));
    }
    function toggle() {
      for (var i = 0; i < arguments.length; i++) {
        var e = document.getElementById(arguments[i]);
        if (e) {
          e.style.display = e.style.display == 'none' ? 'block' : 'none';
        }
      }
      return false;
    }
    function varToggle(link, id) {
      toggle('v' + id);
      var s = link.getElementsByTagName('span')[0];
      var uarr = String.fromCharCode(0x25b6);
      var darr = String.fromCharCode(0x25bc);
      s.innerHTML = s.innerHTML == uarr ? darr : uarr;
      return false;
    }
    //-->
  </script>
</head>
<body>

<div id="summary">
  <h1><%=h exception.class %> at <%=h path %></h1>
  <h2><%=h exception.message %></h2>
  <table><tr>
    <th>Ruby</th>
    <td>
<% if first = frames.first %>
      <code><%=h first.filename %></code>: in <code><%=h first.function %></code>, line <%=h frames.first.lineno %>
<% else %>
      unknown location
<% end %>
    </td>
  </tr><tr>
    <th>Web</th>
    <td><code><%=h req.request_method %> <%=h(req.host + path)%></code></td>
  </tr></table>

  <h3>Jump to:</h3>
  <ul id="quicklinks">
    <li><a href="#get-info">GET</a></li>
    <li><a href="#post-info">POST</a></li>
    <li><a href="#cookie-info">Cookies</a></li>
    <li><a href="#env-info">ENV</a></li>
  </ul>
</div>

<div id="traceback">
  <h2>Traceback <span>(innermost first)</span></h2>
  <ul class="traceback">
<% frames.each { |frame| %>
      <li class="frame">
        <code><%=h frame.filename %></code>: in <code><%=h frame.function %></code>

          <% if frame.context_line %>
          <div class="context" id="c<%=h frame.object_id %>">
              <% if frame.pre_context %>
              <ol start="<%=h frame.pre_context_lineno+1 %>" class="pre-context" id="pre<%=h frame.object_id %>">
                <% frame.pre_context.each { |line| %>
                <li onclick="toggle('pre<%=h frame.object_id %>', 'post<%=h frame.object_id %>')"><%=h line %></li>
                <% } %>
              </ol>
              <% end %>

            <ol start="<%=h frame.lineno %>" class="context-line">
              <li onclick="toggle('pre<%=h frame.object_id %>', 'post<%=h frame.object_id %>')"><%=h frame.context_line %><span>...</span></li></ol>

              <% if frame.post_context %>
              <ol start='<%=h frame.lineno+1 %>' class="post-context" id="post<%=h frame.object_id %>">
                <% frame.post_context.each { |line| %>
                <li onclick="toggle('pre<%=h frame.object_id %>', 'post<%=h frame.object_id %>')"><%=h line %></li>
                <% } %>
              </ol>
              <% end %>
          </div>
          <% end %>
      </li>
<% } %>
  </ul>
</div>

<div id="requestinfo">
  <h2>Request information</h2>

  <h3 id="get-info">GET</h3>
  <% unless req.GET.empty? %>
    <table class="req">
      <thead>
        <tr>
          <th>Variable</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody>
          <% req.GET.sort_by { |k, v| k.to_s }.each { |key, val| %>
          <tr>
            <td><%=h key %></td>
            <td class="code"><div><%=h val.inspect %></div></td>
          </tr>
          <% } %>
      </tbody>
    </table>
  <% else %>
    <p>No GET data.</p>
  <% end %>

  <h3 id="post-info">POST</h3>
  <% unless req.POST.empty? %>
    <table class="req">
      <thead>
        <tr>
          <th>Variable</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody>
          <% req.POST.sort_by { |k, v| k.to_s }.each { |key, val| %>
          <tr>
            <td><%=h key %></td>
            <td class="code"><div><%=h val.inspect %></div></td>
          </tr>
          <% } %>
      </tbody>
    </table>
  <% else %>
    <p>No POST data.</p>
  <% end %>


  <h3 id="cookie-info">COOKIES</h3>
  <% unless req.cookies.empty? %>
    <table class="req">
      <thead>
        <tr>
          <th>Variable</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody>
        <% req.cookies.each { |key, val| %>
          <tr>
            <td><%=h key %></td>
            <td class="code"><div><%=h val.inspect %></div></td>
          </tr>
        <% } %>
      </tbody>
    </table>
  <% else %>
    <p>No cookie data.</p>
  <% end %>

  <h3 id="env-info">Rack ENV</h3>
    <table class="req">
      <thead>
        <tr>
          <th>Variable</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody>
          <% env.sort_by { |k, v| k.to_s }.each { |key, val| %>
          <tr>
            <td><%=h key %></td>
            <td class="code"><div><%=h val %></div></td>
          </tr>
          <% } %>
      </tbody>
    </table>

</div>

</body>
</html>
HTML


  end
end
