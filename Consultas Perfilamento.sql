-- verificando casos que o desembarque consta como antes do embarque
SELECT * FROM './yellow_tripdata_2024-01.parquet'
WHERE tpep_dropoff_datetime < tpep_pickup_datetime;

-- verificando casos que a viagem está fora do mês de janeiro de 2024
SELECT * FROM './yellow_tripdata_2024-01.parquet'
WHERE "tpep_pickup_datetime" < '2024-01-01' OR "tpep_dropoff_datetime" > '2024-01-31';

-- verificando casos que a viagem durou mais de 1 dia
SELECT * FROM  './yellow_tripdata_2024-01.parquet'  WHERE DATEDIFF('DAY', tpep_pickup_datetime, tpep_dropoff_datetime) > 1;

-- verificando casos que o valor da tarifa consta como negativa
SELECT * FROM './yellow_tripdata_2024-01.parquet'  WHERE fare_amount < 0;

-- verificando casos que a tarifa foi muito baixa (menor que 3)
SELECT * FROM './yellow_tripdata_2024-01.parquet'  WHERE ABS(fare_amount) < 3;

-- comando nativo do DuckDB que resume as estatísticas de uma tabela
SUMMARIZE './yellow_tripdata_2024-01.parquet';
-- percebe-se que existem 5 colunas com valores nulos, e são correspondentes a 4.73% das linhas.

-- verificando se todos os valores nulos estão nos mesmos casos
SELECT COUNT(*) AS total_nulos_simultaneos
FROM './yellow_tripdata_2024-01.parquet'
WHERE passenger_count IS NULL
    AND RatecodeID IS NULL
    AND store_and_fwd_flag IS NULL
    AND congestion_surcharge IS NULL
    AND Airport_fee IS NULL;

--verificando se esses casos nulos têm algo em comum
SELECT *
FROM './yellow_tripdata_2024-01.parquet'
WHERE passenger_count IS NULL
    AND RatecodeID IS NULL
    AND store_and_fwd_flag IS NULL
    AND congestion_surcharge IS NULL
    AND Airport_fee IS NULL
LIMIT 10;

--foi verificado que todos têm o payment_type = 0, que remete ao 'Flex Fare Trip'

-- confirmando se todas as corridas com Flex Fare têm essas colunas como nulo
SELECT COUNT(*) AS pagamento_flex_nulo
  FROM './yellow_tripdata_2024-01.parquet'
  WHERE payment_type = 0
      AND passenger_count IS NULL
      AND RatecodeID IS NULL
      AND store_and_fwd_flag IS NULL
      AND congestion_surcharge IS NULL
      AND Airport_fee IS NULL;

--conclui-se que todas as corridas Flex Fare deixam de armazenar esses valores