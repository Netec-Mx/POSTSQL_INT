
DO $$
DECLARE
    temp_saldo_1 NUMERIC;
BEGIN

    UPDATE cuentas
    SET saldo = saldo - 100
    WHERE id_cuenta = 1
    RETURNING saldo INTO temp_saldo_1;

    IF temp_saldo_1 < 0 THEN
        RAISE EXCEPTION 'Saldo insuficiente en la cuenta 1';
    END IF;

    UPDATE cuentas
    SET saldo = saldo + 100
    WHERE id_cuenta = 2;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error detectado: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

