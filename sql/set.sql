--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.2
-- Dumped by pg_dump version 9.2.2
-- Started on 2013-01-13 20:19:16 NOVT

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 13 (class 2615 OID 19359)
-- Name: set; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA set;


--
-- TOC entry 2166 (class 0 OID 0)
-- Dependencies: 13
-- Name: SCHEMA set; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA set IS 'Значения констант, параметров, настроек.';


SET search_path = set, pg_catalog;

--
-- TOC entry 287 (class 1255 OID 19391)
-- Name: get(ext.ltree); Type: FUNCTION; Schema: set; Owner: -
--

CREATE FUNCTION get(_code ext.ltree) RETURNS text
    LANGUAGE plpgsql
    AS $$declare
	_res text;
begin
	select val from set.settings
		where code = _code
		into _res;
	return _res;
end;$$;


--
-- TOC entry 2167 (class 0 OID 0)
-- Dependencies: 287
-- Name: FUNCTION get(_code ext.ltree); Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON FUNCTION get(_code ext.ltree) IS 'Возвращает значение переменной';


--
-- TOC entry 283 (class 1255 OID 19360)
-- Name: set(ext.ltree, text); Type: FUNCTION; Schema: set; Owner: -
--

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
	RETURN TRUE;
exception
	when others then
		return false;
end;$$;


--
-- TOC entry 2168 (class 0 OID 0)
-- Dependencies: 283
-- Name: FUNCTION set(_code ext.ltree, _value text); Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON FUNCTION set(_code ext.ltree, _value text) IS 'Устанавливает значение переменной.
Возвращает TRUE, если значение успешно установлено';


--
-- TOC entry 288 (class 1255 OID 19392)
-- Name: tfc_settings(); Type: FUNCTION; Schema: set; Owner: -
--

CREATE FUNCTION tfc_settings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$declare
	_iscompany boolean;
	_isuser boolean;
	_ishistory boolean;

begin

	IF NEW.code IS NULL THEN
		RAISE EXCEPTION 'code cannot be null';
	END IF;

	select isuser, iscompany, ishistory 
		from def.settings
		where code = NEW.code
		into _isuser, _iscompany, _ishistory;

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


--
-- TOC entry 2169 (class 0 OID 0)
-- Dependencies: 288
-- Name: FUNCTION tfc_settings(); Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON FUNCTION tfc_settings() IS 'Проверяет условиязаполнения таблицы settings';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 184 (class 1259 OID 19361)
-- Name: settings; Type: TABLE; Schema: set; Owner: -; Tablespace: 
--

CREATE TABLE settings (
    code ext.ltree,
    company uuid,
    "user" text,
    val text
);


--
-- TOC entry 2170 (class 0 OID 0)
-- Dependencies: 184
-- Name: TABLE settings; Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON TABLE settings IS 'Значения настроек';


--
-- TOC entry 2171 (class 0 OID 0)
-- Dependencies: 184
-- Name: COLUMN settings.code; Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON COLUMN settings.code IS 'Код настройки';


--
-- TOC entry 2172 (class 0 OID 0)
-- Dependencies: 184
-- Name: COLUMN settings.company; Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON COLUMN settings.company IS 'Организация';


--
-- TOC entry 2173 (class 0 OID 0)
-- Dependencies: 184
-- Name: COLUMN settings."user"; Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON COLUMN settings."user" IS 'Пользователь';


--
-- TOC entry 2174 (class 0 OID 0)
-- Dependencies: 184
-- Name: COLUMN settings.val; Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON COLUMN settings.val IS 'Значение';


--
-- TOC entry 2161 (class 0 OID 19361)
-- Dependencies: 184
-- Data for Name: settings; Type: TABLE DATA; Schema: set; Owner: -
--

INSERT INTO settings (code, company, "user", val) VALUES ('company.name', '00000000-0000-0000-0000-000000000000', NULL, '6Моя онизация');
INSERT INTO settings (code, company, "user", val) VALUES ('work.date', '00000000-0000-0000-0000-000000000000', 'postgres', '11.12.12');
INSERT INTO settings (code, company, "user", val) VALUES ('work.date', '00000000-0000-0000-0000-000000000000', 'oper', '12.12.12');


--
-- TOC entry 2158 (class 1259 OID 19367)
-- Name: fki_settings_code; Type: INDEX; Schema: set; Owner: -; Tablespace: 
--

CREATE INDEX fki_settings_code ON settings USING btree (code);


--
-- TOC entry 2160 (class 2620 OID 19395)
-- Name: tbui_settings; Type: TRIGGER; Schema: set; Owner: -
--

CREATE TRIGGER tbui_settings BEFORE INSERT OR UPDATE OF code, "user", company ON settings FOR EACH ROW EXECUTE PROCEDURE tfc_settings();


--
-- TOC entry 2159 (class 2606 OID 19368)
-- Name: fk_settings_code; Type: FK CONSTRAINT; Schema: set; Owner: -
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT fk_settings_code FOREIGN KEY (code) REFERENCES def.settings(code) ON UPDATE CASCADE;


-- Completed on 2013-01-13 20:19:16 NOVT

--
-- PostgreSQL database dump complete
--

