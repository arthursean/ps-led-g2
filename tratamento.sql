CREATE OR REPLACE TABLE taxi_zone AS
SELECT * FROM read_csv('taxi_zone_lookup.csv');

CREATE OR REPLACE TABLE yellow_data_n_tratado AS 
SELECT * FROM read_parquet('yellow_tripdata_2024-01.parquet');

CREATE OR REPLACE VIEW tratamento_inicial  AS
SELECT
    VendorId as id_empresa,
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
    LEAST(tpep_pickup_datetime, tpep_dropoff_datetime) as tpep_pickup_datetime_corrigido,
    GREATEST(tpep_pickup_datetime, tpep_dropoff_datetime) as tpep_dropoff_datetime_corrigido,
    CASE WHEN trip_distance > 0.1 AND  trip_distance < 150 THEN ABS(trip_distance)
    WHEN ABS(custo_tarifa) > 3.0 THEN ROUND(((ABS(custo_tarifa) - 3.00) / 3.50), 2)
    ELSE ABS(trip_distance)
    END AS distancia_corrida, 
    CAST(tpep_pickup_datetime_corrigido AS DATE) AS data_entrada,
    CAST(tpep_pickup_datetime_corrigido AS TIME) AS horario_entrada,
    CAST(tpep_dropoff_datetime_corrigido AS DATE) AS data_saida,
    CAST(tpep_dropoff_datetime_corrigido AS TIME) AS horario_saida,
    DATEDIFF('MINUTE', tpep_pickup_datetime_corrigido, tpep_dropoff_datetime_corrigido) as duracao_corrida,
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

INSERT INTO Dim_Data (data_raw, data_format, dia, mes, ano, dia_semana, fim_semana) 
SELECT data_entrada, 
    STRFTIME(tpep_pickup_datetime_corrigido, '%d/%m/%Y'), 
    EXTRACT(DAY FROM tpep_pickup_datetime_corrigido),
    EXTRACT(MONTH FROM tpep_pickup_datetime_corrigido), 
    EXTRACT(YEAR FROM tpep_pickup_datetime_corrigido), 
    CASE EXTRACT(DOW FROM tpep_pickup_datetime_corrigido) WHEN 0 THEN 'Domingo' WHEN 6 THEN 'Sábado' WHEN 1 THEN 'Segunda' WHEN 2 THEN 'Terça' WHEN 3 THEN 'Quarta' WHEN 4 THEN 'Quinta' WHEN 5 THEN 'Sexta' END, 
    CASE WHEN EXTRACT(DOW FROM tpep_pickup_datetime_corrigido) IN (0,6) THEN 'Sim' ELSE 'Não' END 
FROM tratamento_inicial
UNION
SELECT data_saida, 
    STRFTIME(tpep_dropoff_datetime_corrigido, '%d/%m/%Y'), 
    EXTRACT(DAY FROM tpep_dropoff_datetime_corrigido), 
    EXTRACT(MONTH FROM tpep_dropoff_datetime_corrigido), 
    EXTRACT(YEAR FROM tpep_dropoff_datetime_corrigido), 
    CASE EXTRACT(DOW FROM tpep_dropoff_datetime_corrigido) WHEN 0 THEN 'Domingo' WHEN 6 THEN 'Sábado' WHEN 1 THEN 'Segunda' 
    WHEN 2 THEN 'Terça' WHEN 3 THEN 'Quarta' WHEN 4 THEN 'Quinta' WHEN 5 THEN 'Sexta' END, 
    CASE WHEN EXTRACT(DOW FROM tpep_dropoff_datetime_corrigido) IN (0,6) THEN 'Sim' ELSE 'Não' END 
FROM tratamento_inicial;

INSERT INTO Dim_Horario (horario_raw, horario_format, hora, minuto, segundo, faixa_horario) 
SELECT horario_entrada, 
    STRFTIME(tpep_pickup_datetime_corrigido, '%H:%M:%S'),
    EXTRACT(HOUR FROM tpep_pickup_datetime_corrigido) as hora_entrada,
    EXTRACT(MINUTE FROM tpep_pickup_datetime_corrigido),
    EXTRACT(SECOND FROM tpep_pickup_datetime_corrigido), 
    CASE WHEN hora_entrada BETWEEN 0 and 5 THEN 'Madrugada' WHEN hora_entrada BETWEEN 5 and 12 THEN 'Manhã'
    WHEN hora_entrada BETWEEN 12 and 18 THEN 'Tarde' ELSE 'Noite' END
