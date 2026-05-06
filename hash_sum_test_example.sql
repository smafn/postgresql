START TRANSACTION;


CREATE OR REPLACE PROCEDURE create_test_all_types_table(_table_name TEXT)
    LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format($sql$
        CREATE TABLE %1$s (
            id SERIAL PRIMARY KEY,
            smallint_field SMALLINT,
            integer_field INTEGER,
            bigint_field BIGINT,
            decimal_field DECIMAL(10, 2),
            numeric_field NUMERIC(10, 2),
            real_field REAL,
            double_precision_field DOUBLE PRECISION,
            money_field MONEY,
            char_field CHAR(10),
            varchar_field VARCHAR(255),
            text_field TEXT,
            boolean_field BOOLEAN,
            date_field DATE,
            time_field TIME,
            timestamp_field TIMESTAMP,
            timestamptz_field TIMESTAMPTZ,
            interval_field INTERVAL,
            json_field JSON,
            jsonb_field JSONB,
            uuid_field UUID,
            bytea_field BYTEA,
            cidr_field CIDR,
            inet_field INET,
            macaddr_field MACADDR,
            point_field POINT,
            line_field LINE,
            lseg_field LSEG,
            box_field BOX,
            path_field PATH,
            polygon_field POLYGON,
            circle_field CIRCLE,
            tsquery_field TSQUERY,
            tsvector_field TSVECTOR
        )
    $sql$, _table_name);
END;
$$;


CREATE OR REPLACE FUNCTION random_int(min_val NUMERIC, max_val NUMERIC)
    RETURNS BIGINT
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN FLOOR(RANDOM() * (max_val - min_val) + min_val)::BIGINT;
END;
$$;


CREATE OR REPLACE FUNCTION random_float(min_val DOUBLE PRECISION, max_val DOUBLE PRECISION)
    RETURNS DOUBLE PRECISION
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN RANDOM() * (max_val - min_val) + min_val;
END;
$$;


CREATE FUNCTION random_string(len INT)
    RETURNS TEXT
    LANGUAGE plpgsql AS $$
DECLARE
    result TEXT = '';
    i INT;
    available_symbols TEXT = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    available_symbols_len INT := length(available_symbols);
BEGIN
    FOR i IN 1 .. len
    LOOP
        result := result || substr(available_symbols, floor(random() * available_symbols_len + 1)::INT, 1);
    END LOOP;
    return result;
END
$$;


CREATE OR REPLACE FUNCTION random_bool()
    RETURNS BOOLEAN
    LANGUAGE plpgsql AS $$
BEGIN
    RETURN RANDOM() < 0.5;
END;
$$;


CREATE OR REPLACE FUNCTION random_timestamp(start_ts TIMESTAMP, end_ts TIMESTAMP)
    RETURNS TIMESTAMP
    LANGUAGE plpgsql AS $$
DECLARE
    delta DOUBLE PRECISION;
BEGIN
    delta := EXTRACT(EPOCH FROM end_ts - start_ts);
    RETURN start_ts + (RANDOM() * delta) * INTERVAL '1 second';
END;
$$;


CREATE OR REPLACE FUNCTION random_bytea(length INT)
    RETURNS BYTEA
    LANGUAGE plpgsql AS $$
DECLARE
    result BYTEA := repeat(E'\\000', length);
    i INT;
BEGIN
    FOR i IN 0..length - 1 LOOP
        result := set_byte(result, i, FLOOR(RANDOM() * 256)::INT);
    END LOOP;
    RETURN result;
END;
$$;


CREATE OR REPLACE FUNCTION random_cidr(base_cidr CIDR, min_mask INT, max_mask INT)
    RETURNS CIDR
    LANGUAGE plpgsql AS $$
DECLARE
    base_ip INET;
    base_prefix INT;
    rand_mask INT;
    host_bits INT;
    max_hosts BIGINT;
    rand_offset BIGINT;
    new_ip INET;
