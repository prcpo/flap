SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET search_path = public, pg_catalog;
CREATE VIEW companies AS
    SELECT companies.uuid, companies.code FROM sec.companies, sec.users WHERE ((users.company = companies.uuid) AND (users.user_name = ("current_user"())::text));
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
REVOKE ALL ON TABLE companies FROM PUBLIC;
REVOKE ALL ON TABLE companies FROM admin;
GRANT ALL ON TABLE companies TO admin;
GRANT SELECT ON TABLE companies TO accuser;