FROM tratamento_inicial
UNION
SELECT horario_saida, 
    STRFTIME(tpep_dropoff_datetime_corrigido, '%H:%M:%S'),
    EXTRACT(HOUR FROM tpep_dropoff_datetime_corrigido) as hora_saida,
    EXTRACT(MINUTE FROM tpep_dropoff_datetime_corrigido),
    EXTRACT(SECOND FROM tpep_dropoff_datetime_corrigido), 
    CASE WHEN hora_saida BETWEEN 0 and 5 THEN 'Madrugada' WHEN hora_saida BETWEEN 5 and 12 THEN 'Manhã'
    WHEN hora_saida BETWEEN 12 and 18 THEN 'Tarde' ELSE 'Noite' END
FROM tratamento_inicial;

INSERT INTO Dim_Local (local_id, bairro, zona, zona_servico)
SELECT LocationID, Borough, Zone, service_zone FROM taxi_zone;

INSERT INTO Dim_Pagamento (pagamento_id, tipo_pagamento)
SELECT DISTINCT tipo_pagamento,
    CASE tipo_pagamento 
    WHEN 0 THEN 'Flex Fare trip'
    WHEN 1 THEN 'Credit card'
    WHEN 2 THEN 'Cash'
    WHEN 3 THEN 'No charge'
    WHEN 4 THEN 'Dispute'
    WHEN 5 THEN 'Unknown'
    WHEN 6 THEN 'Voided trip'
    END AS nome_pagamento
FROM tratamento_inicial
ORDER BY tipo_pagamento;

INSERT INTO Dim_Vendedor (vendedor_id, nome_vendedor)
SELECT DISTINCT id_empresa,
    CASE id_empresa 
    WHEN 1 THEN 'Creative Mobile Technologies, LLC'
    WHEN 2 THEN 'Curb Mobility, LLC'
    WHEN 6 THEN 'Myle Technologies Inc'
    WHEN 7 THEN 'Helix'
    END AS nome_vendedor
FROM tratamento_inicial
ORDER BY id_empresa;

INSERT INTO Dim_Ratecode (ratecode_id, nome_ratecode)
SELECT DISTINCT rate_code_normalizado,
    CASE rate_code_normalizado 
    WHEN 1 THEN 'Standard rate'
    WHEN 2 THEN 'JFK'
    WHEN 3 THEN 'Newark'
    WHEN 4 THEN 'Nassau or Westchester'
    WHEN 5 THEN 'Negotiated fare'
    WHEN 6 THEN 'Group ride'
    WHEN 99 THEN 'Null/unknown'
    END AS nome_ratecode
FROM tratamento_inicial
ORDER BY rate_code_normalizado;

INSERT INTO Fato_Viagem (vendedor_id, ratecode_id, pagamento_id, data_entrada, horario_entrada, data_saida, horario_saida, local_entrada_id, local_saida_id, qnt_passageiros, distancia_corrida, store_and_fwd_flag, custo_tarifa, custo_adicional, imposto_mta, valor_gorjeta, custo_pedagios, custo_melhoria_sistema_taxi, valor_total_corrida, taxa_congestionamento, taxa_aeroporto)
SELECT t.id_empresa, t.rate_code_normalizado, t.tipo_pagamento, data_entrada.data_id, horario_entrada.horario_id, data_saida.data_id, horario_saida.horario_id, t.local_entrada, t.local_saida, t.qnt_passageiros, t.distancia_corrida, t.store_and_fwd_normalizado, t.custo_tarifa, t.custo_adicional, t.taxa_fixa_mta, t.valor_gorjeta, t.custo_pedagios, t.custo_melhoria_sistema_taxi, t.valor_total_corrida, t.taxa_extra_congestionamento, t.taxa_aeroporto
FROM tratamento_inicial t
LEFT JOIN Dim_Data data_entrada
    ON t.data_entrada = data_entrada.data_raw
LEFT JOIN Dim_Data data_saida
    ON t.data_saida = data_saida.data_raw
LEFT JOIN Dim_Horario horario_entrada
    ON t.horario_entrada = horario_entrada.horario_raw
LEFT JOIN Dim_Horario horario_saida
    ON t.horario_saida = horario_saida.horario_raw;

SELECT * FROM Fato_Viagem