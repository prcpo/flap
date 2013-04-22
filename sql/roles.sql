CREATE ROLE accuser;
commit;
CREATE ROLE test LOGIN PASSWORD 'test';
commit;
GRANT accuser TO test;
commit;