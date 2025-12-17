    # ---- Builder Stage ----
    # Use an official Python runtime as a parent image
    FROM python:3.9-slim as builder

    # Set the working directory in the container
    WORKDIR /app

    # Copy the dependencies file and install them
    COPY app/requirements.txt .
    RUN pip install --no-cache-dir -r requirements.txt

    # ---- Final Stage ----
    # Use a smaller, more secure base image for the final container
    FROM python:3.9-slim-bullseye

    # Set the working directory
    WORKDIR /app

    # Copy the installed packages from the builder stage
    COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages

    # Copy the application code
    COPY app/ .

    # Tell Docker that the container listens on port 8080
    EXPOSE 8080

    # Define the command to run your app
    CMD ["python", "main.py"]