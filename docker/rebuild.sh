docker build --no-cache -t oydeu/app-bank .
docker push oydeu/app-bank
docker stop kontoentwicklung
docker rm $(docker ps -q -f status=exited)
docker run --name kontoentwicklung -d --expose 3838 -e VIRTUAL_HOST=kontoentwicklung.datentresor.org -e VIRTUAL_PORT=3838 oydeu/app-bank
