FROM python:3.10-slim

WORKDIR /app

RUN pip install --no-cache-dir pipenv

COPY Pipfile Pipfile.lock* ./
RUN pipenv install --system --deploy || pip install flask flask-cors

COPY . .

EXPOSE 5000

CMD ["python", "-m", "movies"]
