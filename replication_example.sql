-- Рабочая таблица
CREATE TABLE IF NOT EXISTS work_table (
    id BIGSERIAL PRIMARY KEY,
    int_field INTEGER,
    text_field TEXT,
    date_field TIMESTAMPTZ DEFAULT now()
);


CREATE SCHEMA IF NOT EXISTS replication;


-- Таблица-копия рабочей таблицы work_table
CREATE TABLE IF NOT EXISTS replication.repl_work_table AS
    SELECT id, int_field, text_field, date_field FROM work_table WHERE FALSE;

ALTER TABLE replication.repl_work_table ADD COLUMN IF NOT EXISTS __unique_id BIGSERIAL PRIMARY KEY;

-- Очередь репликации
CREATE TABLE IF NOT EXISTS replication.replication_queue (
    id BIGSERIAL PRIMARY KEY,
    virtual_transaction_id BIGINT DEFAULT txid_current(),
    date TIMESTAMPTZ DEFAULT now(),
    table_name TEXT,
    repl_unique_id BIGINT,
    change_type CHAR(1) -- 'I' для вставок, 'U' для обновлений, 'D' для удалений
)


CREATE OR REPLACE FUNCTION save_replication_work_table_create()
    RETURNS TRIGGER
    LANGUAGE plpgsql AS $$
DECLARE
    repl_unique_id BIGINT;
BEGIN
    INSERT INTO replication.repl_work_table (id, int_field, text_field, date_field)
        VALUES (NEW.id, NEW.int_field, NEW.text_field, NEW.date_field)
        RETURNING __unique_id INTO repl_unique_id;

    INSERT INTO replication.replication_queue (table_name, repl_unique_id, change_type)
        VALUES ('work_table', repl_unique_id, 'I');

    RETURN NEW;
END
$$;


CREATE OR REPLACE FUNCTION save_replication_work_table_update()
    RETURNS TRIGGER
    LANGUAGE plpgsql AS $$
DECLARE
    repl_unique_id BIGINT;
BEGIN
    IF (OLD = NEW) THEN
        RETURN NEW;
    END IF;

    INSERT INTO replication.repl_work_table (id, int_field, text_field, date_field)
        VALUES (NEW.id, NEW.int_field, NEW.text_field, NEW.date_field)
        RETURNING __unique_id INTO repl_unique_id;

    INSERT INTO replication.replication_queue (table_name, repl_unique_id, change_type)
        VALUES ('work_table', repl_unique_id, 'U');

    RETURN NEW;
END
$$;


CREATE OR REPLACE FUNCTION save_replication_work_table_delete()
    RETURNS TRIGGER
    LANGUAGE plpgsql AS $$
DECLARE
    repl_unique_id BIGINT;
BEGIN
    INSERT INTO replication.repl_work_table (id, int_field, text_field, date_field)
        VALUES (OLD.id, OLD.int_field, OLD.text_field, OLD.date_field)
        RETURNING __unique_id INTO repl_unique_id;

    INSERT INTO replication.replication_queue (table_name, repl_unique_id, change_type)
        VALUES ('work_table', repl_unique_id, 'D');

    RETURN OLD;
END
$$;


CREATE OR REPLACE TRIGGER save_replication_work_table_create_trigger
    BEFORE INSERT
    ON work_table
    FOR EACH ROW
    EXECUTE FUNCTION save_replication_work_table_create();

CREATE OR REPLACE TRIGGER save_replication_work_table_update_trigger
    BEFORE UPDATE
    ON work_table
    FOR EACH ROW
    EXECUTE FUNCTION save_replication_work_table_update();

CREATE OR REPLACE TRIGGER save_replication_work_table_delete_trigger
    AFTER DELETE
    ON work_table
    FOR EACH ROW
    EXECUTE FUNCTION save_replication_work_table_delete();


-- Тесты


START TRANSACTION;
DO
$$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    N INT = 1000000;
BEGIN
    RAISE NOTICE 'Тест 1. Время выполнения % INSERT без триггеров', n;
    ALTER TABLE work_table DISABLE TRIGGER save_replication_work_table_create_trigger;
    ALTER TABLE work_table DISABLE TRIGGER save_replication_work_table_update_trigger;
    ALTER TABLE work_table DISABLE TRIGGER save_replication_work_table_delete_trigger;

    start_time := clock_timestamp();
    INSERT INTO work_table (int_field, text_field)
        SELECT i, i FROM generate_series(1, n) AS i;
    end_time := clock_timestamp();

    RAISE NOTICE 'Время: %', end_time - start_time;
