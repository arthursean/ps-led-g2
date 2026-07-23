CREATE OR REPLACE TABLE taxi_zone AS
SELECT * FROM read_csv('taxi_zone_lookup.csv');

SELECT * FROM taxi_zone;

CREATE OR REPLACE TABLE yellow_data_n_tratado AS 
SELECT * FROM read_parquet('yellow_tripdata_2024-01.parquet');

CREATE OR REPLACE VIEW tratamento_inicial  AS
SELECT
    VendorId as id_empresa,
    trip_distance as distancia_corrida,
    PULocationID as local_entrada,
    DOLocationID as local_saida,
    payment_type as tipo_pagamento,
    CASE WHEN payment_type != 4 AND fare_amount < 0 THEN fare_amount * -1 ELSE fare_amount END AS custo_tarifa,
    CASE WHEN payment_type != 4 AND extra < 0 THEN extra * -1 ELSE extra END AS custo_adicional,
    CASE WHEN payment_type != 4 AND mta_tax < 0 THEN mta_tax * -1 ELSE mta_tax END AS taxa_fixa_mta,
    CASE WHEN payment_type != 4 AND tip_amount < 0 THEN tip_amount * -1 ELSE tip_amount END AS valor_gorjeta,
    CASE WHEN payment_type != 4 AND tolls_amount < 0 THEN tolls_amount * -1 ELSE tolls_amount END AS custo_pedagios,
    CASE WHEN payment_type != 4 AND improvement_surcharge < 0 THEN improvement_surcharge * -1 ELSE improvement_surcharge END AS custo_melhoria_sistema_taxi,
    CASE WHEN payment_type != 4 AND total_amount < 0 THEN total_amount * -1 ELSE total_amount END AS valor_total_corrida,
    strftime(tpep_pickup_datetime, '%d/%m/%Y') AS data_entrada,
    strftime(tpep_pickup_datetime, '%H:%M:%S') AS horario_entrada,
    EXTRACT(HOUR FROM tpep_pickup_datetime) AS hora_entrada,
    EXTRACT(MINUTE FROM tpep_pickup_datetime) AS minuto_entrada,
    EXTRACT(SECOND FROM tpep_pickup_datetime) AS segundo_entrada,  
    EXTRACT(YEAR FROM tpep_pickup_datetime) AS ano_entrada, 
    EXTRACT(DAY FROM tpep_pickup_datetime) AS dia_entrada,  
    EXTRACT(MONTH FROM tpep_pickup_datetime) AS mes_entrada,
    CASE WHEN hora_entrada BETWEEN 0 and 5 THEN 'Madrugada' WHEN hora_entrada BETWEEN 5 and 12 THEN 'Manhã'
    WHEN hora_entrada BETWEEN 12 and 18 THEN 'Tarde' ELSE 'Noite' END AS faixa_horario_entrada,
    CASE EXTRACT(DOW FROM tpep_pickup_datetime) WHEN 0 THEN 'Domingo'
    WHEN 6 THEN 'Sábado' WHEN 1 THEN 'Segunda' WHEN 2 THEN 'Terça'
    WHEN 3 THEN 'Quarta' WHEN 4 THEN 'Quinta' WHEN 5 THEN 'Sexta'
    END AS dia_semana_entrada,
    CASE WHEN EXTRACT(DOW FROM tpep_pickup_datetime)  IN (0,6) THEN 'Sim' ELSE 'Não' END AS entrada_final_de_semana,
    strftime(tpep_dropoff_datetime, '%d/%m/%Y') AS data_saida,
    strftime(tpep_dropoff_datetime, '%H:%M:%S') AS horario_saida,
    EXTRACT(HOUR FROM tpep_dropoff_datetime) AS hora_saida,
    EXTRACT(MINUTE FROM tpep_dropoff_datetime) AS minuto_saida,
    EXTRACT(SECOND FROM tpep_dropoff_datetime) AS segundo_saida,
    EXTRACT(YEAR FROM tpep_dropoff_datetime) AS ano_saida,  
    EXTRACT(DAY FROM tpep_dropoff_datetime) AS dia_saida,
    EXTRACT(MONTH FROM tpep_dropoff_datetime) AS mes_saida, 
    CASE EXTRACT(DOW FROM tpep_dropoff_datetime) WHEN 0 THEN 'Domingo'
    WHEN 6 THEN 'Sábado' WHEN 1 THEN 'Segunda' WHEN 2 THEN 'Terça'
    WHEN 3 THEN 'Quarta' WHEN 4 THEN 'Quinta' WHEN 5 THEN 'Sexta'
    END AS dia_semana_saida,
    CASE WHEN hora_saida BETWEEN 0 and 5 THEN 'Madrugada' WHEN hora_saida BETWEEN 5 and 12 THEN 'Manhã'
    WHEN hora_saida BETWEEN 12 and 18 THEN 'Tarde'  ELSE 'Noite' END AS faixa_horario_saida,
    CASE WHEN EXTRACT(DOW FROM tpep_dropoff_datetime) IN (0,6) THEN 'Sim' ELSE 'Não' END AS saida_final_de_semana,
    COALESCE(passenger_count, 1) as qnt_passageiros,
    COALESCE(store_and_fwd_flag, 'N') as store_and_fwd_normalizado,
    COALESCE(RatecodeID, 99) as rate_code_normalizado,
    COALESCE(CASE WHEN payment_type != 4 AND congestion_surcharge < 0 THEN congestion_surcharge * -1 ELSE congestion_surcharge END , 0.0) as taxa_extra_congestionamento,
    COALESCE(CASE WHEN payment_type != 4 AND Airport_fee < 0 THEN Airport_fee * -1 ELSE Airport_fee END, 0.0) as taxa_aeroporto
FROM
    yellow_data_n_tratado
WHERE 
    trip_distance > 0 
    AND (
        (EXTRACT(YEAR FROM tpep_pickup_datetime) = 2024 AND EXTRACT(MONTH FROM tpep_pickup_datetime) = 1)
        OR 
        (EXTRACT(YEAR FROM tpep_dropoff_datetime) = 2024 AND EXTRACT(MONTH FROM tpep_dropoff_datetime) = 1)
    );

select * from tratamento_inicial;

INSERT INTO Dim_Data (data, dia, mes, ano, dia_semana, fim_semana) 
SELECT data_entrada, dia_entrada, mes_entrada, ano_entrada, dia_semana_entrada, entrada_final_de_semana FROM tratamento_inicial
UNION
SELECT data_saida, dia_saida, mes_saida, ano_saida, dia_semana_saida, saida_final_de_semana FROM tratamento_inicial
ORDER BY ano_entrada, mes_entrada, dia_entrada;

SELECT * FROM Dim_Data;

INSERT INTO Dim_Horario (horario, hora, minuto, segundo, faixa_horario) 
SELECT horario_entrada, hora_entrada, minuto_entrada, segundo_entrada, faixa_horario_entrada FROM tratamento_inicial
UNION
SELECT horario_saida, hora_saida, minuto_saida, segundo_saida, faixa_horario_saida FROM tratamento_inicial
ORDER BY hora_entrada, minuto_entrada, segundo_entrada;

SELECT * FROM Dim_Horario;

INSERT INTO Dim_Local (local_id, bairro, zona, zona_servico)
SELECT LocationID, Borough, Zone, service_zone FROM taxi_zone;

SELECT * FROM Dim_Local