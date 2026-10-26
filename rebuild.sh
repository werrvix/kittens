#!/bin/bash
set -e
cd ~/kittens
mkdir -p tasks
rm -f search.html login.html union.html hello.html guestbook.html filter.html

cat > index.html << 'PAGE'
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Kittens</title>
<style>
body{font-family:sans-serif;margin:0;background:#f0f2f5}
header{background:#1a1a2e;color:#fff;padding:18px 24px}
header h1{margin:0;font-size:24px}
nav{margin-top:8px;font-size:14px}
nav a{color:#8ec5ff;margin-right:14px;text-decoration:none}
.search{padding:20px 24px;background:#fff;border-bottom:1px solid #ddd}
.search input{padding:10px;width:260px;font-size:15px}
.search button{padding:10px 18px;font-size:15px;cursor:pointer}
.grid{display:flex;flex-wrap:wrap;gap:16px;padding:24px}
.card{background:#fff;border-radius:8px;box-shadow:0 1px 4px #0002;width:240px;overflow:hidden}
.card img{width:240px;height:240px;object-fit:cover;display:block}
.hint{color:#888;padding:0 24px 20px}
.msg{padding:24px;color:#888}
</style></head><body>
<header><h1>Kittens</h1>
<nav>More tasks:
 <a href="tasks/login.html">Login</a>
 <a href="tasks/union.html">Shop</a>
 <a href="tasks/hello.html?name=guest">Greeting</a>
 <a href="tasks/guestbook.html">Guestbook</a>
 <a href="tasks/filter.html?name=guest">Filter</a>
</nav></header>
<div class="search">
  <input id="q" placeholder="Search..." onkeydown="if(event.key==='Enter')doSearch()">
  <button onclick="doSearch()">Search</button>
</div>
<p class="hint">Hint: try typing a single quote ' in the search (or in the ?q= part of the address)</p>
<div id="grid" class="grid"><p class="msg">Loading...</p></div>
<script src="lib/sql-wasm.js"></script>
<script>
var MAX_MEMES=40, db=null;
initSqlJs({locateFile:function(f){return "lib/"+f;}}).then(function(SQL){
  db=new SQL.Database();
  db.run("CREATE TABLE memes(title TEXT,img TEXT,visible INT)");
  for(var i=1;i<=MAX_MEMES;i++) db.run("INSERT INTO memes VALUES(?,?,1)",["meme"+i,"memes/meme"+i+".jpg"]);
  db.run("INSERT INTO memes VALUES('flag','FLAG',0)");
  var q=new URLSearchParams(location.search).get("q");
  if(q){document.getElementById("q").value=q;runSQL(q);} else runSQL("");
}).catch(function(e){document.getElementById("grid").innerHTML="<p class='msg' style='color:red'>sql.js error: "+e+"</p>";});
function doSearch(){runSQL(document.getElementById("q").value);}
function runSQL(q){
  if(!db)return;
  var sql=q?"SELECT title,img FROM memes WHERE visible=1 AND title = '"+q+"'":"SELECT title,img FROM memes WHERE visible=1";
  var rows;
  try{var r=db.exec(sql);rows=r.length?r[0].values:[];}
  catch(e){document.getElementById("grid").innerHTML="<p class='msg' style='color:red'>SQL error: "+e+"<br><code>"+sql+"</code></p>";return;}
  for(var i=0;i<rows.length;i++) if(rows[i][1]==="FLAG"){showFlag();return;}
  var h="";for(var j=0;j<rows.length;j++) h+='<div class="card"><img src="'+rows[j][1]+'" onerror="this.parentNode.remove()"></div>';
  document.getElementById("grid").innerHTML=h||"<p class='msg'>Nothing found</p>";
}
function showFlag(){document.open();document.write('<!doctype html><meta charset="utf-8"><title>flag</title><div style="position:fixed;inset:0;background:#000;color:#0f0;display:flex;align-items:center;justify-content:center;font-family:monospace;font-size:34px">kpi{kitten_cracked_the_query}</div>');document.close();}
</script></body></html>
PAGE

cat > tasks/login.html << 'PAGE'
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Login</title>
<style>body{font-family:sans-serif;max-width:420px;margin:50px auto;padding:0 16px}
input{display:block;width:100%;padding:10px;margin:8px 0;box-sizing:border-box}
button{padding:10px 20px}a{color:#2563eb}.msg{margin-top:14px}code{background:#eee;padding:1px 4px}</style>
</head><body>
<p><a href="../index.html">&larr; home</a></p>
<h2>Admin login</h2>
<input id="u" placeholder="Username"><input id="p" type="text" placeholder="Password">
<button onclick="go()">Log in</button><div id="msg" class="msg"></div>
<p style="color:#888;margin-top:30px">Hint: the password is secret, but the query is not safe. Try a single quote ' in the username.</p>
<script src="../lib/sql-wasm.js"></script>
<script>
var db=null;
initSqlJs({locateFile:function(f){return "../lib/"+f;}}).then(function(SQL){
  db=new SQL.Database();
  db.run("CREATE TABLE users(user TEXT,pass TEXT)");
  db.run("INSERT INTO users VALUES('admin','S3cr3t_p@ss_9142')");
});
function go(){
  if(!db)return;
  var u=document.getElementById("u").value, p=document.getElementById("p").value;
  var sql="SELECT user FROM users WHERE user='"+u+"' AND pass='"+p+"'";
  var out=document.getElementById("msg");
  try{var r=db.exec(sql); var rows=r.length?r[0].values:[];
    if(rows.length) out.innerHTML="<b style='color:green'>Logged in as "+rows[0][0]+"</b><br>FLAG: <code>kpi{meowed_past_the_guard}</code>";
    else out.innerHTML="<span style='color:red'>Wrong username or password</span>";
  }catch(e){out.innerHTML="<span style='color:red'>SQL error: "+e+"</span><br><code>"+sql+"</code>";}
}
</script></body></html>
PAGE

cat > tasks/union.html << 'PAGE'
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Shop</title>
<style>body{font-family:sans-serif;max-width:600px;margin:40px auto;padding:0 16px}
input{padding:10px;width:60%}button{padding:10px 18px}
table{border-collapse:collapse;margin-top:16px;width:100%}
td,th{border:1px solid #ccc;padding:8px;text-align:left}a{color:#2563eb}code{background:#eee;padding:1px 4px}</style>
</head><body>
<p><a href="../index.html">&larr; home</a></p>
<h2>Cat shop — product search</h2>
<input id="q" placeholder="Product name..." onkeydown="if(event.key==='Enter')go()"><button onclick="go()">Search</button>
<div id="out"></div>
<p style="color:#888;margin-top:30px">Hint: this query returns <b>2 columns</b> (name, price). There is another table <code>secret</code> with a column <code>flag</code>. Use <code>UNION SELECT</code>.</p>
<script src="../lib/sql-wasm.js"></script>
<script>
var db=null;
initSqlJs({locateFile:function(f){return "../lib/"+f;}}).then(function(SQL){
  db=new SQL.Database();
  db.run("CREATE TABLE products(name TEXT,price TEXT)");
  db.run("INSERT INTO products VALUES('Cat food','10 UAH')");
  db.run("INSERT INTO products VALUES('Scratching post','250 UAH')");
  db.run("INSERT INTO products VALUES('Toy mouse','35 UAH')");
  db.run("CREATE TABLE secret(flag TEXT)");
  db.run("INSERT INTO secret VALUES('kpi{paws_on_the_secret_table}')");
});
function go(){
  if(!db)return;
  var q=document.getElementById("q").value;
  var sql="SELECT name,price FROM products WHERE name = '"+q+"'";
  var out=document.getElementById("out");
  try{var r=db.exec(sql); var rows=r.length?r[0].values:[];
    var h="<table><tr><th>Name</th><th>Price</th></tr>";
    for(var i=0;i<rows.length;i++) h+="<tr><td>"+rows[i][0]+"</td><td>"+rows[i][1]+"</td></tr>";
    h+="</table>"; out.innerHTML=rows.length?h:"<p>Nothing found</p>";
  }catch(e){out.innerHTML="<p style='color:red'>SQL error: "+e+"</p><code>"+sql+"</code>";}
}
</script></body></html>
PAGE

cat > tasks/hello.html << 'PAGE'
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Greeting</title>
<style>body{font-family:sans-serif;max-width:600px;margin:50px auto;padding:0 16px}
input{padding:8px;width:220px}a{color:#2563eb}code{background:#eee;padding:1px 4px}</style>
</head><body>
<p><a href="../index.html">&larr; home</a></p>
<h2>Greeting</h2>
<form method="GET"><input name="name" placeholder="Your name"><button>Go</button></form>
<div id="out"></div>
<script>
var flag="kpi{a_wild_meow_appeared}";
var name=new URLSearchParams(location.search).get("name");
if(name) document.write("<h3>Hello, "+name+"!</h3>");
</script>
<p style="color:#888;margin-top:30px">Hint: your name is written to the page as-is. Put a script in the <code>?name=</code> part of the address. There is a variable <code>flag</code> on this page.</p>
</body></html>
PAGE

cat > tasks/guestbook.html << 'PAGE'
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Guestbook</title>
<style>body{font-family:sans-serif;max-width:600px;margin:40px auto;padding:0 16px}
input{padding:8px;width:60%}button{padding:8px 16px}a{color:#2563eb}
.c{background:#f3f3f3;border-radius:8px;padding:10px 12px;margin:8px 0}code{background:#eee;padding:1px 4px}</style>
</head><body>
<p><a href="../index.html">&larr; home</a></p>
<h2>Guestbook</h2>
<input id="t" placeholder="Leave a comment..."><button onclick="add()">Post</button>
<button onclick="clearAll()" style="background:#eee">Clear</button>
<div id="list"></div>
<p style="color:#888;margin-top:30px">Hint: comments are saved and shown without any cleaning. A comment with an image error handler runs every time the page loads. There is a variable <code>flag</code> on this page.</p>
<script>
var flag="kpi{nine_lives_in_your_tab}";
function getC(){try{return JSON.parse(localStorage.getItem("gb")||"[]");}catch(e){return [];}}
function render(){var c=getC(), h="";for(var i=0;i<c.length;i++) h+='<div class="c">'+c[i]+'</div>';document.getElementById("list").innerHTML=h;}
function add(){var v=document.getElementById("t").value; if(!v)return;var c=getC(); c.push(v); localStorage.setItem("gb",JSON.stringify(c));document.getElementById("t").value=""; render();}
function clearAll(){localStorage.removeItem("gb");render();}
render();
</script></body></html>
PAGE

cat > tasks/filter.html << 'PAGE'
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Filtered greeting</title>
<style>body{font-family:sans-serif;max-width:600px;margin:50px auto;padding:0 16px}
input{padding:8px;width:220px}a{color:#2563eb}code{background:#eee;padding:1px 4px}</style>
</head><body>
<p><a href="../index.html">&larr; home</a></p>
<h2>Greeting (protected)</h2>
<form method="GET"><input name="name" placeholder="Your name"><button>Go</button></form>
<div id="out"></div>
<script>
var flag="kpi{too_quick_for_the_filter}";
var name=new URLSearchParams(location.search).get("name");
if(name){var clean=name.replace(/script/gi,"");document.write("<h3>Hello, "+clean+"!</h3>");}
</script>
<p style="color:#888;margin-top:30px">Hint: the word <code>script</code> is removed from your input. A plain &lt;script&gt; will not work. Use another tag with an event handler, or hide the word inside itself.</p>
</body></html>
PAGE

git add -A
git commit -q -m "tidy repo, remove emoji, tasks into folder"
git push -q origin main
echo "done"
