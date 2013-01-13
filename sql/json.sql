SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA json;
COMMENT ON SCHEMA json IS 'Функции для работы с JSON';
SET search_path = json, pg_catalog;
CREATE FUNCTION element(text, anyelement) RETURNS text
    LANGUAGE sql
    AS $_$select '"' || $1 || '": ' || json.value($2);$_$;
CREATE FUNCTION elements(VARIADIC text[]) RETURNS text
    LANGUAGE sql
    AS $_$select json.get($1)$_$;
CREATE FUNCTION get(anyarray) RETURNS text
    LANGUAGE sql
    AS $_$select '{' || array_to_string($1, ', ') || '}'$_$;
CREATE FUNCTION value(text) RETURNS text
    LANGUAGE sql
    AS $_$select regexp_replace($1,'^([^\{]*[^\}])$',E'"\\1"','g')$_$;
CREATE FUNCTION value(integer) RETURNS text
    LANGUAGE sql
    AS $_$select $1::text$_$;
CREATE FUNCTION value(boolean) RETURNS text
    LANGUAGE sql
    AS $_$select $1::text$_$;
