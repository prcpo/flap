CREATE ROLE accuser;
CREATE ROLE test LOGIN PASSWORD 'test';
GRANT accuser TO test;
