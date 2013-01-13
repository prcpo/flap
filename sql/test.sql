--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.2
-- Dumped by pg_dump version 9.2.2
-- Started on 2013-01-13 20:26:34 NOVT

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 10 (class 2615 OID 19257)
-- Name: test; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA test;


--
-- TOC entry 2170 (class 0 OID 0)
-- Dependencies: 10
-- Name: SCHEMA test; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA test IS 'Тесты';


SET search_path = test, pg_catalog;

--
-- TOC entry 278 (class 1255 OID 19258)
-- Name: do(ext.lquery, boolean); Type: FUNCTION; Schema: test; Owner: -
--

CREATE FUNCTION "do"(_lquery ext.lquery, _erase_results boolean DEFAULT true) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$declare
  _res boolean array;
begin
  if _erase_results then 
		delete from test.results;
	end if;
	select array (
		select test.do_test(tree) from test.tests where tree ~ $1
		) into _res;
	return true;
end;$_$;


--
-- TOC entry 2171 (class 0 OID 0)
-- Dependencies: 278
-- Name: FUNCTION "do"(_lquery ext.lquery, _erase_results boolean); Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON FUNCTION "do"(_lquery ext.lquery, _erase_results boolean) IS 'Запускает все тесты по маске';


--
-- TOC entry 279 (class 1255 OID 19259)
-- Name: do_test(ext.ltree); Type: FUNCTION; Schema: test; Owner: -
--

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
-- проверяем, есть ли такой тест	
	insert into test.results (dt, test)
		values (_tm_b, _code);
	select command, result from test.tests where tree = _code into _command, _estimate;
-- если теста нет, пишем сообщение
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


--
-- TOC entry 280 (class 1255 OID 19260)
-- Name: execute_statement(text); Type: FUNCTION; Schema: test; Owner: -
--

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


--
-- TOC entry 2172 (class 0 OID 0)
-- Dependencies: 280
-- Name: FUNCTION execute_statement(_statement text, OUT _res text, OUT _err text); Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON FUNCTION execute_statement(_statement text, OUT _res text, OUT _err text) IS 'Пытается выполнить команду';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 176 (class 1259 OID 19261)
-- Name: results; Type: TABLE; Schema: test; Owner: -; Tablespace: 
--

CREATE TABLE results (
    dt timestamp with time zone DEFAULT now() NOT NULL,
    test ext.ltree NOT NULL,
    result text,
    notes text,
    passed boolean,
    ms double precision,
    tm timestamp with time zone
);


--
-- TOC entry 2173 (class 0 OID 0)
-- Dependencies: 176
-- Name: TABLE results; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON TABLE results IS 'Результаты тестов';


--
-- TOC entry 2174 (class 0 OID 0)
-- Dependencies: 176
-- Name: COLUMN results.dt; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN results.dt IS 'Дата и время теста';


--
-- TOC entry 2175 (class 0 OID 0)
-- Dependencies: 176
-- Name: COLUMN results.test; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN results.test IS 'Код теста';


--
-- TOC entry 2176 (class 0 OID 0)
-- Dependencies: 176
-- Name: COLUMN results.result; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN results.result IS 'Результат выполнения теста';


--
-- TOC entry 2177 (class 0 OID 0)
-- Dependencies: 176
-- Name: COLUMN results.notes; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN results.notes IS 'Примечания, вывод сообщений об ошибках';


--
-- TOC entry 2178 (class 0 OID 0)
-- Dependencies: 176
-- Name: COLUMN results.passed; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN results.passed IS 'Тест пройден успешно';


--
-- TOC entry 2179 (class 0 OID 0)
-- Dependencies: 176
-- Name: COLUMN results.ms; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN results.ms IS 'Время выполнения запроса, мс.';


--
-- TOC entry 177 (class 1259 OID 19268)
-- Name: tests; Type: TABLE; Schema: test; Owner: -; Tablespace: 
--

CREATE TABLE tests (
    tree ext.ltree NOT NULL,
    command text NOT NULL,
    result text
);


--
-- TOC entry 2180 (class 0 OID 0)
-- Dependencies: 177
-- Name: TABLE tests; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON TABLE tests IS 'Тесты';


--
-- TOC entry 2181 (class 0 OID 0)
-- Dependencies: 177
-- Name: COLUMN tests.tree; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN tests.tree IS 'Код теста';


--
-- TOC entry 2182 (class 0 OID 0)
-- Dependencies: 177
-- Name: COLUMN tests.command; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN tests.command IS 'Команда';


--
-- TOC entry 2183 (class 0 OID 0)
-- Dependencies: 177
-- Name: COLUMN tests.result; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN tests.result IS 'Ожидаемый результат';


--
-- TOC entry 2164 (class 0 OID 19261)
-- Dependencies: 176
-- Data for Name: results; Type: TABLE DATA; Schema: test; Owner: -
--



--
-- TOC entry 2165 (class 0 OID 19268)
-- Dependencies: 177
-- Data for Name: tests; Type: TABLE DATA; Schema: test; Owner: -
--

INSERT INTO tests (tree, command, result) VALUES ('sec.010.company_add', 'sec.company_add(''<<<test company>>>'')::text || ''''', '');


--
-- TOC entry 2161 (class 2606 OID 19275)
-- Name: pk_results; Type: CONSTRAINT; Schema: test; Owner: -; Tablespace: 
--

ALTER TABLE ONLY results
    ADD CONSTRAINT pk_results PRIMARY KEY (dt, test);


--
-- TOC entry 2163 (class 2606 OID 19277)
-- Name: pk_tests; Type: CONSTRAINT; Schema: test; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tests
    ADD CONSTRAINT pk_tests PRIMARY KEY (tree);


-- Completed on 2013-01-13 20:26:34 NOVT

--
-- PostgreSQL database dump complete
--

