SELECT * FROM './yellow_tripdata_2024-01.parquet'
WHERE tpep_dropoff_datetime < tpep_pickup_datetime;

SELECT * FROM './yellow_tripdata_2024-01.parquet'
WHERE "tpep_pickup_datetime" < '2024-01-01' OR "tpep_dropoff_datetime" > '2024-01-31';

SELECT * FROM './yellow_tripdata_2024-01.parquet'
WHERE "Airport_fee" IS NULL;

SELECT * FROM  './yellow_tripdata_2024-01.parquet'  WHERE DATEDIFF('DAY', tpep_pickup_datetime, tpep_dropoff_datetime) > 1;

SELECT * FROM './yellow_tripdata_2024-01.parquet'  WHERE fare_amount < 0;

SELECT * FROM './yellow_tripdata_2024-01.parquet'  WHERE ABS(fare_amount) < 3;

