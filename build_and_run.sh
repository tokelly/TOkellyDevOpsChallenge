# builds the Docker image
docker build -t log-report-app .
# runs the container (serves on http://localhost:8080)
docker run -d --name log-report-app -p 8080:80 log-report-app