Homework
========

Story
-----

The first thing that comes to my mind when I hear "micro-service" is an AWS Lambda.

I worked for a few good years with this wonderful framework called Chalice [https://aws.github.io/chalice/index.html].
This is a python framework. I did a lot of research regarding these cloud frameworks and I think this one is the best.
Sam (TS framework) is way too heavy, Zappa took me a while to understand and as for Stateless (a JS/TS framework), well,
from my personal experience kinda sux (sorry for my language).

At first I thought to do it all using Redis as my database, just for fun, but eventually I went with Postgres.
It's an amazingly powerful relational database and I saw it fit here.


Arch.
-----

So I approached it like so:

1. First I bootstrapped a new project and populated all the methods. (app.py)
2. Then I wrapped for the database connection (chalicelib/conn.py)
3. After that I created the SQL scheme, all needed stored procedures and some population data.
4. Lastly, I created some tests to optimistically check all the cases.

* I also added a small `.travis.yml` file for some initial CI.


Run
---

To run the project locally, install the dev and regular requirements and simply run the following:

1. `docker run -p 5432:5432 -d -e POSTGRES_USER="user" -e POSTGRES_PASSWORD="pass" -e POSTGRES_DB="db" -v /tmp/pg-data:/var/lib/postgresql/data --name pg postgres`
2. `docker exec -i pg psql postgresql://user:pass@0.0.0.0:5432/db < scheme.sql`

This will run a local Postgres DB and populate it with data

3. `chalice local`

Or simply `docker compose up -d`


Deploy
------

There should be a one-time configuration of the `.chalice/config.json` file, to set the ENV variables for production.

To deploy from the main branch (having sufficient AWS credentials) just run:

`chalice deploy`


Contribute
----------

After any change you can run `py.test tests/test_app.py` from the root of the project to run all the tests.
If adding more functionality, please add more tests.


Notes
-----

1. I believe in a clean code which leads to no doubts of what it does, so I spared myself some comments.
Usually after reviews of my PR's I add comments if I see anyone struggling to understand something.

2. I implemented the password check using a simple query. I understand there should have been some bcrypt or scrypt,
but it's a bit of a mess deploying binaries from MacOS to Linux. I usually do a deployment docker for this,
but I thought it'd be an overkill here.
