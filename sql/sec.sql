SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA sec;
COMMENT ON SCHEMA sec IS 'Обеспечение безопасности, разграничение прав доступа, аудит.';
SET search_path = sec, pg_catalog;
CREATE FUNCTION company_add(_code text, _force boolean DEFAULT true) RETURNS uuid
    LANGUAGE plpgsql
    AS $$declare 
	_res	uuid;
	__code	text;
begin
	_res = uuid_null();
	-- Если  аргумент пустой, устанавливаем наименование организации по-умолчанию
	if _code is null then
		select default_value from def.settings
		where code = 'company.name'
		limit 1
		into _code;
	end if;
	__code = _code;
	-- Если второй аргумент = TRUE, пытаемся добавить до упора
	if _force then
		loop
			RAISE NOTICE 'TRY add company %', __code;
			_res = sec.company_add_try(__code);
			if not (_res = uuid_null()) then 
				exit;
			end if;
			__code = _code || ' [' || to_char(clock_timestamp(),'YYMMDD-HH24MISS') || ']';
		end loop;
	else	--  второй аргумент = FASE
		_res = sec.company_add_try(_code);
	end if;
	return _res;
end;
$$;
COMMENT ON FUNCTION company_add(_code text, _force boolean) IS 'Создаёт новую учётную запись организации.
Возвращает UUID организации.
Если второй параметр = FALSE, то в случае дублирования наименования организации, отменяет её создание и возвращает нулевой UUID.
Если второй параметр = TRUE, то добавляет организацию в любом случае, добавляя, при необходимости, дополнительные символы в конец наименования.';
CREATE FUNCTION company_add_try(_code text) RETURNS uuid
    LANGUAGE plpgsql
    AS $$declare
	_uuid uuid;
BEGIN
	insert into sec.companies (code)
	values (_code)
	returning uuid INTO _uuid;
	begin
		insert into sec.users (company)
		values (_uuid);
	end;
	RETURN _uuid;
exception
	when unique_violation then
		Return uuid_null();
end;$$;
COMMENT ON FUNCTION company_add_try(_code text) IS 'Создаёт новую учётную запись организации.
Возвращает UUID организации.';
CREATE FUNCTION company_del(_code text) RETURNS void
    LANGUAGE sql
    AS $_$delete from sec.companies
where code = $1;$_$;
COMMENT ON FUNCTION company_del(_code text) IS 'Удаляет учётную запись организации';
CREATE FUNCTION tfc_company() RETURNS trigger
    LANGUAGE plpgsql
    AS $$begin
	delete from set.settings
	where
	code = 'work.company'
	and val = OLD.uuid::text;
	RETURN NULL;
end;$$;
COMMENT ON FUNCTION tfc_company() IS 'Чистит упоминания об организации при её удалении';
CREATE FUNCTION tfc_users() RETURNS trigger
    LANGUAGE plpgsql
    AS $$begin
	delete from set.settings
	where
	"user" = OLD.user_name
	and code = 'work.company'
	and val = OLD.company::text;
	RETURN NULL;
end;$$;
COMMENT ON FUNCTION tfc_users() IS 'Чистит упоминания об организации при её удалении из списка доступных пользователю';
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
INSERT INTO companies (uuid, code) VALUES ('4032e894-2556-5de5-f9c7-142d72d31604', 'Моя организация [130117-101132]');
ALTER TABLE ONLY companies
    ADD CONSTRAINT pk_companies PRIMARY KEY (uuid);
ALTER TABLE ONLY users
    ADD CONSTRAINT pk_users PRIMARY KEY (user_name, company);
ALTER TABLE ONLY companies
    ADD CONSTRAINT ui_companies_code UNIQUE (code);
CREATE INDEX fki_users_company ON users USING btree (company);
CREATE TRIGGER tad_company AFTER DELETE ON companies FOR EACH ROW EXECUTE PROCEDURE tfc_company();
CREATE TRIGGER tad_users AFTER DELETE ON users FOR EACH ROW EXECUTE PROCEDURE tfc_users();
ALTER TABLE ONLY users
    ADD CONSTRAINT fk_users_company FOREIGN KEY (company) REFERENCES companies(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
