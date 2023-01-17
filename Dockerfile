FROM python

WORKDIR /app

COPY app.py .
COPY req* .
COPY chalicelib chalicelib
COPY .chalice .chalice

RUN pip install -r requirements.txt
RUN pip install chalice

CMD ["/usr/local/bin/chalice", "local", "host", "0.0.0.0", "--port", "3000"]