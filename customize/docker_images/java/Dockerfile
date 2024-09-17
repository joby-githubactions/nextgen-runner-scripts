# Use the specified JDK 17 image from the AWS ECR
FROM ##BASE_IMAGE##

# Create a group and user for the application
RUN groupadd -r nextgenapp && useradd -r -u 1000 -g nextgenapp -m -s /bin/sh nextgenapp

# Set the working directory in the container
WORKDIR /app

# Copy the JAR file of your Spring Boot application into the container
COPY target/*.jar /app/app.jar

# Change the ownership of the entire /app directory to the new user
RUN chown -R nextgenapp:nextgenapp /app

# Switch to the new user
USER nextgenapp

# Define the command to run your Spring Boot application
CMD ["java", "-jar", "app.jar"]