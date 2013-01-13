SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA sec;
COMMENT ON SCHEMA sec IS 'Обеспечение безопасности, разграничение прав доступа, аудит.';
SET search_path = sec, pg_catalog;
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
COMMENT ON FUNCTION company_add(_code text) IS 'Создаёт новую учётную запись организации.
Возвращает UUID организации.';
CREATE FUNCTION company_del(_code text) RETURNS void
    LANGUAGE sql
    AS $_$delete from sec.companies
where code = $1;$_$;
COMMENT ON FUNCTION company_del(_code text) IS 'Удаляет учётную запись организации';
CREATE FUNCTION company_get() RETURNS uuid
    LANGUAGE sql
    AS $$select uuid_null();$$;
COMMENT ON FUNCTION company_get() IS 'Возвращает тескущую организацию';
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE companies (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    code text NOT NULL
);
COMMENT ON TABLE companies IS 'Учётные записи организаций';
COMMENT ON COLUMN companies.uuid IS 'Уникальный ID учётной записи организации';
COMMENT ON COLUMN companies.code IS 'Код учётной записи организации';
CREATE TABLE users (
    user_name text DEFAULT "current_user"() NOT NULL,
    company uuid NOT NULL
);
INSERT INTO companies (uuid, code) VALUES ('2ce21e12-e5bb-be2e-26e1-cc7f07115237', '<<<test_company>>>');
ALTER TABLE ONLY companies
    ADD CONSTRAINT pk_companies PRIMARY KEY (uuid);
ALTER TABLE ONLY users
    ADD CONSTRAINT pk_users PRIMARY KEY (user_name, company);
ALTER TABLE ONLY companies
    ADD CONSTRAINT ui_companies_code UNIQUE (code);
CREATE INDEX fki_users_company ON users USING btree (company);
ALTER TABLE ONLY users
    ADD CONSTRAINT fk_users_company FOREIGN KEY (company) REFERENCES companies(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
