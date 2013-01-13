--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.2
-- Dumped by pg_dump version 9.2.2
-- Started on 2013-01-13 20:39:12 NOVT

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 11 (class 2615 OID 19278)
-- Name: sec; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sec;


--
-- TOC entry 2175 (class 0 OID 0)
-- Dependencies: 11
-- Name: SCHEMA sec; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA sec IS 'Обеспечение безопасности, разграничение прав доступа, аудит.';


SET search_path = sec, pg_catalog;

--
-- TOC entry 281 (class 1255 OID 19279)
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
-- TOC entry 2176 (class 0 OID 0)
-- Dependencies: 281
-- Name: FUNCTION company_add(_code text); Type: COMMENT; Schema: sec; Owner: -
--

COMMENT ON FUNCTION company_add(_code text) IS 'Создаёт новую учётную запись организации.
Возвращает UUID организации.';


--
-- TOC entry 282 (class 1255 OID 19280)
-- Name: company_del(text); Type: FUNCTION; Schema: sec; Owner: -
--

CREATE FUNCTION company_del(_code text) RETURNS void
    LANGUAGE sql
    AS $_$delete from sec.companies
where code = $1;$_$;


--
-- TOC entry 2177 (class 0 OID 0)
-- Dependencies: 282
-- Name: FUNCTION company_del(_code text); Type: COMMENT; Schema: sec; Owner: -
--

COMMENT ON FUNCTION company_del(_code text) IS 'Удаляет учётную запись организации';


--
-- TOC entry 286 (class 1255 OID 19390)
-- Name: company_get(); Type: FUNCTION; Schema: sec; Owner: -
--

CREATE FUNCTION company_get() RETURNS uuid
    LANGUAGE sql
    AS $$select uuid_null();$$;


--
-- TOC entry 2178 (class 0 OID 0)
-- Dependencies: 286
-- Name: FUNCTION company_get(); Type: COMMENT; Schema: sec; Owner: -
--

COMMENT ON FUNCTION company_get() IS 'Возвращает тескущую организацию';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 178 (class 1259 OID 19281)
-- Name: companies; Type: TABLE; Schema: sec; Owner: -; Tablespace: 
--

CREATE TABLE companies (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    code text NOT NULL
);


--
-- TOC entry 2179 (class 0 OID 0)
-- Dependencies: 178
-- Name: TABLE companies; Type: COMMENT; Schema: sec; Owner: -
--

COMMENT ON TABLE companies IS 'Учётные записи организаций';


--
-- TOC entry 2180 (class 0 OID 0)
-- Dependencies: 178
-- Name: COLUMN companies.uuid; Type: COMMENT; Schema: sec; Owner: -
--

COMMENT ON COLUMN companies.uuid IS 'Уникальный ID учётной записи организации';


--
-- TOC entry 2181 (class 0 OID 0)
-- Dependencies: 178
-- Name: COLUMN companies.code; Type: COMMENT; Schema: sec; Owner: -
--

COMMENT ON COLUMN companies.code IS 'Код учётной записи организации';


--
-- TOC entry 179 (class 1259 OID 19288)
-- Name: users; Type: TABLE; Schema: sec; Owner: -; Tablespace: 
--

CREATE TABLE users (
    user_name text DEFAULT "current_user"() NOT NULL,
    company uuid NOT NULL
);


--
-- TOC entry 2169 (class 0 OID 19281)
-- Dependencies: 178
-- Data for Name: companies; Type: TABLE DATA; Schema: sec; Owner: -
--

INSERT INTO companies (uuid, code) VALUES ('2ce21e12-e5bb-be2e-26e1-cc7f07115237', '<<<test_company>>>');


--
-- TOC entry 2170 (class 0 OID 19288)
-- Dependencies: 179
-- Data for Name: users; Type: TABLE DATA; Schema: sec; Owner: -
--



--
-- TOC entry 2162 (class 2606 OID 19296)
-- Name: pk_companies; Type: CONSTRAINT; Schema: sec; Owner: -; Tablespace: 
--

ALTER TABLE ONLY companies
    ADD CONSTRAINT pk_companies PRIMARY KEY (uuid);


--
-- TOC entry 2167 (class 2606 OID 19298)
-- Name: pk_users; Type: CONSTRAINT; Schema: sec; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT pk_users PRIMARY KEY (user_name, company);


--
-- TOC entry 2164 (class 2606 OID 19300)
-- Name: ui_companies_code; Type: CONSTRAINT; Schema: sec; Owner: -; Tablespace: 
--

ALTER TABLE ONLY companies
    ADD CONSTRAINT ui_companies_code UNIQUE (code);


--
-- TOC entry 2165 (class 1259 OID 19301)
-- Name: fki_users_company; Type: INDEX; Schema: sec; Owner: -; Tablespace: 
--

CREATE INDEX fki_users_company ON users USING btree (company);


--
-- TOC entry 2168 (class 2606 OID 19302)
-- Name: fk_users_company; Type: FK CONSTRAINT; Schema: sec; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_users_company FOREIGN KEY (company) REFERENCES companies(uuid) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2013-01-13 20:39:12 NOVT

--
-- PostgreSQL database dump complete
--

