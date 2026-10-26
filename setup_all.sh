#!/bin/bash
set -e
cd ~/kittens

cat > index.html << 'PAGE'
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Kittens — Web Security Lab</title>
<style>
body{font-family:sans-serif;margin:0;background:#f0f2f5;color:#222}
header{background:#1a1a2e;color:#fff;padding:22px 24px}
header h1{margin:0;font-size:26px}
header p{margin:6px 0 0;color:#aab}
.wrap{max-width:760px;margin:24px auto;padding:0 16px}
.task{display:block;background:#fff;border-radius:10px;box-shadow:0 1px 4px #0002;padding:16px 18px;margin-bottom:14px;text-decoration:none;color:inherit}
.task:hover{box-shadow:0 2px 10px #0003}
.task h3{margin:0 0 4px;font-size:18px}
.task .tag{font-size:12px;font-weight:bold;padding:2px 8px;border-radius:10px;color:#fff}
.sql{background:#2563eb}.xss{background:#c0392b}
.task p{margin:8px 0 0;color:#666;font-size:14px}
</style></head><body>
<header><h1>🐱 Kittens — Web Security Lab</h1><p>6 tasks: SQL injection and XSS. Find the flags.</p></header>
<div class="wrap">
 <a class="task" href="search.html"><span class="tag sql">SQLi</span><h3>Task 1 — Search injection</h3><p>The meme search puts your input straight into a SQL query. Make it reveal a hidden row.</p></a>
 <a class="task" href="login.html"><span class="tag sql">SQLi</span><h3>Task 2 — Login bypass</h3><p>Log in as admin without knowing the password.</p></a>
 <a class="task" href="union.html"><span class="tag sql">SQLi</span><h3>Task 3 — UNION select</h3><p>The shop search shows 2 columns. Pull data from another table.</p></a>
 <a class="task" href="hello.html?name=guest"><span class="tag xss">XSS</span><h3>Task 4 — Reflected XSS</h3><p>The greeting page prints your name without protection.</p></a>
 <a class="task" href="guestbook.html"><span class="tag xss">XSS</span><h3>Task 5 — Stored XSS</h3><p>Leave a comment that runs for everyone who opens the page.</p></a>
 <a class="task" href="filter.html?name=guest"><span class="tag xss">XSS</span><h3>Task 6 — Filter bypass</h3><p>Same as Task 4, but the word "script" is removed. Get around it.</p></a>
</div></body></html>
PAGE

cat > search.html << 'PAGE'
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Task 1 — Search</title>
<style>
body{font-family:sans-serif;margin:0;background:#f0f2f5}
header{background:#1a1a2e;color:#fff;padding:18px 24px}
header h1{margin:0;font-size:22px}header a{color:#8ec5ff;font-size:14px;margin-left:10px}
.search{padding:20px 24px;background:#fff;border-bottom:1px solid #ddd}
.search input{padding:10px;width:260px;font-size:15px}
.search button{padding:10px 18px;font-size:15px;cursor:pointer}
.grid{display:flex;flex-wrap:wrap;gap:16px;padding:24px}
.card{background:#fff;border-radius:8px;box-shadow:0 1px 4px #0002;width:240px;overflow:hidden}
.card img{width:240px;height:240px;object-fit:cover;display:block}
.hint{color:#888;padding:0 24px 20px}.msg{padding:24px;color:#888}
</style></head><body>
<header><h1>🐱 Kittens <a href="index.html">menu</a></h1></header>
<div class="search"><input id="q" placeholder="Search..." onkeydown="if(event.key==='Enter')doSearch()"><button onclick="doSearch()">Search</button></div>
<p class="hint">Hint: try typing a single quote ' in the search.</p>
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
function showFlag(){document.open();document.write('<!doctype html><meta charset="utf-8"><title>flag</title><div style="position:fixed;inset:0;background:#000;color:#0f0;display:flex;align-items:center;justify-content:center;font-family:monospace;font-size:34px">kpi{sqli_in_search}</div>');document.close();}
</script></body></html>
PAGE

cat > login.html << 'PAGE'
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Task 2 — Login</title>
<style>body{font-family:sans-serif;max-width:420px;margin:50px auto;padding:0 16px}
input{display:block;width:100%;padding:10px;margin:8px 0;box-sizing:border-box}
button{padding:10px 20px}a{color:#2563eb}.msg{margin-top:14px}code{background:#eee;padding:1px 4px}</style>
</head><body>
<p><a href="index.html">&larr; menu</a></p>
<h2>🔐 Admin login</h2>
<input id="u" placeholder="Username"><input id="p" type="text" placeholder="Password">
<button onclick="go()">Log in</button><div id="msg" class="msg"></div>
<p style="color:#888;margin-top:30px">Hint: the password is secret, but the query is not safe. Try a single quote ' in the username.</p>
<script src="lib/sql-wasm.js"></script>
<script>
var db=null;
initSqlJs({locateFile:function(f){return "lib/"+f;}}).then(function(SQL){
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
    if(rows.length) out.innerHTML="<b style='color:green'>Logged in as "+rows[0][0]+"</b><br>FLAG: <code>kpi{login_bypass}</code>";
    else out.innerHTML="<span style='color:red'>Wrong username or password</span>";
  }catch(e){out.innerHTML="<span style='color:red'>SQL error: "+e+"</span><br><code>"+sql+"</code>";}
}
</script></body></html>
PAGE

cat > union.html << 'PAGE'
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Task 3 — Shop</title>
<style>body{font-family:sans-serif;max-width:600px;margin:40px auto;padding:0 16px}
input{padding:10px;width:60%}button{padding:10px 18px}
table{border-collapse:collapse;margin-top:16px;width:100%}
td,th{border:1px solid #ccc;padding:8px;text-align:left}a{color:#2563eb}code{background:#eee;padding:1px 4px}</style>
</head><body>
<p><a href="index.html">&larr; menu</a></p>
<h2>🛒 Cat shop — product search</h2>
<input id="q" placeholder="Product name..." onkeydown="if(event.key==='Enter')go()"><button onclick="go()">Search</button>
<div id="out"></div>
<p style="color:#888;margin-top:30px">Hint: this query returns <b>2 columns</b> (name, price). There is another table <code>secret</code> with a column <code>flag</code>. Use <code>UNION SELECT</code>.</p>
<script src="lib/sql-wasm.js"></script>
<script>
var db=null;
initSqlJs({locateFile:function(f){return "lib/"+f;}}).then(function(SQL){
  db=new SQL.Database();
  db.run("CREATE TABLE products(name TEXT,price TEXT)");
  db.run("INSERT INTO products VALUES('Cat food','10 UAH')");
  db.run("INSERT INTO products VALUES('Scratching post','250 UAH')");
  db.run("INSERT INTO products VALUES('Toy mouse','35 UAH')");
  db.run("CREATE TABLE secret(flag TEXT)");
  db.run("INSERT INTO secret VALUES('kpi{union_select}')");
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

cat > hello.html << 'PAGE'
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Task 4 — Greeting</title>
<style>body{font-family:sans-serif;max-width:600px;margin:50px auto;padding:0 16px}
input{padding:8px;width:220px}a{color:#2563eb}code{background:#eee;padding:1px 4px}</style>
</head><body>
<p><a href="index.html">&larr; menu</a></p>
<h2>Greeting</h2>
<form method="GET"><input name="name" placeholder="Your name"><button>Go</button></form>
<div id="out"></div>
<script>
var flag="kpi{reflected_xss}";
var name=new URLSearchParams(location.search).get("name");
if(name) document.write("<h3>Hello, "+name+"!</h3>");
</script>
<p style="color:#888;margin-top:30px">Hint: your name is written to the page as-is. Put a script in the <code>?name=</code> part of the address. There is a variable <code>flag</code> on this page.</p>
</body></html>
PAGE

cat > guestbook.html << 'PAGE'
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Task 5 — Guestbook</title>
<style>body{font-family:sans-serif;max-width:600px;margin:40px auto;padding:0 16px}
input{padding:8px;width:60%}button{padding:8px 16px}a{color:#2563eb}
.c{background:#f3f3f3;border-radius:8px;padding:10px 12px;margin:8px 0}code{background:#eee;padding:1px 4px}</style>
</head><body>
<p><a href="index.html">&larr; menu</a></p>
<h2>📖 Guestbook</h2>
<input id="t" placeholder="Leave a comment..."><button onclick="add()">Post</button>
<button onclick="clearAll()" style="background:#eee">Clear</button>
<div id="list"></div>
<p style="color:#888;margin-top:30px">Hint: comments are saved and shown without any cleaning. A comment with an image error handler runs every time the page loads. There is a variable <code>flag</code> on this page.</p>
<script>
var flag="kpi{stored_xss}";
function getC(){try{return JSON.parse(localStorage.getItem("gb")||"[]");}catch(e){return [];}}
function render(){var c=getC(), h="";for(var i=0;i<c.length;i++) h+='<div class="c">'+c[i]+'</div>';document.getElementById("list").innerHTML=h;}
function add(){var v=document.getElementById("t").value; if(!v)return;var c=getC(); c.push(v); localStorage.setItem("gb",JSON.stringify(c));document.getElementById("t").value=""; render();}
function clearAll(){localStorage.removeItem("gb");render();}
render();
</script></body></html>
PAGE

cat > filter.html << 'PAGE'
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Task 6 — Filtered greeting</title>
<style>body{font-family:sans-serif;max-width:600px;margin:50px auto;padding:0 16px}
input{padding:8px;width:220px}a{color:#2563eb}code{background:#eee;padding:1px 4px}</style>
</head><body>
<p><a href="index.html">&larr; menu</a></p>
<h2>Greeting (protected)</h2>
<form method="GET"><input name="name" placeholder="Your name"><button>Go</button></form>
<div id="out"></div>
<script>
var flag="kpi{filter_bypass}";
var name=new URLSearchParams(location.search).get("name");
if(name){var clean=name.replace(/script/gi,"");document.write("<h3>Hello, "+clean+"!</h3>");}
</script>
<p style="color:#888;margin-top:30px">Hint: the word <code>script</code> is removed from your input. A plain &lt;script&gt; will not work. Use another tag with an event handler, or hide the word inside itself.</p>
</body></html>
PAGE

echo "[*] сторінки:"; ls -1 *.html
git add .
git commit -q -m "6 tasks + menu"
git push -q origin main
echo "[*] готово. Онови сайт через 1-2 хв (Ctrl+F5)."
