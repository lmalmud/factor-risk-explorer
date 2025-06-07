# overview: https://docs.docker.com/reference/dockerfile/#overview
# build from base image
FROM python:3.11                                        

# change working directory
WORKDIR /app     
# copies everything into the app                                      
COPY . ./
# executes build command                                
RUN pip install --no-cache-dir -r requirements.txt                           

# spefecifes default command - to be executed when running container form image
CMD ["python", "main.py", "all"]                        