BEGIN
    base_ip := host(base_cidr);
    base_prefix := masklen(base_cidr);

    rand_mask := random_int(GREATEST(min_mask, base_prefix), LEAST(max_mask, 32));

    host_bits := 32 - rand_mask;

    max_hosts := 2 ^ host_bits;

    rand_offset := FLOOR(RANDOM() * max_hosts);

    new_ip := base_ip + rand_offset;

    RETURN set_masklen(new_ip, rand_mask)::CIDR;
END;
$$;


CREATE OR REPLACE FUNCTION random_inet()
    RETURNS INET
    LANGUAGE plpgsql AS $$
DECLARE
    octet1 INT := FLOOR(RANDOM() * 256);
    octet2 INT := FLOOR(RANDOM() * 256);
    octet3 INT := FLOOR(RANDOM() * 256);
    octet4 INT := FLOOR(RANDOM() * 256);
BEGIN
    RETURN (octet1 || '.' || octet2 || '.' || octet3 || '.' || octet4)::INET;
END;
$$;


CREATE OR REPLACE FUNCTION random_macaddr()
    RETURNS MACADDR
    LANGUAGE plpgsql AS $$
DECLARE
    octets TEXT := '';
    i INT;
BEGIN
    FOR i IN 1..6 LOOP
        octets := octets || lpad(to_hex(FLOOR(RANDOM() * 256)::INT), 2, '0');
        IF i < 6 THEN
            octets := octets || ':';
        END IF;
    END LOOP;

    RETURN octets::MACADDR;
END;
$$;


CREATE OR REPLACE FUNCTION random_insert_into_test_all_types_table(_table_name TEXT, n INT)
    RETURNS INT[]
    LANGUAGE plpgsql AS $$
DECLARE
    _ids INT[];
BEGIN
    EXECUTE format($sql$
        WITH random_rows AS (
            INSERT INTO %1$s (
                smallint_field,
                integer_field,
                bigint_field,
                decimal_field,
                numeric_field,
                real_field,
                double_precision_field,
                money_field,
                char_field,
                varchar_field,
                text_field,
                boolean_field,
                date_field,
                time_field,
                timestamp_field,
                timestamptz_field,
                interval_field,
                json_field,
                jsonb_field,
                uuid_field,
                bytea_field,
                cidr_field,
                inet_field,
                macaddr_field,
                point_field,
                line_field,
                lseg_field,
                box_field,
                path_field,
                polygon_field,
                circle_field,
                tsquery_field,
                tsvector_field
            )
            SELECT
                random_int(-32768, 32767),
                random_int(-2147483648, 2147483647),
                random_int(-9223372036854775808, 9223372036854775807),
                random_float(-10000, 10000),
                random_float(-10000, 10000),
                random_float(-10000, 10000),
                random_float(-10000, 10000),
                REPLACE(round(random_float(0, 10000)::NUMERIC(10, 2), 2)::TEXT, '.', ',')::MONEY,
                random_string(1),
                random_string(10),
                random_string(255),
                random_bool(),
                random_timestamp('1900-01-01', '2100-01-01'),
                random_timestamp('1900-01-01', '2100-01-01'),
                random_timestamp('1900-01-01', '2100-01-01'),
                random_timestamp('1900-01-01', '2100-01-01'),
                random_timestamp('1900-01-01', '2100-01-01') - random_timestamp('1900-01-01', '2100-01-01'),
                ('{"' || random_string(10) || '": "' || random_string(10) || '"}')::JSON,
                ('{"' || random_string(10) || '": "' || random_string(10) || '"}')::JSONB,
                gen_random_uuid(),
                random_bytea(16),
                random_cidr('10.0.0.0/8', 16, 24),
                random_inet(),
                random_macaddr(),
                ('(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || ')')::POINT,
                ('{' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '}')::LINE,
                ('[(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || ')]')::LSEG,
                ('((' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '))')::BOX,
                ('((' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '))')::PATH,
                ('((' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '))')::POLYGON,
                ('<(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),' || random_int(1, 9)::TEXT || '>')::CIRCLE,
                (random_string(10) || ' & ' || random_string(10))::TSQUERY,
                (random_string(60))::TSVECTOR
            FROM generate_series(1, %2$s)
            RETURNING id
        )
        SELECT array_agg(id) FROM random_rows
    $sql$, _table_name, n) INTO _ids;
    RETURN _ids;
