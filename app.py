from chalice import Chalice, BadRequestError, UnauthorizedError
import chalicelib.conn as db
from datetime import datetime
from json import loads, dumps

app = Chalice(app_name='hw')
app.api.cors = True


def authed(func):
	def inner(*args, **kwargs):
		request = app.current_request

		username = db.read_one('check_hash', [request.headers.get('Authorization', '')])

		if not username:
			return UnauthorizedError()

		return func(request, username, *args, **kwargs)
	return inner


@app.route('/')
def index():
	# Health check
	return 'OK'


@app.route('/auth', methods=['POST'])
def auth():
	# Authentication endpoint
	#
	# NOTE: The endpoint should authenticate a user by getting a username
	# and password from the user and returning an access token. A user can
	# be authenticated as a sender or as a courier(for testing one entity
	# per user is enough).

	username = app.current_request.json_body.get('username')
	password = app.current_request.json_body.get('password')

	if not username or not password:
		return UnauthorizedError()

	_hash = db.read_one('check_auth', [username, password])

	if not _hash:
		return UnauthorizedError()

	return {'hash': _hash}


@app.route('/add_delivery', methods=['POST'])
@authed
def ad_delivery(req, username, **kwargs):
	# "Add Delivery" endpoint
	#
	# NOTE: Only the sender can add a delivery.

	if db.read_one('get_sender', [username]):
		size = req.json_body.get('size', '').split('x')

		if not size or len(size) != 3 or not all(map(lambda x: x.isnumeric(), size)):
			return BadRequestError('No size for delivery')

		try:
			cost = float(req.json_body.get('cost'))
		except:
			return BadRequestError('No cost for delivery')

		description = req.json_body.get('description', '')
		description = description.replace('<', '') # basic XSS protection, this breaks any injected script

		return db.write('add_delivery', ['x'.join(size), cost, description])

	return BadRequestError()


@app.route('/deliveries/sender/{sid}', methods=['GET'])
@authed
def deliveries_sender(req, username, sid, **kwargs):
	# “Get Deliveries" for sender endpoint
	#
	# NOTE: Returns all the deliveries created by this sender.
	# NOTE: Support pagination by using ?page=<number>

	return loads(dumps(db.read('get_sender_deliveries', [sid, int(req.query_params.get('page') if req.query_params else 0)]), default=str))


@app.route('/deliveries/courier/{cid}', methods=['GET'])
@authed
def deliveries_courier(req, username, cid, **kwargs):
	# “Get Deliveries" for courier endpoint
	#
	# NOTE: Returns only the deliveries that are assigned to him.
	# NOTE: Support pagination by using ?page=<number>

	return loads(dumps(db.read('get_courier_deliveries', [cid, int(req.query_params.get('page') if req.query_params else 0)]), default=str))


@app.route('/assign/{did}/{cid}', methods=['PUT'])
@authed
def assign(req, username, did, cid, **kwargs):
	# “Assign Delivery" endpoint
	#
	# NOTE: The endpoint should get a delivery and a courier and assign the delivery to the courier.
	# NOTE: Only a sender can assign a delivery.
	# NOTE: Each courier can be assigned up to 5 deliveries a day.

	if db.read_one('get_sender', [username]):
		return db.write_read('assign_delivery', [cid, did])

	return BadRequestError()


@app.route('/revenue/{_from}/{_to}', methods=['GET'])
@authed
def index(req, username, _from, _to, **kwargs):
	# Courier Revenue" endpoint
	#
	# NOTE: The endpoint should return the courier’s revenue for a specific date range.
	# NOTE: A courier can see its own revenue only.

	return db.read('get_courier', [username, datetime.fromtimestamp(int(_from)), datetime.fromtimestamp(int(_to))])
