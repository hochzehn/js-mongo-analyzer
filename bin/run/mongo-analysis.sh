#!/usr/bin/env bash

# Parameters

MONGO_CONTAINER_NAME="$1"
if [ -z "$MONGO_CONTAINER_NAME" ]; then
  echo "[Error] Mongo docker container name has to be provided. Exiting."
  exit 1
fi
MONGO_SOURCE_COLLECTION_NAME="$2"
if [ -z "$MONGO_SOURCE_COLLECTION_NAME" ]; then
  echo "[Error] Mongo source collection name has to be provided. Exiting."
  exit 2
fi
MONGO_DB_NAME="$3"
if [ -z "$MONGO_DB_NAME" ]; then
  MONGO_DB_NAME="local"
fi

MONGO_RESULT_COLLECTION_NAME="results"

echo ""
echo "- Count total results"
echo ""

COUNT=$(docker run -ti --rm \
  --link ${MONGO_CONTAINER_NAME}:mongodb \
  mongo \
  sh -c 'exec mongo '"$MONGO_DB_NAME"' \
    --host "mongodb" \
    --port "27017" \
    --quiet \
    --eval "db.getCollection(\"'"$MONGO_SOURCE_COLLECTION_NAME"'\").count()" \
    ')
echo "$COUNT"
echo "$COUNT" > ${PWD}/results/sample_size.json

echo ""
echo "- JavaScript libraries by usages"
echo ""

docker run -ti --rm \
  --link ${MONGO_CONTAINER_NAME}:mongodb \
  mongo \
  sh -c 'exec mongo '"$MONGO_DB_NAME"' \
    --host "mongodb" \
    --port "27017" \
    --eval "db.getCollection(\"'"$MONGO_SOURCE_COLLECTION_NAME"'\").aggregate([ \
    { \"\$project\": { \"_id\": 0, \"javascript.libraries\": 1 }}, \
    { \"\$unwind\": \"\$javascript.libraries\" }, \
    { \"\$project\": { \"_id\": { \"\$concat\": [\"\$javascript.libraries.name\"] }, \"javascript.libraries\": 1 } }, \
    { \"\$group\": { \"_id\": \"\$_id\", \"usages\": { \"\$sum\": 1 }, \"name\": { \"\$first\": \"\$javascript.libraries.name\" } }}, \
    { \"\$project\": { \"_id\": 0, \"name\": 1, \"usages\": 1 } }, \
    { \"\$sort\": { \"usages\": -1 } }, \
    { \"\$out\": \"'"$MONGO_RESULT_COLLECTION_NAME"'\" } \
])" \
    '

docker run -ti --rm \
  --link ${MONGO_CONTAINER_NAME}:mongodb \
  --volume ${PWD}/results/:/opt/results \
  mongo \
  sh -c 'exec mongoexport \
    --db '"$MONGO_DB_NAME"' \
    --host "mongodb:27017" \
    --collection "'"$MONGO_RESULT_COLLECTION_NAME"'" \
    --out "/opt/results/js.library.json" \
    '

echo ""
echo "- JavaScript library versions by usages"
echo ""

docker run -ti --rm \
  --link ${MONGO_CONTAINER_NAME}:mongodb \
  mongo \
  sh -c 'exec mongo '"$MONGO_DB_NAME"' \
    --host "mongodb" \
    --port "27017" \
    --eval "db.getCollection(\"'"$MONGO_SOURCE_COLLECTION_NAME"'\").aggregate([ \
    { \"\$project\": { \"_id\": 0, \"javascript.libraries\": 1 }}, \
    { \"\$unwind\": \"\$javascript.libraries\" }, \
    { \"\$project\": { \"_id\": { \"\$concat\": [\"\$javascript.libraries.name\", \"---\", \"\$javascript.libraries.version\"] }, \"javascript.libraries\": 1 } }, \
    { \"\$group\": { \"_id\": \"\$_id\", \"usages\": { \"\$sum\": 1 }, \"name\": { \"\$first\": \"\$javascript.libraries.name\" }, \"version\": { \"\$first\": \"\$javascript.libraries.version\" } }}, \
    { \"\$project\": { \"_id\": 0, \"name\": 1, \"version\": 1, \"usages\": 1 } }, \
    { \"\$sort\": { \"name\": 1, \"version\": -1 } }, \
    { \"\$out\": \"'"$MONGO_RESULT_COLLECTION_NAME"'\" } \
])" \
    '

docker run -ti --rm \
  --link ${MONGO_CONTAINER_NAME}:mongodb \
  --volume ${PWD}/results/:/opt/results \
  mongo \
  sh -c 'exec mongoexport \
    --db '"$MONGO_DB_NAME"' \
    --host "mongodb:27017" \
    --collection "'"$MONGO_RESULT_COLLECTION_NAME"'" \
    --out "/opt/results/js.library.version.json" \
    '
