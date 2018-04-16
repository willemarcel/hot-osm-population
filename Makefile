rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

SCALA_SRC := $(call rwildcard, src/, *.scala)
SCALA_BLD := $(wildcard project/) build.sbt

target/scala-2.11/hot-osm-population-assembly.jar: ${SCALA_SRC} ${SCALA_BLD}
	./sbt assembly

aws/task/hot-osm-population-assembly.jar: target/scala-2.11/hot-osm-population-assembly.jar
	cp $< $@

docker: target/scala-2.11/hot-osm-population-assembly.jar
	docker build aws/task -t hot-osm-population

ecr-publish:
	docker tag hot-osm-population:latest 896538046175.dkr.ecr.us-east-1.amazonaws.com/hot-osm-population:latest
	docker push 896538046175.dkr.ecr.us-east-1.amazonaws.com/hot-osm-population:latest

predict:
	spark-submit --master "local[*]" --driver-memory 4G \
--class com.azavea.hotosmpopulation.PredictApp \
target/scala-2.11/hot-osm-population-assembly.jar \
--country BWA \
--worldpop file:/hot-osm/WorldPop/BWA15v4.tif \
--qatiles /hot-osm/mbtiles/botswana.mbtiles \
--model /hot-osm/models/avg-38/ \
--output /hot-osm/botswana-predict.json