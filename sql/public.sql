SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET search_path = public, pg_catalog;
CREATE FUNCTION calculate(_statement text) RETURNS text
    LANGUAGE plpgsql
    AS $$declare
	_res text;
begin
	execute 'select ' || _statement into _res;
	return _res::text;
end;$$;
COMMENT ON FUNCTION calculate(_statement text) IS 'Возвращает результат SQL выражения. 
SQL выражение задаётся без ключевого слова SELECT.
Результат приводится в текстовый формат.
SQL выражение не должно возвращать более одного значения. Дополнительные значения игнорируются.
Примеры:
date_trunc(''month'', now()) - возвращает дату начала текущего месяца
code FROM companies WHERE uuid = company() - кодовое название организации, для которой ведётся учёт
!!!!!!!!!!!!!!!!
НАДО: Добавить проверку параметра, чтобы исключить уязвимости типа "Robert''); DROP TABLE... "
';
CREATE FUNCTION company() RETURNS uuid
    LANGUAGE sql SECURITY DEFINER
    AS $$select set.company_get();$$;
COMMENT ON FUNCTION company() IS 'Возвращает uuid организации, для которой ведётся учёт. ';
CREATE FUNCTION company(uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$begin
	PERFORM set.company_set(COALESCE($1,uuid_null()));
	return company();
end;$_$;
COMMENT ON FUNCTION company(uuid) IS 'Устанавливает организацию, для которой ведётся учёт. 
Возвращает uuid организации.';
CREATE FUNCTION company_display() RETURNS text
    LANGUAGE sql
    AS $$select code from companies where uuid = company();$$;
COMMENT ON FUNCTION company_display() IS 'Возвращает понятное человеку кодовое имя организации, для которой ведётся учёт';
CREATE FUNCTION setting(text) RETURNS text
    LANGUAGE sql SECURITY DEFINER
    AS $_$select set.get($1::ltree)$_$;
COMMENT ON FUNCTION setting(text) IS 'Возвращает значение пользовательской переменой.
Параметр - код переменной из def.settings
Возвращаемое значение - текст.';
CREATE FUNCTION setting(text, anyelement) RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    AS $_$insert into settings (code, val) values ($1::ltree, $2::text) returning true;$_$;
COMMENT ON FUNCTION setting(text, anyelement) IS 'Устанавливает значение пользовательской переменой.
Первый параметр - код переменной из def.settings
Второй - значение. Значение может быть любого типа, оно автоматически преобразуется в текст.
Возвращает TRUE, если успешно. Иначе - FALSE.';
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
COMMENT ON FUNCTION tfc_settings() IS 'Изменяет настройки пользователя';
CREATE FUNCTION work_date() RETURNS date
    LANGUAGE plpgsql
    AS $$begin
	return set.get('work.date');
exception 
	when others then
		return now();
end;$$;
COMMENT ON FUNCTION work_date() IS 'Возвращает рабочую дату';
CREATE VIEW companies AS
    SELECT companies.uuid, companies.code FROM sec.companies, sec.users WHERE ((users.company = companies.uuid) AND (users.user_name = ("session_user"())::text));
COMMENT ON VIEW companies IS 'Список организаций, для которых ведётся учёт.
Наименование организации дублируется в пользовательской переменной.';
CREATE VIEW objects AS
    SELECT raw.uuid, raw.data FROM obj.raw WHERE (raw.comp = company());
COMMENT ON VIEW objects IS 'Объекты системы';
CREATE VIEW settings AS
    SELECT s.code, CASE WHEN (s.val ~~ '=%'::text) THEN calculate("substring"(s.val, 2)) ELSE s.val END AS val FROM (SELECT d.code, COALESCE(s.val, d.default_value) AS val FROM (def.settings d LEFT JOIN set.user_settings s ON ((s.code OPERATOR(ext.=) d.code)))) s;
COMMENT ON VIEW settings IS 'Значения переменных';
CREATE TRIGGER tiu_settings INSTEAD OF INSERT OR DELETE OR UPDATE ON settings FOR EACH ROW EXECUTE PROCEDURE tfc_settings();
CREATE TRIGGER tiud_companies INSTEAD OF INSERT OR DELETE OR UPDATE ON companies FOR EACH ROW EXECUTE PROCEDURE tfc_companies();
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
REVOKE ALL ON FUNCTION company() FROM PUBLIC;
REVOKE ALL ON FUNCTION company() FROM admin;
GRANT ALL ON FUNCTION company() TO admin;
GRANT ALL ON FUNCTION company() TO PUBLIC;
GRANT ALL ON FUNCTION company() TO accuser;
REVOKE ALL ON FUNCTION company(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION company(uuid) FROM admin;
GRANT ALL ON FUNCTION company(uuid) TO admin;
GRANT ALL ON FUNCTION company(uuid) TO PUBLIC;
GRANT ALL ON FUNCTION company(uuid) TO accuser;
REVOKE ALL ON FUNCTION setting(text, anyelement) FROM PUBLIC;
REVOKE ALL ON FUNCTION setting(text, anyelement) FROM admin;
GRANT ALL ON FUNCTION setting(text, anyelement) TO admin;
GRANT ALL ON FUNCTION setting(text, anyelement) TO PUBLIC;
GRANT ALL ON FUNCTION setting(text, anyelement) TO accuser;
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
REVOKE ALL ON TABLE objects FROM PUBLIC;
REVOKE ALL ON TABLE objects FROM admin;
GRANT ALL ON TABLE objects TO admin;
GRANT SELECT,INSERT,DELETE,TRIGGER,UPDATE ON TABLE objects TO accuser;
REVOKE ALL ON TABLE settings FROM PUBLIC;
REVOKE ALL ON TABLE settings FROM admin;
GRANT ALL ON TABLE settings TO admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE settings TO accuser;
