#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

SCALA_VERSION=2.10

if [ -n "$1" ]; then
  QUERY_CLASS="$1"
  shift
else
  echo "Usage: ./bin/submit-query <query-class> [query-args]"
  echo "  - can use abbreviated class name (e.g. LinkedIn, largescale.GoogleImage)"
  exit 1
fi

export QUERY_JAR=target/scala-$SCALA_VERSION/queries-assembly-0.3.0-SNAPSHOT.jar
export SPOOKY_JAR=../spookystuff/shell/target/scala-$SCALA_VERSION/spookystuff-shell-assembly-assembly-0.3.0-SNAPSHOT.jar

if [[ -z QUERY_JAR ]]; then
  echo "You need to build queries before running this program" >&2
  exit 1
fi

if [[ ! $QUERY_CLASS == com.anchorbot.queries.* ]]; then
  QUERY_CLASS="com.anchorbot.queries.$QUERY_CLASS"
fi

AWS_ACCESS_KEY_ID={{AWS_ACCESS_KEY_ID}} \
AWS_SECRET_ACCESS_KEY={{AWS_SECRET_ACCESS_KEY}} \
$SPARK_HOME/bin/spark-submit \
  --master {{spark_master}} \
  --class $QUERY_CLASS \
  --driver-memory 8G \
  --executor-memory 10G \
  --conf spark.task.maxFailures=1000 \
  --conf spark.shuffle.consolidateFiles=true \
  \
  --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \
  --conf spark.kryo.registrator=org.tribbloid.spookystuff.SpookyRegistrator \
  --conf spark.kryoserializer.buffer.max.mb=512 \
  \
  --conf spooky.root=s3n://spooky- \
  --conf spooky.checkpoint=s3://spooky-checkpoint \
  --conf spooky.preview.mode=no \
  --conf spark.executorEnv.com.amazonaws.sdk.disableCertChecking=true \
  \
  --jars /home/ubuntu/git/spookystuff/shell/target/scala-2.10/spookystuff-shell-assembly-0.3.0-SNAPSHOT.jar,/home/ubuntu/git/spookystuff/lib/target/scala-2.10/spookystuff-lib-assembly-0.3.0-SNAPSHOT.jar \
  /home/ubuntu/git/Anchorbot-queries/target/scala-$SCALA_VERSION/queries-assembly-0.3.0-SNAPSHOT.jar \
  "$@"