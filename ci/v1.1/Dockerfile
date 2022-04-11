FROM quay.io/bitnami/python:3.8.6-prod-debian-10-r81

WORKDIR /code

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY conftest.py create_tables.py music.py test_music.py ./

CMD ["python", "ci_test.py", "s1", "30000", "s2", "30001", "scp756-221"]
