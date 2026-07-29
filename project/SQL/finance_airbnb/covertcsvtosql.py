import pandas as pd
from sqlalchemy import create_engine

df = pd.read_csv(r"C:\Users\chuqu\Desktop\SQL\listings.csv")

engine = create_engine(
    "mysql+pymysql://root:jhoelito12@localhost:3306/airbnb"
)

df.to_sql("listings", engine, index=False, if_exists="replace")

print("Done!")
