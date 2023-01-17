
-- docker run -p 5432:5432 -d -e POSTGRES_USER="user" -e POSTGRES_PASSWORD="pass" -e POSTGRES_DB="db" -v /tmp/pg-data:/var/lib/postgresql/data --name pg postgres
-- docker exec -i pg psql postgresql://user:pass@0.0.0.0:5432/db < scheme.sql

SET search_path TO public;

create extension pgcrypto;

DROP TABLE IF EXISTS Hashes;
DROP TABLE IF EXISTS Couriers;
DROP TABLE IF EXISTS Deliveries;
DROP TABLE IF EXISTS Senders;
DROP TABLE IF EXISTS Users;

DROP TYPE IF EXISTS VEHICLES;


-- ------------------ MAIN ------------------ --


CREATE TYPE VEHICLES AS ENUM ('bicycle', 'car', 'truck', 'scooter', 'motorcycle', 'helicopter', 'airplain');

CREATE TABLE Couriers (
	"cid" BIGSERIAL,
	"uid" BIGSERIAL,
	"firstName" VARCHAR(42),
	"lastName" VARCHAR(42),
	"phoneNumber" VARCHAR(32),
	"vehicleType" VEHICLES DEFAULT NULL,
	PRIMARY KEY ("cid"),
	UNIQUE ("phoneNumber")
);

CREATE TABLE Deliveries (
	"did" BIGSERIAL,
	"cid" BIGSERIAL,
	"sid" BIGSERIAL,
	"packageSize" VARCHAR(128),
	"cost" DECIMAL,
	"description" TEXT,
	"date" TIMESTAMPTZ DEFAULT NOW(),
	PRIMARY KEY ("did")
);

CREATE TABLE Senders (
	"sid" BIGSERIAL,
	"uid" BIGSERIAL,
	"companyName" VARCHAR(128),
	PRIMARY KEY ("sid"),
	UNIQUE ("companyName")
);

CREATE TABLE Users (
	"uid" BIGSERIAL,
	"username" VARCHAR(42),
	"password" VARCHAR(42),
	PRIMARY KEY ("uid"),
	UNIQUE ("username")
);

CREATE TABLE Hashes (
	"uid" BIGSERIAL,
	"hash" VARCHAR(42),
	PRIMARY KEY ("uid", "hash")
);


-- ------------------ FUNC ------------------ --


DROP FUNCTION IF EXISTS check_auth;
CREATE OR REPLACE FUNCTION check_auth(_username VARCHAR(42), _password VARCHAR(42))
RETURNS VARCHAR(42) AS $$
DECLARE
	_uid BIGINT := 0;
	_hash VARCHAR(42) := '';
BEGIN
	SELECT "uid" INTO _uid FROM Users WHERE "username" = _username AND "password" = _password;

	IF _uid > 0 THEN
		SELECT ENCODE(DIGEST(((RANDOM()::DECIMAL * RANDOM()::DECIMAL)::VARCHAR)::BYTEA, 'sha1'), 'hex') INTO _hash;
		INSERT INTO Hashes("uid", "hash") VALUES (_uid, _hash);
		RETURN _hash;
	ELSE
		RETURN '';
	END IF;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS check_hash;
CREATE OR REPLACE FUNCTION check_hash(_hash VARCHAR(42))
RETURNS VARCHAR(42) AS $$
DECLARE
	_username VARCHAR(42);
BEGIN
	SELECT "username" INTO _username
	FROM Users AS U
		INNER JOIN Hashes AS H ON (H."uid" = U."uid" AND H."hash" = _hash);

	RETURN _username;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS get_sender;
CREATE OR REPLACE FUNCTION get_sender(_username VARCHAR(42))
RETURNS BIGINT AS $$
DECLARE
	_uid BIGINT := 0;
BEGIN
	SELECT "uid" INTO _uid FROM Users WHERE "username" = _username;
	RETURN _uid;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


DROP PROCEDURE IF EXISTS add_delivery;
CREATE OR REPLACE PROCEDURE add_delivery(_sizes VARCHAR(128), _cost DECIMAL, _description TEXT) AS $$
BEGIN
	INSERT INTO Deliveries("packageSize", "cost", "description") VALUES (_sizes, _cost, _description);
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS assign_delivery;
CREATE OR REPLACE FUNCTION assign_delivery(_cid BIGINT, _did BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
	_count SMALLINT := 0;
BEGIN
	IF _count < 5 THEN
		UPDATE Deliveries SET "cid" = _cid WHERE "did" = _did;
		RETURN TRUE;
	ELSE
		RETURN FALE;
	END IF;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS get_courier;
CREATE OR REPLACE FUNCTION get_courier(_username VARCHAR(42), _from TIMESTAMPTZ, _to TIMESTAMPTZ)
RETURNS DECIMAL AS $$
DECLARE
	_ret DECIMAL := 0;
BEGIN
	SELECT SUM(D."cost") INTO _ret
		FROM Deliveries AS D
			INNER JOIN Couriers AS C ON (C."cid" = D."cid")
			INNER JOIN Users AS U ON (U."uid" = C."uid" AND U."username" = _username)
		WHERE D."date" BETWEEN _from AND _to;

	RETURN _ret;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


DROP FUNCTION IF EXISTS get_sender_deliveries;
CREATE OR REPLACE FUNCTION get_sender_deliveries(_sid BIGINT, _page INTEGER)
RETURNS TABLE("did" BIGINT, "cid" BIGINT, "packageSize" VARCHAR(128), "cost" DECIMAL, "description" TEXT, "date" TIMESTAMPTZ) AS $$
BEGIN
	RETURN QUERY EXECUTE 'SELECT "did", "cid", "packageSize", "cost", "description", "date"
		FROM Deliveries
		WHERE "sid" = $1
		LIMIT 10 OFFSET $2' USING _sid, 10 * _page;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


DROP FUNCTION IF EXISTS get_courier_deliveries;
CREATE OR REPLACE FUNCTION get_courier_deliveries(_cid BIGINT, _page INTEGER)
RETURNS TABLE("did" BIGINT, "sid" BIGINT, "packageSize" VARCHAR(128), "cost" DECIMAL, "description" TEXT, "date" TIMESTAMPTZ) AS $$
BEGIN
	RETURN QUERY EXECUTE 'SELECT "did", "sid", "packageSize", "cost", "description", "date"
		FROM Deliveries
		WHERE "cid" = $1
		LIMIT 10 OFFSET $2' USING _cid, 10 * _page;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- ------------------ DATA ------------------ --


INSERT INTO Users ("username", "password") VALUES ('sender', 'pass'), ('courier', 'pass');
INSERT INTO Senders ("uid", "companyName") VALUES (1, 'acmey');
INSERT INTO Couriers ("uid" ,"firstName", "lastName", "phoneNumber", "vehicleType") VALUES (2, 'John', 'Doe', '+1234567890', 'car');



