@rem test_curl_open_close.bat

@echo off

echo open (testareaQuick) with curl, closing it after 20 seconds ...

curl http://localhost:65005/scs?open=(testareaQuick)  

timeout /T 20

curl http://localhost:65005/scs?close=(testareaQuick)  

