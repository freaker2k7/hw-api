from chalice.test import Client
from app import app
from time import time


def test_index():
	with Client(app) as client:
		response = client.http.get('/')
		assert response.body == b'OK'


def test_flow():
	with Client(app) as client:
		response = client.http.post('/auth',
			headers={'Content-Type': 'application/json'},
			body=b'{"username": "sender", "password": "pass"}')
		token = response.json_body.get('hash')
		assert len(token) == 40

		response = client.http.post('/add_delivery',
			headers={"Authorization": token, 'Content-Type': 'application/json'},
			body=b'{"size": "22x33x44", "cost": 23.45, "description": "Test delivery"}')
		assert response.status_code == 200

		response = client.http.get('/deliveries/sender/1',
			headers={"Authorization": token, 'Content-Type': 'application/json'})
		assert response.status_code == 200

		response = client.http.get('/deliveries/courier/1',
			headers={"Authorization": token, 'Content-Type': 'application/json'})
		assert response.status_code == 200

		response = client.http.put('/assign/1/1',
			headers={"Authorization": token, 'Content-Type': 'application/json'})
		assert response.status_code == 200

		response = client.http.post('/auth',
			headers={'Content-Type': 'application/json'},
			body=b'{"username": "courier", "password": "pass"}')
		token = response.json_body.get('hash')
		assert len(token) == 40

		response = client.http.get(f'/revenue/0/{int(time())}',
			headers={"Authorization": token, 'Content-Type': 'application/json'})
		assert response.status_code == 200