END
$$;


CREATE OR REPLACE PROCEDURE delete_test_all_types_table(_table_name TEXT)
    LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format($sql$
        DROP TABLE %1$s CASCADE
    $sql$, _table_name);
END
$$;


DO
$$
DECLARE
    table_name TEXT := 'test_all_types_table';
    n INT := 1000;
    hash_sum BIGINT;
BEGIN
    RAISE NOTICE 'Тест 1: Работоспособность функции.';
    CALL create_test_all_types_table(table_name);
    PERFORM random_insert_into_test_all_types_table(table_name, n);
    hash_sum := get_table_hash_sum(table_name);
    RAISE NOTICE 'Хеш сумма: %', hash_sum;
    CALL delete_test_all_types_table(table_name);
END;
$$;


DO
$$
DECLARE
    table_name TEXT := 'test_all_types_table';
    n INT := 10000;
    hash_sum BIGINT;
BEGIN
    RAISE NOTICE 'Тест 2: Функция для нулевой таблицы.';
    CALL create_test_all_types_table(table_name);
    hash_sum := get_table_hash_sum(table_name);
    RAISE NOTICE 'Хеш сумма: %', hash_sum;
    CALL delete_test_all_types_table(table_name);
END;
$$;


DO
$$
DECLARE
    hash_sum_1 BIGINT;
    hash_sum_2 BIGINT;
    _id BIGINT;
    _smallint_field SMALLINT;
    _integer_field INTEGER;
    _bigint_field BIGINT;
    _decimal_field DECIMAL(10, 2);
    _numeric_field NUMERIC(10, 2);
    _real_field REAL;
    _double_precision_field DOUBLE PRECISION;
    _money_field MONEY;
    _char_field CHAR(10);
    _varchar_field VARCHAR(255);
    _text_field TEXT;
    _boolean_field BOOLEAN;
    _date_field DATE;
    _time_field TIME;
    _timestamp_field TIMESTAMP;
    _timestamptz_field TIMESTAMPTZ;
    _interval_field INTERVAL;
    _json_field JSON;
    _jsonb_field JSONB;
    _uuid_field UUID;
    _bytea_field BYTEA;
    _cidr_field CIDR;
    _inet_field INET;
    _macaddr_field MACADDR;
    _point_field POINT;
    _line_field LINE;
    _lseg_field LSEG;
    _box_field BOX;
    _path_field PATH;
    _polygon_field POLYGON;
    _circle_field CIRCLE;
    _tsquery_field TSQUERY;
    _tsvector_field TSVECTOR;
