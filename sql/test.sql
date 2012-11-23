--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.1
-- Dumped by pg_dump version 9.2.1
-- Started on 2012-11-23 12:02:11 OMST

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 10 (class 2615 OID 25642)
-- Name: test; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA test;


--
-- TOC entry 2143 (class 0 OID 0)
-- Dependencies: 10
-- Name: SCHEMA test; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA test IS 'Тесты';


SET search_path = test, pg_catalog;

--
-- TOC entry 272 (class 1255 OID 25686)
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
-- TOC entry 2144 (class 0 OID 0)
-- Dependencies: 272
-- Name: FUNCTION "do"(_lquery ext.lquery, _erase_results boolean); Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON FUNCTION "do"(_lquery ext.lquery, _erase_results boolean) IS 'Запускает все тесты по маске';


--
-- TOC entry 268 (class 1255 OID 25683)
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
-- TOC entry 267 (class 1255 OID 25679)
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
-- TOC entry 2145 (class 0 OID 0)
-- Dependencies: 267
-- Name: FUNCTION execute_statement(_statement text, OUT _res text, OUT _err text); Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON FUNCTION execute_statement(_statement text, OUT _res text, OUT _err text) IS 'Пытается выполнить команду';


SET default_with_oids = false;

--
-- TOC entry 176 (class 1259 OID 25651)
-- Name: results; Type: TABLE; Schema: test; Owner: -
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
-- TOC entry 2146 (class 0 OID 0)
-- Dependencies: 176
-- Name: TABLE results; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON TABLE results IS 'Результаты тестов';


--
-- TOC entry 2147 (class 0 OID 0)
-- Dependencies: 176
-- Name: COLUMN results.dt; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN results.dt IS 'Дата и время теста';


--
-- TOC entry 2148 (class 0 OID 0)
-- Dependencies: 176
-- Name: COLUMN results.test; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN results.test IS 'Код теста';


--
-- TOC entry 2149 (class 0 OID 0)
-- Dependencies: 176
-- Name: COLUMN results.result; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN results.result IS 'Результат выполнения теста';


--
-- TOC entry 2150 (class 0 OID 0)
-- Dependencies: 176
-- Name: COLUMN results.notes; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN results.notes IS 'Примечания, вывод сообщений об ошибках';


--
-- TOC entry 2151 (class 0 OID 0)
-- Dependencies: 176
-- Name: COLUMN results.passed; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN results.passed IS 'Тест пройден успешно';


--
-- TOC entry 2152 (class 0 OID 0)
-- Dependencies: 176
-- Name: COLUMN results.ms; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN results.ms IS 'Время выполнения запроса, мс.';


--
-- TOC entry 175 (class 1259 OID 25643)
-- Name: tests; Type: TABLE; Schema: test; Owner: -
--

CREATE TABLE tests (
    tree ext.ltree NOT NULL,
    command text NOT NULL,
    result text
);


--
-- TOC entry 2153 (class 0 OID 0)
-- Dependencies: 175
-- Name: TABLE tests; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON TABLE tests IS 'Тесты';


--
-- TOC entry 2154 (class 0 OID 0)
-- Dependencies: 175
-- Name: COLUMN tests.tree; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN tests.tree IS 'Код теста';


--
-- TOC entry 2155 (class 0 OID 0)
-- Dependencies: 175
-- Name: COLUMN tests.command; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN tests.command IS 'Команда';


--
-- TOC entry 2156 (class 0 OID 0)
-- Dependencies: 175
-- Name: COLUMN tests.result; Type: COMMENT; Schema: test; Owner: -
--

COMMENT ON COLUMN tests.result IS 'Ожидаемый результат';


--
-- TOC entry 2138 (class 0 OID 25651)
-- Dependencies: 176
-- Data for Name: results; Type: TABLE DATA; Schema: test; Owner: -
--


--
-- TOC entry 2137 (class 0 OID 25643)
-- Dependencies: 175
-- Data for Name: tests; Type: TABLE DATA; Schema: test; Owner: -
--

INSERT INTO tests VALUES ('sec.010.company_add', 'sec.company_add(''<<<test company>>>'')::text || ''''', '');


--
-- TOC entry 2136 (class 2606 OID 25671)
-- Name: pk_results; Type: CONSTRAINT; Schema: test; Owner: -
--

ALTER TABLE ONLY results
    ADD CONSTRAINT pk_results PRIMARY KEY (dt, test);


--
-- TOC entry 2134 (class 2606 OID 25650)
-- Name: pk_tests; Type: CONSTRAINT; Schema: test; Owner: -
--

ALTER TABLE ONLY tests
    ADD CONSTRAINT pk_tests PRIMARY KEY (tree);


-- Completed on 2012-11-23 12:02:11 OMST

--
-- PostgreSQL database dump complete
--

