--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.1
-- Dumped by pg_dump version 9.2.1
-- Started on 2012-11-23 11:51:42 OMST

SET statement_timeout = 0;
--SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 11 (class 2615 OID 25709)
-- Name: json; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA json;


--
-- TOC entry 2134 (class 0 OID 0)
-- Dependencies: 11
-- Name: SCHEMA json; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA json IS 'Функции для работы с JSON';


SET search_path = json, pg_catalog;

--
-- TOC entry 274 (class 1255 OID 25710)
-- Name: element(text, anyelement); Type: FUNCTION; Schema: json; Owner: -
--

CREATE FUNCTION element(text, anyelement) RETURNS text
    LANGUAGE sql
    AS $_$select '"' || $1 || '": ' || json.value($2);$_$;


--
-- TOC entry 269 (class 1255 OID 25713)
-- Name: elements(text[]); Type: FUNCTION; Schema: json; Owner: -
--

CREATE FUNCTION elements(VARIADIC text[]) RETURNS text
    LANGUAGE sql
    AS $_$select json.get($1)$_$;


--
-- TOC entry 275 (class 1255 OID 25712)
-- Name: get(anyarray); Type: FUNCTION; Schema: json; Owner: -
--

CREATE FUNCTION get(anyarray) RETURNS text
    LANGUAGE sql
    AS $_$select '{' || array_to_string($1, ', ') || '}'$_$;


--
-- TOC entry 270 (class 1255 OID 25714)
-- Name: value(text); Type: FUNCTION; Schema: json; Owner: -
--

CREATE FUNCTION value(text) RETURNS text
    LANGUAGE sql
    AS $_$select regexp_replace($1,'^([^\{]*[^\}])$',E'"\\1"','g')$_$;


--
-- TOC entry 271 (class 1255 OID 25715)
-- Name: value(integer); Type: FUNCTION; Schema: json; Owner: -
--

CREATE FUNCTION value(integer) RETURNS text
    LANGUAGE sql
    AS $_$select $1::text$_$;


--
-- TOC entry 276 (class 1255 OID 25716)
-- Name: value(boolean); Type: FUNCTION; Schema: json; Owner: -
--

CREATE FUNCTION value(boolean) RETURNS text
    LANGUAGE sql
    AS $_$select $1::text$_$;


-- Completed on 2012-11-23 11:51:42 OMST

--
-- PostgreSQL database dump complete
--