BEGIN
    RAISE NOTICE 'Тест 3: Функция для одинаковых данных в разных таблицах.';
    CALL create_test_all_types_table('test_all_types_table_1');
    CALL create_test_all_types_table('test_all_types_table_2');

    _id := 1;
    _smallint_field := random_int(-32768, 32767);
    _integer_field := random_int(-2147483648, 2147483647);
    _bigint_field := random_int(-9223372036854775808, 9223372036854775807);
    _decimal_field := random_float(-10000, 10000);
    _numeric_field := random_float(-10000, 10000);
    _real_field := random_float(-10000, 10000);
    _double_precision_field := random_float(-10000, 10000);
    _money_field := REPLACE(round(random_float(0, 10000)::NUMERIC(10, 2), 2)::TEXT, '.', ',')::MONEY;
    _char_field := random_string(1);
    _varchar_field := random_string(10);
    _text_field := random_string(255);
    _boolean_field := random_bool();
    _date_field := random_timestamp('1900-01-01', '2100-01-01');
    _time_field := random_timestamp('1900-01-01', '2100-01-01');
    _timestamp_field := random_timestamp('1900-01-01', '2100-01-01');
    _timestamptz_field := random_timestamp('1900-01-01', '2100-01-01');
    _interval_field := random_timestamp('1900-01-01', '2100-01-01') - random_timestamp('1900-01-01', '2100-01-01');
    _json_field := ('{"' || random_string(10) || '": "' || random_string(10) || '"}')::JSON;
    _jsonb_field := ('{"' || random_string(10) || '": "' || random_string(10) || '"}')::JSONB;
    _uuid_field := gen_random_uuid();
    _bytea_field := random_bytea(16);
    _cidr_field := random_cidr('10.0.0.0/8', 16, 24);
    _inet_field := random_inet();
    _macaddr_field := random_macaddr();
    _point_field := ('(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || ')')::POINT;
    _line_field := ('{' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '}')::LINE;
    _lseg_field := ('[(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || ')]')::LSEG;
    _box_field := ('((' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '))')::BOX;
    _path_field := ('((' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '))')::PATH;
    _polygon_field := ('((' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '))')::POLYGON;
    _circle_field := ('<(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),' || random_int(1, 9)::TEXT || '>')::CIRCLE;
    _tsquery_field := (random_string(10) || ' & ' || random_string(10))::TSQUERY;
    _tsvector_field := (random_string(60))::TSVECTOR;

    INSERT INTO test_all_types_table_1 (
            id,
            smallint_field,
            integer_field,
            bigint_field,
            decimal_field,
            numeric_field,
            real_field,
            double_precision_field,
            money_field,
            char_field,
            varchar_field,
            text_field,
            boolean_field,
            date_field,
            time_field,
            timestamp_field,
            timestamptz_field,
            interval_field,
            json_field,
            jsonb_field,
            uuid_field,
            bytea_field,
            cidr_field,
            inet_field,
            macaddr_field,
            point_field,
            line_field,
            lseg_field,
            box_field,
            path_field,
            polygon_field,
            circle_field,
            tsquery_field,
            tsvector_field
        )
        VALUES (
            _id,
            _smallint_field,
            _integer_field,
            _bigint_field,
            _decimal_field,
            _numeric_field,
            _real_field,
            _double_precision_field,
            _money_field,
            _char_field,
            _varchar_field,
            _text_field,
            _boolean_field,
            _date_field,
            _time_field,
            _timestamp_field,
            _timestamptz_field,
            _interval_field,
            _json_field,
            _jsonb_field,
            _uuid_field,
            _bytea_field,
            _cidr_field,
            _inet_field,
            _macaddr_field,
            _point_field,
            _line_field,
            _lseg_field,
            _box_field,
            _path_field,
            _polygon_field,
            _circle_field,
            _tsquery_field,
            _tsvector_field
        );

    INSERT INTO test_all_types_table_2 (
            id,
            smallint_field,
            integer_field,
            bigint_field,
            decimal_field,
            numeric_field,
            real_field,
            double_precision_field,
            money_field,
            char_field,
            varchar_field,
            text_field,
            boolean_field,
            date_field,
            time_field,
            timestamp_field,
            timestamptz_field,
            interval_field,
            json_field,
            jsonb_field,
            uuid_field,
            bytea_field,
            cidr_field,
            inet_field,
            macaddr_field,
            point_field,
            line_field,
            lseg_field,
            box_field,
            path_field,
            polygon_field,
            circle_field,
            tsquery_field,
            tsvector_field
        )
        VALUES (
            _id,
            _smallint_field,
            _integer_field,
            _bigint_field,
            _decimal_field,
            _numeric_field,
            _real_field,
            _double_precision_field,
            _money_field,
            _char_field,
            _varchar_field,
            _text_field,
            _boolean_field,
            _date_field,
            _time_field,
            _timestamp_field,
            _timestamptz_field,
            _interval_field,
            _json_field,
            _jsonb_field,
            _uuid_field,
            _bytea_field,
            _cidr_field,
            _inet_field,
            _macaddr_field,
            _point_field,
            _line_field,
            _lseg_field,
            _box_field,
            _path_field,
            _polygon_field,
            _circle_field,
            _tsquery_field,
            _tsvector_field
        );

    hash_sum_1 := get_table_hash_sum('test_all_types_table_1');
    hash_sum_2 := get_table_hash_sum('test_all_types_table_2');
    RAISE NOTICE 'Хеш сумма таблицы 1: %', hash_sum_1;
    RAISE NOTICE 'Хеш сумма таблицы 2: %', hash_sum_2;
    CALL delete_test_all_types_table('test_all_types_table_1');
    CALL delete_test_all_types_table('test_all_types_table_2');
