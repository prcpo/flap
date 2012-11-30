--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.1
-- Dumped by pg_dump version 9.2.1
-- Started on 2012-11-30 09:59:39 OMST

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 14 (class 2615 OID 36389)
-- Name: set; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA set;


--
-- TOC entry 2154 (class 0 OID 0)
-- Dependencies: 14
-- Name: SCHEMA set; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA set IS 'Значения констант, параметров, настроек.';


SET search_path = set, pg_catalog;

--
-- TOC entry 283 (class 1255 OID 110574)
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
-- TOC entry 2155 (class 0 OID 0)
-- Dependencies: 283
-- Name: FUNCTION set(_code ext.ltree, _value text); Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON FUNCTION set(_code ext.ltree, _value text) IS 'Устанавливает значение переменной.
Возвращает TRUE, если значение успешно установлено';


SET default_with_oids = false;

--
-- TOC entry 185 (class 1259 OID 36404)
-- Name: settings; Type: TABLE; Schema: set; Owner: -
--

CREATE TABLE settings (
    code ext.ltree,
    company uuid,
    "user" text,
    val text
);


--
-- TOC entry 2156 (class 0 OID 0)
-- Dependencies: 185
-- Name: TABLE settings; Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON TABLE settings IS 'Значения настроек';


--
-- TOC entry 2157 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN settings.code; Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON COLUMN settings.code IS 'Код настройки';


--
-- TOC entry 2158 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN settings.company; Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON COLUMN settings.company IS 'Организация';


--
-- TOC entry 2159 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN settings."user"; Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON COLUMN settings."user" IS 'Пользователь';


--
-- TOC entry 2160 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN settings.val; Type: COMMENT; Schema: set; Owner: -
--

COMMENT ON COLUMN settings.val IS 'Значение';


--
-- TOC entry 2149 (class 0 OID 36404)
-- Dependencies: 185
-- Data for Name: settings; Type: TABLE DATA; Schema: set; Owner: -
--



--
-- TOC entry 2147 (class 1259 OID 110570)
-- Name: fki_settings_code; Type: INDEX; Schema: set; Owner: -
--

CREATE INDEX fki_settings_code ON settings USING btree (code);


--
-- TOC entry 2148 (class 2606 OID 110565)
-- Name: fk_settings_code; Type: FK CONSTRAINT; Schema: set; Owner: -
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT fk_settings_code FOREIGN KEY (code) REFERENCES def.settings(code) ON UPDATE CASCADE;


-- Completed on 2012-11-30 09:59:39 OMST

--
-- PostgreSQL database dump complete
--

