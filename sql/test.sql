SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA test;
COMMENT ON SCHEMA test IS 'Тесты';
SET search_path = test, pg_catalog;
CREATE FUNCTION "do"(_lquery ext.lquery, _erase_results boolean DEFAULT true) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$declare
  _res boolean array;
begin
  if _erase_results then 
		delete from test.results;
	end if;
	select array (
		select test.do_test(tree) from def.tests where tree ~ $1
		) into _res;
	return true;
end;$_$;
COMMENT ON FUNCTION "do"(_lquery ext.lquery, _erase_results boolean) IS 'Запускает все тесты по маске';
CREATE FUNCTION do_test(_code ext.ltree) RETURNS boolean
    LANGUAGE plpgsql
    AS $$declare
  _command text;
  _err text;
  _res text;
  _estimate text;
  _tm_b timestamp;
  _tm_e timestamp;
begin
	_res = null;
	_tm_b = now();
	_tm_e = _tm_b;
	insert into test.results (dt, test)
		values (_tm_b, _code);
	select command, result from def.tests where tree = _code into _command, _estimate;
	if _command is null then
		_err = 'Test "' || _code::text || '" is not found in table "test.tests"';
	ELSE
		begin
		  _tm_b = now();
			select * FROM test.execute_statement('select ' || _command) INTO _res, _err;
			_tm_e = now();
			raise notice '.res = %', _res;
			raise notice '.err = %', _err;
		EXCEPTION WHEN OTHERS THEN
			_err = SQLERRM;
		end;
	end if;
	update test.results
		set notes = _err,
		result = _res,
		ms = EXTRACT(MILLISECONDS FROM (_tm_e - _tm_b)),
		dt = _tm_b,
		tm = _tm_e,
		passed = (_res = _estimate)
		where dt = _tm_b
		and test::text = _code::text;
	RETURN _res = _estimate;
end;$$;
CREATE FUNCTION execute_statement(_statement text, OUT _res text, OUT _err text) RETURNS record
    LANGUAGE plpgsql
    AS $$begin
  Raise notice 'Try: %', _statement;
	begin
		execute _statement into _res;
		Raise notice ' >: %', _res;
	EXCEPTION WHEN OTHERS THEN
		_err = _err || SQLERRM;
		Raise notice ' error: %', _err;
	end;
end;$$;
COMMENT ON FUNCTION execute_statement(_statement text, OUT _res text, OUT _err text) IS 'Пытается выполнить команду';
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE results (
    dt timestamp with time zone DEFAULT now() NOT NULL,
    test ext.ltree NOT NULL,
    result text,
    notes text,
    passed boolean,
    ms double precision,
    tm timestamp with time zone
);
COMMENT ON TABLE results IS 'Результаты тестов';
COMMENT ON COLUMN results.dt IS 'Дата и время теста';
COMMENT ON COLUMN results.test IS 'Код теста';
COMMENT ON COLUMN results.result IS 'Результат выполнения теста';
COMMENT ON COLUMN results.notes IS 'Примечания, вывод сообщений об ошибках';
COMMENT ON COLUMN results.passed IS 'Тест пройден успешно';
COMMENT ON COLUMN results.ms IS 'Время выполнения запроса, мс.';
ALTER TABLE ONLY results
    ADD CONSTRAINT pk_results PRIMARY KEY (dt, test);