END;
$$;


DO
$$
DECLARE
    table_name TEXT := 'test_all_types_table';
    hash_sum_1 BIGINT;
    hash_sum_2 BIGINT;
    hash_sum_3 BIGINT;
    _id_1 BIGINT;
    _id_2 BIGINT;
    _smallint_field_1 SMALLINT;
    _smallint_field_2 SMALLINT;
    _integer_field_1 INTEGER;
    _integer_field_2 INTEGER;
    _bigint_field_1 BIGINT;
    _bigint_field_2 BIGINT;
    _decimal_field_1 DECIMAL(10, 2);
    _decimal_field_2 DECIMAL(10, 2);
    _numeric_field_1 NUMERIC(10, 2);
    _numeric_field_2 NUMERIC(10, 2);
    _real_field_1 REAL;
    _real_field_2 REAL;
    _double_precision_field_1 DOUBLE PRECISION;
    _double_precision_field_2 DOUBLE PRECISION;
    _money_field_1 MONEY;
    _money_field_2 MONEY;
    _char_field_1 CHAR(10);
    _char_field_2 CHAR(10);
    _varchar_field_1 VARCHAR(255);
    _varchar_field_2 VARCHAR(255);
    _text_field_1 TEXT;
    _text_field_2 TEXT;
    _boolean_field_1 BOOLEAN;
    _boolean_field_2 BOOLEAN;
    _date_field_1 DATE;
    _date_field_2 DATE;
    _time_field_1 TIME;
    _time_field_2 TIME;
    _timestamp_field_1 TIMESTAMP;
    _timestamp_field_2 TIMESTAMP;
    _timestamptz_field_1 TIMESTAMPTZ;
    _timestamptz_field_2 TIMESTAMPTZ;
    _interval_field_1 INTERVAL;
    _interval_field_2 INTERVAL;
    _json_field_1 JSON;
    _json_field_2 JSON;
    _jsonb_field_1 JSONB;
    _jsonb_field_2 JSONB;
    _uuid_field_1 UUID;
    _uuid_field_2 UUID;
    _bytea_field_1 BYTEA;
    _bytea_field_2 BYTEA;
    _cidr_field_1 CIDR;
    _cidr_field_2 CIDR;
    _inet_field_1 INET;
    _inet_field_2 INET;
    _macaddr_field_1 MACADDR;
    _macaddr_field_2 MACADDR;
    _point_field_1 POINT;
    _point_field_2 POINT;
    _line_field_1 LINE;
    _line_field_2 LINE;
    _lseg_field_1 LSEG;
    _lseg_field_2 LSEG;
    _box_field_1 BOX;
    _box_field_2 BOX;
    _path_field_1 PATH;
    _path_field_2 PATH;
    _polygon_field_1 POLYGON;
    _polygon_field_2 POLYGON;
    _circle_field_1 CIRCLE;
    _circle_field_2 CIRCLE;
    _tsquery_field_1 TSQUERY;
    _tsquery_field_2 TSQUERY;
    _tsvector_field_1 TSVECTOR;
    _tsvector_field_2 TSVECTOR;
