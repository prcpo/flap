SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA tools;
COMMENT ON SCHEMA tools IS 'Всякие нужные функции';
SET search_path = tools, pg_catalog;
CREATE FUNCTION execute_statement(_statement text, OUT _res text, OUT _err text) RETURNS record
    LANGUAGE plpgsql
    AS $$begin
  Raise notice 'Try: %', _statement;
	begin
		execute _statement into _res;
		Raise notice ' >: %', _res;
	EXCEPTION WHEN OTHERS THEN
		_err = COALESCE(_err,'') || SQLERRM;
		Raise notice ' error: %', _err;
	end;
end;$$;
COMMENT ON FUNCTION execute_statement(_statement text, OUT _res text, OUT _err text) IS 'Пытается выполнить команду';
CREATE FUNCTION iif(_condition boolean, _res1 anyelement, _res2 anyelement) RETURNS anyelement
    LANGUAGE sql
    AS $$select 
	case 
		when _condition
		then _res1
		else _res2 
	END;$$;
CREATE FUNCTION this_month(date DEFAULT public.work_date()) RETURNS daterange
    LANGUAGE sql
    AS $$select daterange(date_trunc('month',work_date())::date, 
	(date_trunc('month',work_date())+interval '1 month')::date);$$;
COMMENT ON FUNCTION this_month(date) IS 'Возвращает период дат, соответствуюущий календарному месяцу, в который входит параметр - дата.
Если дата не задана, используется рабочая дата.';
CREATE FUNCTION this_year(date DEFAULT public.work_date()) RETURNS daterange
    LANGUAGE sql
    AS $$select daterange(date_trunc('year',work_date())::date, 
	(date_trunc('year',work_date())+interval '1 year')::date);$$;
COMMENT ON FUNCTION this_year(date) IS 'Возвращает период дат, соответствуюущий календарному году, в который входит параметр - дата.
Если дата не задана, используется рабочая дата.';
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
REVOKE ALL ON SCHEMA tools FROM PUBLIC;
REVOKE ALL ON SCHEMA tools FROM admin;
GRANT ALL ON SCHEMA tools TO admin;
GRANT USAGE ON SCHEMA tools TO accuser;
REVOKE ALL ON FUNCTION iif(_condition boolean, _res1 anyelement, _res2 anyelement) FROM PUBLIC;
REVOKE ALL ON FUNCTION iif(_condition boolean, _res1 anyelement, _res2 anyelement) FROM admin;
GRANT ALL ON FUNCTION iif(_condition boolean, _res1 anyelement, _res2 anyelement) TO admin;
GRANT ALL ON FUNCTION iif(_condition boolean, _res1 anyelement, _res2 anyelement) TO PUBLIC;
GRANT ALL ON FUNCTION iif(_condition boolean, _res1 anyelement, _res2 anyelement) TO accuser;
REVOKE ALL ON FUNCTION uuid_generate_v4() FROM PUBLIC;
REVOKE ALL ON FUNCTION uuid_generate_v4() FROM admin;
GRANT ALL ON FUNCTION uuid_generate_v4() TO admin;
GRANT ALL ON FUNCTION uuid_generate_v4() TO PUBLIC;
GRANT ALL ON FUNCTION uuid_generate_v4() TO accuser;
REVOKE ALL ON FUNCTION uuid_null() FROM PUBLIC;
REVOKE ALL ON FUNCTION uuid_null() FROM admin;
GRANT ALL ON FUNCTION uuid_null() TO admin;
GRANT ALL ON FUNCTION uuid_null() TO PUBLIC;
GRANT ALL ON FUNCTION uuid_null() TO accuser;
