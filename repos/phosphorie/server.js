const http=require('http'); http.createServer((q,r)=>r.end(process.env.RESPONSE||'NO_RESPONSE')).listen(8080,'0.0.0.0');
