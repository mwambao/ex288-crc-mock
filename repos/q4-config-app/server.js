const http=require('http');http.createServer((q,r)=>{r.end(`${process.env.RESPONSE||'missing'}|${process.env.API_TOKEN?'secret-loaded':'secret-missing'}`)}).listen(8080,'0.0.0');