BEGIN
    RAISE NOTICE 'Тест 4: Влияние полей таблицы на результат.';
    CALL create_test_all_types_table(table_name);

    _id_1 := 1;
    _smallint_field_1 := random_int(-32768, 32767);
    _integer_field_1 := random_int(-2147483648, 2147483647);
    _bigint_field_1 := random_int(-9223372036854775808, 9223372036854775807);
    _decimal_field_1 := random_float(-10000, 10000);
    _numeric_field_1 := random_float(-10000, 10000);
    _real_field_1 := random_float(-10000, 10000);
    _double_precision_field_1 := random_float(-10000, 10000);
    _money_field_1 := REPLACE(round(random_float(0, 10000)::NUMERIC(10, 2), 2)::TEXT, '.', ',')::MONEY;
    _char_field_1 := random_string(1);
    _varchar_field_1 := random_string(10);
    _text_field_1 := random_string(255);
    _boolean_field_1 := TRUE;
    _date_field_1 := random_timestamp('1900-01-01', '2100-01-01');
    _time_field_1 := random_timestamp('1900-01-01', '2100-01-01');
    _timestamp_field_1 := random_timestamp('1900-01-01', '2100-01-01');
    _timestamptz_field_1 := random_timestamp('1900-01-01', '2100-01-01');
    _interval_field_1 := random_timestamp('1900-01-01', '2100-01-01') - random_timestamp('1900-01-01', '2100-01-01');
    _json_field_1 := ('{"' || random_string(10) || '": "' || random_string(10) || '"}')::JSON;
    _jsonb_field_1 := ('{"' || random_string(10) || '": "' || random_string(10) || '"}')::JSONB;
    _uuid_field_1 := gen_random_uuid();
    _bytea_field_1 := random_bytea(16);
    _cidr_field_1 := random_cidr('10.0.0.0/8', 16, 24);
    _inet_field_1 := random_inet();
    _macaddr_field_1 := random_macaddr();
    _point_field_1 := ('(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || ')')::POINT;
    _line_field_1 := ('{' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '}')::LINE;
    _lseg_field_1 := ('[(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || ')]')::LSEG;
    _box_field_1 := ('((' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '))')::BOX;
    _path_field_1 := ('((' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '))')::PATH;
    _polygon_field_1 := ('((' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '))')::POLYGON;
    _circle_field_1 := ('<(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),' || random_int(1, 9)::TEXT || '>')::CIRCLE;
    _tsquery_field_1 := (random_string(10) || ' & ' || random_string(10))::TSQUERY;
    _tsvector_field_1 := (random_string(60))::TSVECTOR;

    INSERT INTO test_all_types_table (
            id,
            smallint_field,
            integer_field,
            bigint_field,
            decimal_field,
            numeric_field,
            real_field,
            double_precision_field,
            money_field,
            char_field,
            varchar_field,
            text_field,
            boolean_field,
            date_field,
            time_field,
            timestamp_field,
            timestamptz_field,
            interval_field,
            json_field,
            jsonb_field,
            uuid_field,
            bytea_field,
            cidr_field,
            inet_field,
            macaddr_field,
            point_field,
            line_field,
            lseg_field,
            box_field,
            path_field,
            polygon_field,
            circle_field,
            tsquery_field,
            tsvector_field
        )
        VALUES (
            _id_1,
            _smallint_field_1,
            _integer_field_1,
            _bigint_field_1,
            _decimal_field_1,
            _numeric_field_1,
            _real_field_1,
            _double_precision_field_1,
            _money_field_1,
            _char_field_1,
            _varchar_field_1,
            _text_field_1,
            _boolean_field_1,
            _date_field_1,
            _time_field_1,
            _timestamp_field_1,
            _timestamptz_field_1,
            _interval_field_1,
            _json_field_1,
            _jsonb_field_1,
            _uuid_field_1,
            _bytea_field_1,
            _cidr_field_1,
            _inet_field_1,
            _macaddr_field_1,
            _point_field_1,
            _line_field_1,
            _lseg_field_1,
            _box_field_1,
            _path_field_1,
            _polygon_field_1,
            _circle_field_1,
            _tsquery_field_1,
            _tsvector_field_1
        );

    _id_2 := 2;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET id = _id_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET id = _id_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле id. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _smallint_field_2 := random_int(-32768, 32767);
        EXIT WHEN _smallint_field_1 != _smallint_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET smallint_field = _smallint_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET smallint_field = _smallint_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле SMALLINT. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _integer_field_2 := random_int(-2147483648, 2147483647);
        EXIT WHEN _integer_field_1 != _integer_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET integer_field = _integer_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET integer_field = _integer_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле INTEGER. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _bigint_field_2 := random_int(-9223372036854775808, 9223372036854775807);
        EXIT WHEN _bigint_field_1 != _bigint_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET bigint_field = _bigint_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET bigint_field = _bigint_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле BIGINT. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _decimal_field_2 := random_float(-10000, 10000);
        EXIT WHEN _decimal_field_1 != _decimal_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET decimal_field = _decimal_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET decimal_field = _decimal_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле DECIMAL. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _numeric_field_2 := random_float(-10000, 10000);
        EXIT WHEN _numeric_field_1 != _numeric_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET numeric_field = _numeric_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET numeric_field = _numeric_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле NUMERIC. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _real_field_2 := random_float(-10000, 10000);
        EXIT WHEN _real_field_1 != _real_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET real_field = _real_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET real_field = _real_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле REAL. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _double_precision_field_2 := random_float(-10000, 10000);
        EXIT WHEN _double_precision_field_1 != _double_precision_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET double_precision_field = _double_precision_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET double_precision_field = _double_precision_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле DOUBLE PRECISION. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _money_field_2 := REPLACE(round(random_float(0, 10000)::NUMERIC(10, 2), 2)::TEXT, '.', ',')::MONEY;
        EXIT WHEN _money_field_1 != _money_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET money_field = _money_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET money_field = _money_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле MONEY. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _char_field_2 := random_string(1);
        EXIT WHEN _char_field_1 != _char_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET char_field = _char_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET char_field = _char_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле CHAR. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _varchar_field_2 := random_string(10);
        EXIT WHEN _varchar_field_1 != _varchar_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET varchar_field = _varchar_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET varchar_field = _varchar_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле VARCHAR. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _text_field_2 := random_string(255);
        EXIT WHEN _text_field_1 != _text_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET text_field = _text_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET text_field = _text_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле TEXT. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    _boolean_field_2 := FALSE;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET boolean_field = _boolean_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET boolean_field = _boolean_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле BOOLEAN. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _date_field_2 := random_timestamp('1900-01-01', '2100-01-01');
        EXIT WHEN _date_field_1 != _date_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET date_field = _date_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET date_field = _date_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле DATE. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _time_field_2 := random_timestamp('1900-01-01', '2100-01-01');
        EXIT WHEN _time_field_1 != _time_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET time_field = _time_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET time_field = _time_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле TIME. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _timestamp_field_2 := random_timestamp('1900-01-01', '2100-01-01');
        EXIT WHEN _timestamp_field_1 != _timestamp_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET timestamp_field = _timestamp_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET timestamp_field = _timestamp_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле TIMESTAMP. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _timestamptz_field_2 := random_timestamp('1900-01-01', '2100-01-01');
        EXIT WHEN _timestamptz_field_1 != _timestamptz_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET timestamptz_field = _timestamptz_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET timestamptz_field = _timestamptz_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле TIMESTAMPTZ. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _interval_field_2 := random_timestamp('1900-01-01', '2100-01-01') - random_timestamp('1900-01-01', '2100-01-01');
        EXIT WHEN _interval_field_1 != _interval_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET interval_field = _interval_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET interval_field = _interval_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле INTERVAL. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _json_field_2 := ('{"' || random_string(10) || '": "' || random_string(10) || '"}')::JSON;
        EXIT WHEN _json_field_1::TEXT != _json_field_2::TEXT;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET json_field = _json_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET json_field = _json_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле JSON. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _jsonb_field_2 := ('{"' || random_string(10) || '": "' || random_string(10) || '"}')::JSONB;
        EXIT WHEN _jsonb_field_1 != _jsonb_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET jsonb_field = _jsonb_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET jsonb_field = _jsonb_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле JSONB. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _uuid_field_2 := gen_random_uuid();
        EXIT WHEN _uuid_field_1 != _uuid_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET uuid_field = _uuid_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET uuid_field = _uuid_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле UUID. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _bytea_field_2 := random_bytea(16);
        EXIT WHEN _bytea_field_1 != _bytea_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET bytea_field = _bytea_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET bytea_field = _bytea_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле BYTEA. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _cidr_field_2 := random_cidr('10.0.0.0/8', 16, 24);
        EXIT WHEN _cidr_field_1 != _cidr_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET cidr_field = _cidr_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET cidr_field = _cidr_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле CIDR. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _inet_field_2 := random_inet();
        EXIT WHEN _inet_field_1 != _inet_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET inet_field = _inet_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET inet_field = _inet_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле INET. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _macaddr_field_2 := random_macaddr();
        EXIT WHEN _macaddr_field_1 != _macaddr_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET macaddr_field = _macaddr_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET macaddr_field = _macaddr_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле MACADDR. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _point_field_2 := ('(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || ')')::POINT;
        EXIT WHEN _point_field_1 != _point_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET point_field = _point_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET point_field = _point_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле POINT. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _line_field_2 := ('{' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '}')::LINE;
        EXIT WHEN _line_field_1::TEXT != _line_field_2::TEXT;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET line_field = _line_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET line_field = _line_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле LINE. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _lseg_field_2 := ('[(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || ')]')::LSEG;
        EXIT WHEN _lseg_field_1 != _lseg_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET lseg_field = _lseg_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET lseg_field = _lseg_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле LSEG. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _box_field_2 := ('((' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '))')::BOX;
        EXIT WHEN _box_field_1::TEXT != _box_field_2::TEXT;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET box_field = _box_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET box_field = _box_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле BOX. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _path_field_2 := ('((' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '))')::PATH;
        EXIT WHEN _path_field_1::TEXT != _path_field_2::TEXT;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET path_field = _path_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET path_field = _path_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле PATH. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _polygon_field_2 := ('((' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '))')::POLYGON;
        EXIT WHEN _polygon_field_1::TEXT != _polygon_field_2::TEXT;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET polygon_field = _polygon_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET polygon_field = _polygon_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле POLYGON. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _circle_field_2 := ('<(' || random_int(1, 9)::TEXT || ',' || random_int(1, 9)::TEXT || '),' || random_int(1, 9)::TEXT || '>')::CIRCLE;
        EXIT WHEN _circle_field_1 != _circle_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET circle_field = _circle_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET circle_field = _circle_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле CIRCLE. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _tsquery_field_2 := (random_string(10) || ' & ' || random_string(10))::TSQUERY;
        EXIT WHEN _tsquery_field_1 != _tsquery_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET tsquery_field = _tsquery_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET tsquery_field = _tsquery_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле TSQUERY. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    WHILE TRUE LOOP
        _tsvector_field_2 := (random_string(60))::TSVECTOR;
        EXIT WHEN _tsvector_field_1 != _tsvector_field_2;
    END LOOP;
    hash_sum_1 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET tsvector_field = _tsvector_field_2;
    hash_sum_2 := get_table_hash_sum(table_name);
    UPDATE test_all_types_table SET tsvector_field = _tsvector_field_1;
    hash_sum_3 := get_table_hash_sum(table_name);
    RAISE NOTICE 'Поле TSVECTOR. Изначальная хеш сумма равна конечной: %; Хеш сумма после UPDATE не равна изначальной: %; Изначальная хеш сумма: %; После UPDATE: %; Конечная: %', hash_sum_1 = hash_sum_3, hash_sum_1 != hash_sum_2, hash_sum_1, hash_sum_2, hash_sum_3;

    CALL delete_test_all_types_table(table_name);
END;
$$;


ROLLBACK;
