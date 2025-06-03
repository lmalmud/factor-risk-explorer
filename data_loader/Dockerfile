# overview: https://docs.docker.com/reference/dockerfile/#overview
# build from base image
FROM python:3.11                                        

# change working directory
WORKDIR /app     
# copies requirements.txt to current                                       
COPY requirements.txt ./
# executes build command                                
RUN pip install --no-cache-dir -r requirements.txt      

# copies load_prices.py to current
COPY load_prices.py ./                                  

# spefecifes default command - to be executed when running container form image
CMD ["python", "load_prices.py"]                        