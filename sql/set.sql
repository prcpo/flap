SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA set;
COMMENT ON SCHEMA set IS 'Значения констант, параметров, настроек.';
SET search_path = set, pg_catalog;
CREATE FUNCTION get(_code ext.ltree) RETURNS text
    LANGUAGE plpgsql
    AS $$declare
	_res text;
begin
	select val from set.settings
		where code = _code
		and coalesce(company, uuid_null()) = coalesce(def.settings_company(_code), uuid_null())
		and coalesce("user",'') = coalesce(def.settings_user(_code), '')
		into _res;
	return _res;
end;$$;
COMMENT ON FUNCTION get(_code ext.ltree) IS 'Возвращает значение переменной';
CREATE FUNCTION set(_code ext.ltree, _value text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$declare
	_iscompany boolean;
	_isuser boolean;
	_ishistory boolean;
	_type	ltree;
	_tcode ltree;
begin
	select code, "type", isuser, iscompany, ishistory 
		from def.settings
		where code = _code
		into _tcode, _type, _isuser, _iscompany, _ishistory;
	if _code is null or _tcode is null then
		raise exception 'Отсутствует параметр с кодом %', _code;
		return false;
	end if;
	if _value is NULL then
		delete from set.settings
				where code = _code
				and coalesce(company, uuid_null()) = coalesce(def.settings_company(_code), uuid_null())
				and coalesce("user",'') = coalesce(def.settings_user(_code), '');
		IF NOT FOUND THEN RETURN true; END IF;
	else
		begin
			insert into set.settings (code, val)
			values (_code, _value);
		exception
			when unique_violation then
				update set.settings
				set val = _value
				where code = _code
				and coalesce(company, uuid_null()) = coalesce(def.settings_company(_code), uuid_null())
				and coalesce("user",'') = coalesce(def.settings_user(_code), '');
		end;
	end if;
	RETURN TRUE;
end;$$;
COMMENT ON FUNCTION set(_code ext.ltree, _value text) IS 'Устанавливает значение переменной.
Возвращает TRUE, если значение успешно установлено.
Если второй параметр NULL, то значение пользовательской настройки сбрасывается до значения по умолчанию.';
CREATE FUNCTION tfc_settings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$begin
	IF NEW.code IS NULL THEN
		RAISE EXCEPTION 'code cannot be null';
	END IF;
	NEW.company = def.settings_company(NEW.code);
	NEW.user = def.settings_user(NEW.code);
	if exists 
		(select 1 from set.settings
			where code = NEW.code
			and coalesce(company, uuid_null()) = coalesce(NEW.company, uuid_null())
			and coalesce("user",'') = coalesce(NEW.user, ''))
		then 
		raise exception unique_violation ;
		RETURN NULL;
	else
		RETURN NEW;
	end if;
end;$$;
COMMENT ON FUNCTION tfc_settings() IS 'Проверяет условия заполнения таблицы settings';
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE settings (
    code ext.ltree,
    company uuid,
    "user" text,
    val text
);
COMMENT ON TABLE settings IS 'Значения настроек';
COMMENT ON COLUMN settings.code IS 'Код настройки';
COMMENT ON COLUMN settings.company IS 'Организация';
COMMENT ON COLUMN settings."user" IS 'Пользователь';
COMMENT ON COLUMN settings.val IS 'Значение';
CREATE VIEW user_settings AS
    SELECT settings.code, settings.val FROM settings WHERE ((COALESCE(settings.company, tools.uuid_null()) = COALESCE(def.settings_company(settings.code), tools.uuid_null())) AND (COALESCE(settings."user", ''::text) = COALESCE(def.settings_user(settings.code), ''::text)));
COMMENT ON VIEW user_settings IS 'Переменные пользователя';
CREATE TABLE company (
    code ext.ltree,
    company uuid,
    val text
);
COMMENT ON TABLE company IS 'Значения настроек уровня организации';
COMMENT ON COLUMN company.code IS 'Код настройки';
COMMENT ON COLUMN company.company IS 'Организация';
COMMENT ON COLUMN company.val IS 'Значение';
ALTER TABLE ONLY company
    ADD CONSTRAINT uk_set_company_code UNIQUE (code, company);
ALTER TABLE ONLY settings
    ADD CONSTRAINT uk_settings_code UNIQUE (code, company, "user");
CREATE INDEX fki_company_code ON company USING btree (code);
CREATE INDEX fki_settings_code ON settings USING btree (code);
CREATE TRIGGER tbui_settings BEFORE INSERT OR UPDATE OF code, "user", company ON settings FOR EACH ROW EXECUTE PROCEDURE tfc_settings();
ALTER TABLE ONLY company
    ADD CONSTRAINT fk_set_company_code FOREIGN KEY (code) REFERENCES def.settings(code) ON UPDATE CASCADE;
ALTER TABLE ONLY settings
    ADD CONSTRAINT fk_settings_code FOREIGN KEY (code) REFERENCES def.settings(code) ON UPDATE CASCADE;
