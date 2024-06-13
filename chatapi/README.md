# README


# 環境設定
### 1-ENV
> DB_USER=XXXXXXXXX <br>
> DB_PASS=XXXXXXXXX <br>
> API_ENV=development (or) production　<br>
### 2- コンテナー起動
> docker compose build　<br>
> docker compose up



# REDISへやりとり
> docker exec -it chatapi-redis bash\
> redis-cli -h 127.0.0.1 -p 6379 -a "$your_password"

# DB設定へやりとり
> docker exec chatapi-api rails db:create\
> docker exec chatapi-api rails db:migate

# CONTAINERへやりとり
> docker compose ps\
> docker exec -it [container-name] bash


# POSTGRESへ設定確認
> SHOW log_directory; <br>
> SELECT  pg_current_logfile();








# 参照リンク
https://zenn.dev/redheadchloe/articles/631a8fa58ed7b9 <br>
https://qiita.com/pokohide/items/7397b92a188da841b435 <br>
https://qiita.com/k5trismegistus/items/de1d4f1cb2a8a88e81c2 <br>
https://qiita.com/at-946/items/8630ddd411d1e6a651c6 <br>

# ActionCable
https://qiita.com/rhiroe/items/4c4e983e34a44c5ace27