END
$$;
ROLLBACK;


START TRANSACTION;
DO
$$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    N INT = 1000000;
BEGIN
    RAISE NOTICE 'Тест 2. Время выполнения % INSERT с триггерами', n;
    ALTER TABLE work_table ENABLE TRIGGER save_replication_work_table_create_trigger;
    ALTER TABLE work_table ENABLE TRIGGER save_replication_work_table_update_trigger;
    ALTER TABLE work_table ENABLE TRIGGER save_replication_work_table_delete_trigger;

    start_time := clock_timestamp();
    INSERT INTO work_table (int_field, text_field)
        SELECT i, i FROM generate_series(1, n) AS i;
    end_time := clock_timestamp();

    RAISE NOTICE 'Время: %', end_time - start_time;
END
$$;
ROLLBACK;


START TRANSACTION;
DO
$$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    N INT = 1000000;
BEGIN
    RAISE NOTICE 'Тест 3. Время выполнения % UPDATE без триггеров', n;
    ALTER TABLE work_table DISABLE TRIGGER save_replication_work_table_create_trigger;
    ALTER TABLE work_table DISABLE TRIGGER save_replication_work_table_update_trigger;
    ALTER TABLE work_table DISABLE TRIGGER save_replication_work_table_delete_trigger;

    INSERT INTO work_table (int_field, text_field)
        SELECT i, i FROM generate_series(1, n) AS i;

    start_time := clock_timestamp();
    UPDATE work_table SET int_field = 0, text_field = '0', date_field = now();
    end_time := clock_timestamp();

    RAISE NOTICE 'Время: %', end_time - start_time;
END
$$;
ROLLBACK;


START TRANSACTION;
DO
$$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    N INT = 1000000;
BEGIN
    RAISE NOTICE 'Тест 4. Время выполнения % UPDATE с триггерами', n;
    ALTER TABLE work_table ENABLE TRIGGER save_replication_work_table_create_trigger;
    ALTER TABLE work_table ENABLE TRIGGER save_replication_work_table_update_trigger;
    ALTER TABLE work_table ENABLE TRIGGER save_replication_work_table_delete_trigger;

    INSERT INTO work_table (int_field, text_field)
        SELECT i, i FROM generate_series(1, n) AS i;

    start_time := clock_timestamp();
    UPDATE work_table SET int_field = 0, text_field = '0', date_field = now();
    end_time := clock_timestamp();

    RAISE NOTICE 'Время: %', end_time - start_time;
END
$$;
ROLLBACK;


START TRANSACTION;
DO
$$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    N INT = 1000000;
BEGIN
    RAISE NOTICE 'Тест 5. Время выполнения % DELETE без триггеров', n;
    ALTER TABLE work_table DISABLE TRIGGER save_replication_work_table_create_trigger;
    ALTER TABLE work_table DISABLE TRIGGER save_replication_work_table_update_trigger;
    ALTER TABLE work_table DISABLE TRIGGER save_replication_work_table_delete_trigger;

    INSERT INTO work_table (int_field, text_field)
        SELECT i, i FROM generate_series(1, n) AS i;

    start_time := clock_timestamp();
    DELETE FROM work_table;
    end_time := clock_timestamp();

    RAISE NOTICE 'Время: %', end_time - start_time;
END
$$;
ROLLBACK;


START TRANSACTION;
DO
$$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    N INT = 1000000;
BEGIN
    RAISE NOTICE 'Тест 6. Время выполнения % DELETE с триггерами', n;
    ALTER TABLE work_table ENABLE TRIGGER save_replication_work_table_create_trigger;
    ALTER TABLE work_table ENABLE TRIGGER save_replication_work_table_update_trigger;
    ALTER TABLE work_table ENABLE TRIGGER save_replication_work_table_delete_trigger;

    INSERT INTO work_table (int_field, text_field)
        SELECT i, i FROM generate_series(1, n) AS i;

    start_time := clock_timestamp();
    DELETE FROM work_table;
    end_time := clock_timestamp();

    RAISE NOTICE 'Время: %', end_time - start_time;
END
$$;
ROLLBACK;
