# Use the official Tomcat image as the base image
# https://hub.docker.com/_/tomcat/tags
FROM tomcat:10.1.39-jdk21

# Set the working directory inside the container
WORKDIR /usr/local/tomcat/webapps/

# Copy the Spring Boot WAR file into the Tomcat webapps directory
COPY ./src/demo/build/libs/demo.war demo.war

# TimeZone:Asia/Tokyoに変更
#  - Aurora:TimeZoneも変更される
ENV TZ=Asia/Tokyo

# Expose the default Tomcat port
EXPOSE 8080

# Tomcat will automatically deploy the WAR file, so no additional ENTRYPOINT is needed
