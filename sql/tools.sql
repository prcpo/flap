SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA tools;
COMMENT ON SCHEMA tools IS 'Всякие нужные функции';
SET search_path = tools, pg_catalog;
CREATE FUNCTION iif(_condition boolean, _res1 anyelement, _res2 anyelement) RETURNS anyelement
    LANGUAGE sql
    AS $$select 
	case 
		when _condition
		then _res1
		else _res2 
	END;$$;
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
COMMENT ON FUNCTION uuid_generate_v4() IS 'Генерирует новый UUID';
CREATE FUNCTION uuid_null() RETURNS uuid
    LANGUAGE sql
    AS $$
  select '00000000-0000-0000-0000-000000000000'::uuid
$$;
COMMENT ON FUNCTION uuid_null() IS 'Возвращает нулевой UUID';
