CREATE OR REPLACE SEQUENCE dim_data_seq START 1;

CREATE OR REPLACE SEQUENCE dim_horario_seq START 1; 

CREATE OR REPLACE TABLE Dim_Data (
    data_id INT DEFAULT nextval('dim_data_seq') PRIMARY KEY,
    data_format VARCHAR UNIQUE,
    data_raw DATE UNIQUE,
    ano INT,
    dia INT,
    mes INT,
    dia_semana VARCHAR,
    fim_semana VARCHAR
);
SELECT * FROM Dim_Data;

CREATE OR REPLACE TABLE Dim_Horario  (
    horario_id INT DEFAULT nextval('dim_horario_seq') PRIMARY KEY,
    horario_format VARCHAR UNIQUE,
    horario_raw TIME UNIQUE,
    hora INT,
    minuto INT,
    segundo INT,
    faixa_horario VARCHAR
);

CREATE OR REPLACE TABLE Dim_Local (
    local_id INT PRIMARY KEY,
    bairro VARCHAR,
    zona VARCHAR,
    zona_servico VARCHAR
);

CREATE OR REPLACE TABLE Dim_Pagamento (
    pagamento_id INT PRIMARY KEY,
    tipo_pagamento VARCHAR
);

CREATE OR REPLACE TABLE Dim_Vendedor (
    vendedor_id INT PRIMARY KEY,
    nome_vendedor VARCHAR
);

CREATE OR REPLACE TABLE Dim_Ratecode (
    ratecode_id INT PRIMARY KEY,
    nome_ratecode VARCHAR
);

CREATE OR REPLACE TABLE Fato_Viagem (
    vendedor_id INT REFERENCES Dim_Vendedor(vendedor_id),
    data_entrada INT REFERENCES Dim_Data(data_id),
    horario_entrada INT REFERENCES Dim_Horario(horario_id),
    data_saida INT REFERENCES Dim_Data(data_id),
    horario_saida INT REFERENCES Dim_Horario(horario_id),
    qnt_passageiros INT,
    distancia_corrida DOUBLE,
    ratecode_id INT REFERENCES Dim_Ratecode(ratecode_id),
    store_and_fwd_flag VARCHAR,
    local_entrada_id INT REFERENCES Dim_local(local_id),
    local_saida_id INT REFERENCES Dim_local(local_id),
    pagamento_id INT REFERENCES Dim_Pagamento(pagamento_id),
    custo_tarifa DOUBLE,
    custo_adicional DOUBLE,
    imposto_mta DOUBLE,
    valor_gorjeta DOUBLE,
    custo_pedagios DOUBLE,
    custo_melhoria_sistema_taxi DOUBLE,
    valor_total_corrida DOUBLE,
    taxa_congestionamento DOUBLE,
    taxa_aeroporto DOUBLE
);

SHOW TABLES;
