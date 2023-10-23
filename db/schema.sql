CREATE TABLE IF NOT EXISTS vets (
  id         INTEGER NOT NULL PRIMARY KEY,
  first_name TEXT,
  last_name  TEXT
);
CREATE INDEX ON vets (last_name);

CREATE TABLE IF NOT EXISTS specialties (
  id   INTEGER NOT NULL PRIMARY KEY,
  name TEXT
);
CREATE INDEX ON specialties (name);

CREATE TABLE IF NOT EXISTS vet_specialties (
  vet_id       INT NOT NULL REFERENCES vets (id),
  specialty_id INT NOT NULL REFERENCES specialties (id),
  UNIQUE (vet_id, specialty_id)
);

CREATE TABLE IF NOT EXISTS types (
  id   INTEGER NOT NULL PRIMARY KEY,
  name TEXT
);
CREATE INDEX ON types (name);

CREATE TABLE IF NOT EXISTS owners (
  id         INTEGER NOT NULL PRIMARY KEY,
  first_name TEXT,
  last_name  TEXT,
  address    TEXT,
  city       TEXT,
  telephone  TEXT
);
CREATE INDEX ON owners (last_name);

CREATE TABLE IF NOT EXISTS pets (
  id         INTEGER NOT NULL PRIMARY KEY,
  name       TEXT,
  birth_date DATE,
  type_id    INT NOT NULL REFERENCES types (id),
  owner_id   INT REFERENCES owners (id)
);
CREATE INDEX ON pets (name);
CREATE INDEX ON pets (owner_id);

CREATE TABLE IF NOT EXISTS visits (
  id          INTEGER NOT NULL PRIMARY KEY,
  pet_id      INT REFERENCES pets (id),
  visit_date  DATE,
  description TEXT
);
CREATE INDEX ON visits (pet_id);
