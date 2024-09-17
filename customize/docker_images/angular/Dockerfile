# Use the specified JDK 17 image from the AWS ECR
FROM 471112628582.dkr.ecr.eu-central-1.amazonaws.com/openjdk:17-jdk

# Set the working directory in the container
WORKDIR /app

# Copy the JAR file of your Spring Boot application into the container
COPY target/*.jar /app/app.jar

# Define the command to run your Spring Boot application
CMD ["java", "-jar", "app.jar"]