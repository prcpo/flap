SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET search_path = public, pg_catalog;
CREATE FUNCTION setting(text, text) RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    AS $_$insert into settings (code, val) values ($1::ltree, $2::text) returning true;$_$;
COMMENT ON FUNCTION setting(text, text) IS 'Устанавливает значение пользовательской переменой.
Первый параметр - код переменной из def.settings
Второй - значение. 
Возвращает TRUE, если успешно. Иначе - FALSE.';
CREATE FUNCTION work_date() RETURNS date
    LANGUAGE sql
    AS $$select tools.work_date();
$$;
COMMENT ON FUNCTION work_date() IS 'Возвращает рабочую дату';
CREATE FUNCTION setting(_code text, _dt date DEFAULT work_date()) RETURNS text
    LANGUAGE sql
    AS $_$select calculate(val, $2)::text
	from set.settings_h
	where code = $1::ltree and period @> $2;$_$;
COMMENT ON FUNCTION setting(_code text, _dt date) IS 'Возвращает значение переменной на указанную дату.
Певый параметр - код переменной из def.settings
Второй - дата. Если отсутсвует, то будет использована расчётная дата.
Возвращаемое значение - текст.';
CREATE FUNCTION shortname(_fullname text) RETURNS text
    LANGUAGE sql
    AS $_$select COALESCE(_fullname, $1);$_$;
COMMENT ON FUNCTION shortname(_fullname text) IS 'Вычисляет фамилию и инициалы пользователя';
CREATE FUNCTION tfc_companies() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$begin
	if (TG_OP = 'DELETE') then
		delete from sec.users 
		where user_name = session_user 
		and company = OLD.uuid;
		IF NOT FOUND THEN RETURN NULL; end if;
		RETURN OLD;
	else
		if (TG_OP = 'UPDATE') then
			if not (NEW.uuid = OLD.uuid) then 
				raise notice 'Менять UUID запрещено';
				NEW.uuid = OLD.uuid;
			end if;
			update sec.companies set code = NEW.code where uuid = OLD.uuid;
			IF NOT FOUND THEN RETURN NULL; END IF;
		ELSE -- INSERT
			NEW.uuid = sec.company_add(NEW.code, TRUE);
		end if;
		select code from sec.companies where uuid = NEW.uuid
		into NEW.code;
		return NEW;
	end if;
end;$$;
COMMENT ON FUNCTION tfc_companies() IS 'Изменяет перечень организаций учёта';
CREATE FUNCTION tfc_settings() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$begin
	if (TG_OP = 'DELETE') then
		perform set.set(OLD.code, NULL);
		return OLD;
	else
		if (TG_OP = 'UPDATE') then
			if not (NEW.code = OLD.code) then 
				raise notice 'Менять код параметра запрещено';
				NEW.code = OLD.code;
			end if;
		end if;
		perform set.set(NEW.code, NEW.val);
		return NEW;
	end if;
end;$$;
COMMENT ON FUNCTION tfc_settings() IS 'Изменяет структуру реквизитов объектов';
CREATE VIEW companies AS
    SELECT companies.uuid, companies.code FROM sec.companies, sec.users WHERE ((users.company = companies.uuid) AND (users.user_name = ("session_user"())::text));
COMMENT ON VIEW companies IS 'Список организаций, для которых ведётся учёт.
Наименование организации дублируется в пользовательской переменной.';
CREATE VIEW otypes AS
    SELECT types.code FROM def.types WHERE (types.code OPERATOR(ext.~) 'dic|doc.*'::ext.lquery);
CREATE VIEW tap_funky AS
    SELECT p.oid, n.nspname AS schema, p.proname AS name, array_to_string((p.proargtypes)::regtype[], ','::text) AS args, (CASE p.proretset WHEN true THEN 'setof '::text ELSE ''::text END || (p.prorettype)::regtype) AS returns, p.prolang AS langoid, p.proisstrict AS is_strict, p.proisagg AS is_agg, p.prosecdef AS is_definer, p.proretset AS returns_set, (p.provolatile)::character(1) AS volatility, pg_function_is_visible(p.oid) AS is_visible FROM (pg_proc p JOIN pg_namespace n ON ((p.pronamespace = n.oid)));
CREATE VIEW types AS
    SELECT types.code FROM def.types WHERE ((types.code OPERATOR(ext.~) 'dic|doc|fld.*'::ext.lquery) AND (ext.nlevel(types.code) > 1));
COMMENT ON VIEW types IS 'Типы объектов системы';
CREATE TRIGGER tiud_companies INSTEAD OF INSERT OR DELETE OR UPDATE ON companies FOR EACH ROW EXECUTE PROCEDURE tfc_companies();
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
REVOKE ALL ON FUNCTION setting(text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION setting(text, text) FROM admin;
GRANT ALL ON FUNCTION setting(text, text) TO admin;
GRANT ALL ON FUNCTION setting(text, text) TO PUBLIC;
GRANT ALL ON FUNCTION setting(text, text) TO accuser;
REVOKE ALL ON FUNCTION tfc_companies() FROM PUBLIC;
REVOKE ALL ON FUNCTION tfc_companies() FROM admin;
GRANT ALL ON FUNCTION tfc_companies() TO admin;
GRANT ALL ON FUNCTION tfc_companies() TO PUBLIC;
GRANT ALL ON FUNCTION tfc_companies() TO accuser;
REVOKE ALL ON FUNCTION tfc_settings() FROM PUBLIC;
REVOKE ALL ON FUNCTION tfc_settings() FROM admin;
GRANT ALL ON FUNCTION tfc_settings() TO admin;
GRANT ALL ON FUNCTION tfc_settings() TO PUBLIC;
GRANT ALL ON FUNCTION tfc_settings() TO accuser;
REVOKE ALL ON TABLE companies FROM PUBLIC;
REVOKE ALL ON TABLE companies FROM admin;
GRANT ALL ON TABLE companies TO admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE companies TO accuser;
