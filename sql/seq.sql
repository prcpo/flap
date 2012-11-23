--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.1
-- Dumped by pg_dump version 9.2.1
-- Started on 2012-11-23 12:04:42 OMST

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 9 (class 2615 OID 25600)
-- Name: sec; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sec;


--
-- TOC entry 2148 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA sec; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA sec IS 'Обеспечение безопасности, разграничение прав доступа, аудит.';


SET search_path = sec, pg_catalog;

--
-- TOC entry 266 (class 1255 OID 25612)
-- Name: company_add(text); Type: FUNCTION; Schema: sec; Owner: -
--

CREATE FUNCTION company_add(_code text) RETURNS uuid
    LANGUAGE plpgsql
    AS $$declare
	_uuid uuid;
BEGIN
	insert into sec.companies (code)
	values (_code)
	Returning uuid INTO _uuid;
	RETURN _uuid;
exception
	when unique_violation then
		Return null::uuid;
end;$$;


--
-- TOC entry 2149 (class 0 OID 0)
-- Dependencies: 266
-- Name: FUNCTION company_add(_code text); Type: COMMENT; Schema: sec; Owner: -
--

COMMENT ON FUNCTION company_add(_code text) IS 'Создаёт новую учётную запись организации.
Возвращает UUID организации.';


--
-- TOC entry 273 (class 1255 OID 25688)
-- Name: company_del(text); Type: FUNCTION; Schema: sec; Owner: -
--

CREATE FUNCTION company_del(_code text) RETURNS void
    LANGUAGE sql
    AS $_$delete from sec.companies
where code = $1;$_$;


--
-- TOC entry 2150 (class 0 OID 0)
-- Dependencies: 273
-- Name: FUNCTION company_del(_code text); Type: COMMENT; Schema: sec; Owner: -
--

COMMENT ON FUNCTION company_del(_code text) IS 'Удаляет учётную запись организации';


SET default_with_oids = false;

--
-- TOC entry 174 (class 1259 OID 25631)
-- Name: companies; Type: TABLE; Schema: sec; Owner: -
--

CREATE TABLE companies (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    code text NOT NULL
);


--
-- TOC entry 2151 (class 0 OID 0)
-- Dependencies: 174
-- Name: TABLE companies; Type: COMMENT; Schema: sec; Owner: -
--

COMMENT ON TABLE companies IS 'Учётные записи организаций';


--
-- TOC entry 2152 (class 0 OID 0)
-- Dependencies: 174
-- Name: COLUMN companies.uuid; Type: COMMENT; Schema: sec; Owner: -
--

COMMENT ON COLUMN companies.uuid IS 'Уникальный ID учётной записи организации';


--
-- TOC entry 2153 (class 0 OID 0)
-- Dependencies: 174
-- Name: COLUMN companies.code; Type: COMMENT; Schema: sec; Owner: -
--

COMMENT ON COLUMN companies.code IS 'Код учётной записи организации';


--
-- TOC entry 177 (class 1259 OID 25689)
-- Name: users; Type: TABLE; Schema: sec; Owner: -
--

CREATE TABLE users (
    user_name text DEFAULT "current_user"() NOT NULL,
    company uuid NOT NULL
);


--
-- TOC entry 2142 (class 0 OID 25631)
-- Dependencies: 174
-- Data for Name: companies; Type: TABLE DATA; Schema: sec; Owner: -
--

INSERT INTO companies (uuid, code) VALUES ('2ce21e12-e5bb-be2e-26e1-cc7f07115237', '<<<test_company>>>');


--
-- TOC entry 2143 (class 0 OID 25689)
-- Dependencies: 177
-- Data for Name: users; Type: TABLE DATA; Schema: sec; Owner: -
--



--
-- TOC entry 2135 (class 2606 OID 25639)
-- Name: pk_companies; Type: CONSTRAINT; Schema: sec; Owner: -
--

ALTER TABLE ONLY companies
    ADD CONSTRAINT pk_companies PRIMARY KEY (uuid);


--
-- TOC entry 2140 (class 2606 OID 25697)
-- Name: pk_users; Type: CONSTRAINT; Schema: sec; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT pk_users PRIMARY KEY (user_name, company);


--
-- TOC entry 2137 (class 2606 OID 25641)
-- Name: ui_companies_code; Type: CONSTRAINT; Schema: sec; Owner: -
--

ALTER TABLE ONLY companies
    ADD CONSTRAINT ui_companies_code UNIQUE (code);


--
-- TOC entry 2138 (class 1259 OID 25703)
-- Name: fki_users_company; Type: INDEX; Schema: sec; Owner: -
--

CREATE INDEX fki_users_company ON users USING btree (company);


--
-- TOC entry 2141 (class 2606 OID 25698)
-- Name: fk_users_company; Type: FK CONSTRAINT; Schema: sec; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_users_company FOREIGN KEY (company) REFERENCES companies(uuid) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2012-11-23 12:04:43 OMST

--
-- PostgreSQL database dump complete
--

