const express=require('express'); const app=express(); app.use(express.urlencoded({extended:true})); let paste='';
app.get('/',(q,r)=>r.send(`<h1>Pastebin</h1><form method=post><textarea name=text></textarea><button>Save</button></form><p id=paste>${paste}</p>`));
app.post('/',(q,r)=>{paste=q.body.text||'';r.redirect('/')}); app.listen(process.env.PORT||8080,'0.0.0.0');
