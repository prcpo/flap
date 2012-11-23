--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.1
-- Dumped by pg_dump version 9.2.1
-- Started on 2012-11-23 11:49:29 OMST

SET statement_timeout = 0;
--SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 8 (class 2615 OID 25598)
-- Name: tools; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tools;


--
-- TOC entry 2134 (class 0 OID 0)
-- Dependencies: 8
-- Name: SCHEMA tools; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA tools IS 'Всякие нужные функции';


SET search_path = tools, pg_catalog;

--
-- TOC entry 265 (class 1255 OID 25599)
-- Name: uuid_generate_v4(); Type: FUNCTION; Schema: tools; Owner: -
--

CREATE FUNCTION uuid_generate_v4() RETURNS uuid
    LANGUAGE sql
    AS $$
  select array_to_string(
    array (
      select
        case when (( idx = 8 ) or ( idx = 13 ) or ( idx = 18 ) or ( idx = 23 )) then
          '-'
        else
          substring( '0123456789abcdef' from (( random() * 15 )::int + 1 ) for 1 )
        end
      from
        generate_series( 0, 35 ) idx
    ), ''
  )::uuid
$$;


--
-- TOC entry 2135 (class 0 OID 0)
-- Dependencies: 265
-- Name: FUNCTION uuid_generate_v4(); Type: COMMENT; Schema: tools; Owner: -
--

COMMENT ON FUNCTION uuid_generate_v4() IS 'Генерирует новый UUID';


-- Completed on 2012-11-23 11:49:30 OMST

--
-- PostgreSQL database dump complete
--

