jade=function(e){function t(e){return e!=null}return Array.isArray||(Array.isArray=function(e){return"[object Array]"==Object.prototype.toString.call(e)}),Object.keys||(Object.keys=function(e){var t=[];for(var n in e)e.hasOwnProperty(n)&&t.push(n);return t}),e.merge=function(n,r){var i=n["class"],s=r["class"];if(i||s)i=i||[],s=s||[],Array.isArray(i)||(i=[i]),Array.isArray(s)||(s=[s]),i=i.filter(t),s=s.filter(t),n["class"]=i.concat(s).join(" ");for(var o in r)o!="class"&&(n[o]=r[o]);return n},e.attrs=function(n,r){var i=[],s=n.terse;delete n.terse;var o=Object.keys(n),u=o.length;if(u){i.push("");for(var a=0;a<u;++a){var f=o[a],l=n[f];"boolean"==typeof l||null==l?l&&(s?i.push(f):i.push(f+'="'+f+'"')):0==f.indexOf("data")&&"string"!=typeof l?i.push(f+"='"+JSON.stringify(l)+"'"):"class"==f&&Array.isArray(l)?i.push(f+'="'+e.escape(l.join(" "))+'"'):r&&r[f]?i.push(f+'="'+e.escape(l)+'"'):i.push(f+'="'+l+'"')}}return i.join(" ")},e.escape=function(t){return String(t).replace(/&(?!(\w+|\#\d+);)/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;")},e.rethrow=function(t,n,r){if(!n)throw t;var i=3,s=require("fs").readFileSync(n,"utf8"),o=s.split("\n"),u=Math.max(r-i,0),a=Math.min(o.length,r+i),i=o.slice(u,a).map(function(e,t){var n=t+u+1;return(n==r?"  > ":"    ")+n+"| "+e}).join("\n");throw t.path=n,t.message=(n||"Jade")+":"+r+"\n"+i+"\n\n"+t.message,t},e}({}),jade.templates={},jade.render=function(e,t,n){var r=jade.templates[t](n);e.innerHTML=r},jade.templates.homepage=function(locals,attrs,escape,rethrow,merge){attrs=attrs||jade.attrs,escape=escape||jade.escape,rethrow=rethrow||jade.rethrow,merge=merge||jade.merge;var buf=[];with(locals||{}){var interp,forum_mixin=function(e,t){var n=this.block,r=this.attributes||{},i=this.escaped||{};buf.push("<img"),buf.push(attrs({id:"forum_bg_"+e.id+"",src:""+cache_url+"/images/bg_"+e.id+".jpg","class":"bg "+(t==0?"active":"")},{"class":!0,id:!0,src:!0})),buf.push("/><a"),buf.push(attrs({name:"forum_"+e.id+""},{name:!0})),buf.push("></a><div"),buf.push(attrs({id:"forum_"+e.id+"","class":"forum "+(t%2?"odd":"even")},{"class":!0,id:!0})),buf.push('><div class="header"><h4 class="title">');var s=e.title;buf.push(escape(null==s?"":s)),buf.push('</h4><span class="description">');var s=e.description;buf.push(escape(null==s?"":s)),buf.push('</span></div><div class="container">'),function(){if("number"==typeof e.posts.length)for(var t=0,n=e.posts.length;t<n;t++){var r=e.posts[t];post_mixin(r,t)}else for(var t in e.posts){var r=e.posts[t];post_mixin(r,t)}}.call(this),buf.push("</div></div>")},post_mixin=function(e,t){var n=this.block,r=this.attributes||{},i=this.escaped||{};buf.push("<div"),buf.push(attrs({id:"post_"+e.id+"","class":"post "+("col"+Math.ceil(Math.random()*2)+"")},{"class":!0,id:!0})),buf.push('><h5 class="title">');var s=e.title;buf.push(escape(null==s?"":s)),buf.push('<span class="date">'+escape((interp=e.date)==null?"":interp)+'</span></h5><p class="body">');var s=e.body;buf.push(escape(null==s?"":s)),buf.push("</p>"),function(){if("number"==typeof e.posts.length)for(var t=0,n=e.posts.length;t<n;t++){var r=e.posts[t];subpost_mixin(r,t)}else for(var t in e.posts){var r=e.posts[t];subpost_mixin(r,t)}}.call(this),buf.push('<div class="comment"><div class="photo"><img'),buf.push(attrs({src:""+cache_url+"/images/profile.jpg"},{src:!0})),buf.push('/></div><input type="text" placeholder="Say it ..." class="msg"/></div></div>')},subpost_mixin=function(e,t){var n=this.block,r=this.attributes||{},i=this.escaped||{};buf.push("<div"),buf.push(attrs({id:"subpost_"+e.id+"","class":"subpost "+(t%2?"odd":"even")},{"class":!0,id:!0})),buf.push('><div class="photo"><img'),buf.push(attrs({src:""+cache_url+"/images/profile.jpg"},{src:!0})),buf.push('/></div><p class="body">');var s=e.body;buf.push(escape(null==s?"":s)),buf.push('</p><div class="signature"><span class="username">- '+escape((interp=e.user.name)==null?"":interp)+'</span><span class="date">');var s=e.date;buf.push(escape(null==s?"":s)),buf.push("</span></div></div>")};(function(){if("number"==typeof forums.length)for(var e=0,t=forums.length;e<t;e++){var n=forums[e];forum_mixin(n,e)}else for(var e in forums){var n=forums[e];forum_mixin(n,e)}}).call(this)}return buf.join("")}