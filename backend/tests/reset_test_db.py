from sqlalchemy import create_engine, text
import os

TEST_DATABASE_URL = os.getenv("TEST_DATABASE_URL", "postgresql://admin:admin@localhost/local_eats_test_db")
engine = create_engine(TEST_DATABASE_URL)

with engine.connect() as con:
    con.execute(text("DROP SCHEMA public CASCADE;"))
    con.execute(text("CREATE SCHEMA public;"))
    con.commit()
    print("Test DB Reset Complete")
