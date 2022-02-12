# PanScan


## build & push

```
 docker build -t adam429/pan-repo:panscan .
 docker push adam429/pan-repo:panscan
```

## run

`docker container run -d -p 80:80  --env-file ~/.env --name panscan adam429/pan-repo:panscan`

## push

`docker push adam429/pan-repo:panscan`
