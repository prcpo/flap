SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA set;
COMMENT ON SCHEMA set IS 'Значения констант, параметров, настроек.';
SET search_path = set, pg_catalog;
CREATE FUNCTION company_get() RETURNS uuid
    LANGUAGE plpgsql
    AS $$declare
	_res uuid;
begin
	_res = NULL;
	select val::uuid into _res
	from set.user_settings_wo_history 
	where code = 'work.company';
	return coalesce(_res, uuid_null());
end;$$;
COMMENT ON FUNCTION company_get() IS 'Возвращает тескущую организацию';
CREATE FUNCTION company_set(uuid) RETURNS boolean
    LANGUAGE sql
    AS $_$select set.set('work.company', uuid::text) 
from companies
where uuid = $1;$_$;
COMMENT ON FUNCTION company_set(uuid) IS 'Устанавливает организацию, учёт которой ведём.';
CREATE FUNCTION get(_code ext.ltree, _dt date DEFAULT public.work_date()) RETURNS text
    LANGUAGE plpgsql
    AS $$begin
	-- Если запрашивается расчётная дата, то получим зацикливание на view set.user_settings
	if (_code = 'work.date') then
		return val from set.user_settings_wo_history
			where code = _code;
	else
		return COALESCE(h.val, s.val) AS val
			FROM set.user_settings_wo_history s
			LEFT JOIN set.history h ON h.code = s.code AND h.company = s.company AND h."user" = s."user"
			WHERE daterange(h.dt, h.dt_e) @> coalesce(_dt, work_date())
			and s.code = _code;
	end if;
end;$$;
COMMENT ON FUNCTION get(_code ext.ltree, _dt date) IS 'Возвращает значение переменной';
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
CREATE FUNCTION tfc_history() RETURNS trigger
    LANGUAGE plpgsql
    AS $$declare
	_cur	refcursor;
	_row	set.history%rowtype;
	_currow	set.history%rowtype;
	_dt	date;
begin
	_dt = 'infinity'::date;
	if (TG_OP = 'DELETE') then
		_row = OLD;
	else
		_row = NEW;
	end if;
	open _cur for select * FROM set.history
		where code = _row.code 
		and company = _row.company
		and "user" = _row.user 
		order by dt desc;
	loop
		fetch _cur into _currow;
		exit when _currow is null;
		if not (_currow.dt_e = _dt) then
			update set.history
				set dt_e = _dt
				where code = _currow.code 
				and company = _currow.company
				and "user" = _currow.user
				and dt = _currow.dt;
			raise notice 'History on "%" was be updated', _dt;
		end if;
	_dt = _currow.dt;
	end loop;
	close _cur;
	return _row;
end;$$;
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
CREATE FUNCTION tfc_settings_history() RETURNS trigger
    LANGUAGE plpgsql
    AS $$begin
	if TG_OP = 'DELETE' then return NEW; end if;
	if exists (
		select 'x' from def.settings
		where code = NEW.code and (not ishistory)) then
		raise notice 'Setting "%" save no history', NEW.code;
		return NEW;
	end if;
	if not exists (
		select 'x' from set.history
		where code = NEW.code and company = NEW.company 
		and "user" = NEW.user and dt = work_date())
	then
		insert into set.history (code, company, "user", dt, val)
		values (NEW.code, NEW.company, NEW.user, work_date(), NEW.val);
		raise notice 'Setting "%" history was be added', NEW.code;
	else
		update set.history 
		set val = NEW.val
		where code = NEW.code and company = NEW.company 
		and "user" = NEW.user and dt = work_date();
		raise notice 'Setting "%" history was be updated', NEW.code;
	end if;
	return NEW;
end;$$;
COMMENT ON FUNCTION tfc_settings_history() IS 'Отражает историю изменения значений параметров';
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE history (
    code ext.ltree NOT NULL,
    company uuid DEFAULT tools.uuid_null() NOT NULL,
    "user" text DEFAULT "session_user"() NOT NULL,
    val text,
    dt date DEFAULT now() NOT NULL,
    dt_e date DEFAULT now() NOT NULL
);
COMMENT ON TABLE history IS 'История значений';
CREATE TABLE settings (
    code ext.ltree NOT NULL,
    company uuid DEFAULT tools.uuid_null() NOT NULL,
    "user" text DEFAULT "session_user"() NOT NULL,
    val text
);
COMMENT ON TABLE settings IS 'Значения настроек';
COMMENT ON COLUMN settings.code IS 'Код настройки';
COMMENT ON COLUMN settings.company IS 'Организация';
COMMENT ON COLUMN settings."user" IS 'Пользователь';
COMMENT ON COLUMN settings.val IS 'Значение';
CREATE VIEW user_settings_wo_history AS
    SELECT s.code, s.company, s."user", s.val FROM settings s WHERE ((COALESCE(s.company, tools.uuid_null()) = COALESCE(def.settings_company(s.code), tools.uuid_null())) AND (COALESCE(s."user", ''::text) = COALESCE(def.settings_user(s.code), ''::text)));
COMMENT ON VIEW user_settings_wo_history IS 'Переменные пользователя без учёта истории';
CREATE VIEW user_settings_h AS
    SELECT s.code, COALESCE(h.val, s.val) AS val, daterange(COALESCE(h.dt, '-infinity'::date), COALESCE(h.dt_e, 'infinity'::date)) AS period FROM (user_settings_wo_history s LEFT JOIN history h ON ((((h.code OPERATOR(ext.=) s.code) AND (h.company = s.company)) AND (h."user" = s."user"))));
COMMENT ON VIEW user_settings_h IS 'Переменные пользователя с историей';
CREATE VIEW settings_h AS
    SELECT d.code, COALESCE(s.val, d.default_value) AS val, COALESCE(s.period, daterange('-infinity'::date, 'infinity'::date)) AS period FROM (def.settings d LEFT JOIN user_settings_h s ON ((s.code OPERATOR(ext.=) d.code)));
COMMENT ON VIEW settings_h IS 'Все значения переменных, доступные пользователю, включая их историю';
ALTER TABLE ONLY history
    ADD CONSTRAINT pk_history PRIMARY KEY (code, company, "user", dt);
ALTER TABLE ONLY settings
    ADD CONSTRAINT pk_settings PRIMARY KEY (code, company, "user");
ALTER TABLE ONLY settings
    ADD CONSTRAINT uk_settings_code UNIQUE (code, company, "user");
CREATE INDEX fki_settings_code ON settings USING btree (code);
CREATE INDEX history_code_idx ON history USING btree (code);
CREATE TRIGGER taiud_history AFTER INSERT OR DELETE OR UPDATE ON history FOR EACH ROW EXECUTE PROCEDURE tfc_history();
CREATE TRIGGER taui_settings AFTER INSERT OR DELETE OR UPDATE ON settings FOR EACH ROW EXECUTE PROCEDURE tfc_settings_history();
CREATE TRIGGER tbui_settings BEFORE INSERT OR UPDATE OF code, "user", company ON settings FOR EACH ROW EXECUTE PROCEDURE tfc_settings();
ALTER TABLE ONLY settings
    ADD CONSTRAINT fk_settings_code FOREIGN KEY (code) REFERENCES def.settings(code) ON UPDATE CASCADE;
