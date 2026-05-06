CREATE OR REPLACE FUNCTION _hash_sum_col_transformation(_column_name TEXT, data_type TEXT)
    RETURNS TEXT
    LANGUAGE sql AS $$
 -- преобразование значения поля в зависимости от типа поля для расчёта хеш суммы
    SELECT CASE
        WHEN data_type = 'text' THEN
            _column_name
        ELSE
            format('%1$s::TEXT', _column_name)
    END
$$;


CREATE OR REPLACE FUNCTION get_table_hash_sum(
    _table_name TEXT  -- название таблицы
)
    RETURNS BIGINT
    LANGUAGE plpgsql AS $$
 -- возвращает хеш сумму таблицы
DECLARE
    hash_sum_fields TEXT[];  -- итоговые аргументы таблицы для расчёта хеш суммы
    max_format_args INT = 99;  -- 100 - максимальное количество аргументов функции format минус 1 на основную строку
    hash_sum BIGINT;
BEGIN
    SELECT ARRAY(
        SELECT
            CASE
                WHEN is_nullable = 'YES' THEN
                    format(  -- добавляется приведение к строке значения null, если допустимо для данного поля
                        $str$coalesce(%s, 'NULL')$str$,
                        _hash_sum_col_transformation(column_name, data_type)
                    )
                ELSE _hash_sum_col_transformation(column_name, data_type)
            END
            FROM information_schema.columns
            WHERE table_name = _table_name
            ORDER BY column_name
    ) INTO hash_sum_fields;

    -- в начало массива добавляется название текущей таблицы
    hash_sum_fields := array_prepend(format($str$'%s'$str$, _table_name), hash_sum_fields);

    -- массив hash_sum_fields сворачивается в функцию format с учётом ограничения на максимальное количество аргументов у функции format
    WHILE array_length(hash_sum_fields, 1) > 1 LOOP
        SELECT ARRAY(
            SELECT CASE
                WHEN array_length(hash_sum_fields[(i):(i+max_format_args-1)], 1) > 1 THEN
                    format(
                        $str$format('%s', %s)$str$,
                        substr(repeat('|%s', array_length(hash_sum_fields[(i):(i+max_format_args-1)], 1)), 2), array_to_string(hash_sum_fields[(i):(i+max_format_args-1)], ', ')
                    )
                ELSE
                    hash_sum_fields[i]
                END
                FROM generate_series(1, array_length(hash_sum_fields, 1), max_format_args) AS i
        ) INTO hash_sum_fields;
    END LOOP;

    EXECUTE format($func$
        SELECT COALESCE(MOD(SUM(hashtextextended(%1$s, 0)), 1000000000000000000), 0) FROM %2$s
    $func$, hash_sum_fields[1], _table_name) INTO hash_sum;
    RETURN hash_sum;
END
$$;


