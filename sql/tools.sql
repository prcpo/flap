--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.2
-- Dumped by pg_dump version 9.2.2
-- Started on 2013-01-13 20:37:07 NOVT

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 9 (class 2615 OID 19255)
-- Name: tools; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tools;


--
-- TOC entry 2161 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA tools; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA tools IS 'Всякие нужные функции';


SET search_path = tools, pg_catalog;

--
-- TOC entry 289 (class 1255 OID 19393)
-- Name: iif(boolean, anyelement, anyelement); Type: FUNCTION; Schema: tools; Owner: -
--

CREATE FUNCTION iif(_condition boolean, _res1 anyelement, _res2 anyelement) RETURNS anyelement
    LANGUAGE sql
    AS $$select 
	case 
		when _condition
		then _res1
		else _res2 
	END;$$;


--
-- TOC entry 277 (class 1255 OID 19256)
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
-- TOC entry 2162 (class 0 OID 0)
-- Dependencies: 277
-- Name: FUNCTION uuid_generate_v4(); Type: COMMENT; Schema: tools; Owner: -
--

COMMENT ON FUNCTION uuid_generate_v4() IS 'Генерирует новый UUID';


--
-- TOC entry 290 (class 1255 OID 19394)
-- Name: uuid_null(); Type: FUNCTION; Schema: tools; Owner: -
--

CREATE FUNCTION uuid_null() RETURNS uuid
    LANGUAGE sql
    AS $$
  select '00000000-0000-0000-0000-000000000000'::uuid
$$;


--
-- TOC entry 2163 (class 0 OID 0)
-- Dependencies: 290
-- Name: FUNCTION uuid_null(); Type: COMMENT; Schema: tools; Owner: -
--

COMMENT ON FUNCTION uuid_null() IS 'Возвращает нулевой UUID';


-- Completed on 2013-01-13 20:37:07 NOVT

--
-- PostgreSQL database dump complete
--

