FROM python:3.9-slim-buster
WORKDIR /app
COPY requirements.txt .
RUN pip install --trusted-host pypi.python.org -r requirements.txt
COPY app.py .
COPY test.db .
EXPOSE 5000
CMD ["python", "app.py"]
