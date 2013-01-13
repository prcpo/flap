--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.1
-- Dumped by pg_dump version 9.2.1
-- Started on 2012-11-23 12:07:00 OMST

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- TOC entry 178 (class 1259 OID 25705)
-- Name: companies; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW companies AS
    SELECT companies.uuid, companies.code FROM sec.companies, sec.users WHERE ((users.company = companies.uuid) AND (users.user_name = ("current_user"())::text));

GRANT SELECT ON TABLE companies TO GROUP accuser;

-- Completed on 2012-11-23 12:07:01 OMST

--
-- PostgreSQL database dump complete
--

