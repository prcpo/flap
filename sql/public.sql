SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET search_path = public, pg_catalog;
CREATE FUNCTION company() RETURNS uuid
    LANGUAGE sql SECURITY DEFINER
    AS $$select def.company_get();$$;
COMMENT ON FUNCTION company() IS 'Возвращает uuid организации, для которой ведётся учёт. ';
CREATE FUNCTION company(uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$begin
	PERFORM def.company_set(COALESCE($1,uuid_null()));
	return company();
end;$_$;
COMMENT ON FUNCTION company(uuid) IS 'Устанавливает организацию, для которой ведётся учёт. 
Возвращает uuid организации.';
CREATE FUNCTION setting(text) RETURNS text
    LANGUAGE sql SECURITY DEFINER
    AS $_$select set.get($1::ltree)$_$;
COMMENT ON FUNCTION setting(text) IS 'Возвращает значение пользовательской переменой.
Параметр - код переменной из def.settings
Возвращаемое значение - текст.';
CREATE FUNCTION setting(text, anyelement) RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    AS $_$select set.set($1::ltree, $2::text)$_$;
COMMENT ON FUNCTION setting(text, anyelement) IS 'Устанавливает значение пользовательской переменой.
Первый параметр - код переменной из def.settings
Второй - значение. Значение может быть любого типа, оно автоматически преобразуется в текст.
Возвращает TRUE, если успешно. Иначе - FALSE.';
CREATE FUNCTION tfc_companies() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$begin
	NEW.uuid = sec.company_add(NEW.code, TRUE);
	select code from sec.companies where uuid = NEW.uuid
	into NEW.code;
	return NEW;
end;$$;
CREATE FUNCTION tfc_settings() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$begin
	-- Менять код параметра запрещено
	NEW.code = OLD.code;
	if set.set(OLD.code, NEW.val) then
		return NEW;
	else
		RAISE NOTICE 'Значение % не бы установлено.', NEW.val;
		return NULL;
	end if;
end;$$;
COMMENT ON FUNCTION tfc_settings() IS 'Изменяет настройки пользователя';
CREATE VIEW companies AS
    SELECT companies.uuid, companies.code FROM sec.companies, sec.users WHERE ((users.company = companies.uuid) AND (users.user_name = ("session_user"())::text));
COMMENT ON VIEW companies IS 'Список организаций, для которых ведётся учёт';
CREATE VIEW objects AS
    SELECT raw.uuid, raw.data FROM obj.raw WHERE (raw.comp = company());
COMMENT ON VIEW objects IS 'Объекты системы';
CREATE VIEW settings AS
    SELECT d.code, COALESCE(s.val, d.default_value) AS val FROM (def.settings d LEFT JOIN set.user_settings s ON ((s.code OPERATOR(ext.=) d.code)));
COMMENT ON VIEW settings IS 'Значения переменных';
CREATE TRIGGER tiu_companies INSTEAD OF INSERT ON companies FOR EACH ROW EXECUTE PROCEDURE tfc_companies();
CREATE TRIGGER tiu_settings INSTEAD OF UPDATE ON settings FOR EACH ROW EXECUTE PROCEDURE tfc_settings();
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
REVOKE ALL ON FUNCTION setting(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION setting(text) FROM admin;
GRANT ALL ON FUNCTION setting(text) TO admin;
GRANT ALL ON FUNCTION setting(text) TO PUBLIC;
GRANT ALL ON FUNCTION setting(text) TO accuser;
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
