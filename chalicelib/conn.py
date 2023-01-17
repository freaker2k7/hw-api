from postgres import Postgres
from os import environ

username = environ.get('POSTGRES_USER', 'user')
password = environ.get('POSTGRES_PASSWORD', 'pass')
host = environ.get('POSTGRES_HOST', '10.0.0.2')
port = environ.get('POSTGRES_PORT', '5432')
db = environ.get('POSTGRES_DB', 'db')

db = Postgres(url=f'postgresql://{username}:{password}@{host}:{port}/{db}')

def _prepare(data):
	return ', '.join([f'%s' for t in data])

def read(func, data, limit=100):
	return db.all(f'SELECT * FROM {func}({_prepare(data)}) LIMIT {limit}', data)

def read_one(func, data):
	return db.one(f'SELECT * FROM {func}({_prepare(data)})', data)

def write(func, data):
	return db.run(f'CALL {func}({_prepare(data)})', data)

def write_read(func, data):
	return db.run(f'SELECT * FROM {func}({_prepare(data)})', data)
