from sqlalchemy.orm import Session
from ..common import models, schemas
from datetime import date

class TableService:
    def __init__(self, db: Session):
        self.db = db

    # --- Tables ---
    def get_tables(self):
        return self.db.query(models.Table).all()

    def create_table(self, table: schemas.TableCreate):
        db_table = models.Table(name=table.name, seat=table.seat)
        self.db.add(db_table)
        self.db.commit()
        self.db.refresh(db_table)
        return db_table

    # --- Reservations ---
    def get_reservations(self):
        return self.db.query(models.Reservation).all()

    def check_availability(self, slot: int, r_date: date, person: int):
        # Find tables with enough seats
        tables = self.db.query(models.Table).filter(models.Table.seat >= person).all()
        available_tables = []
        for table in tables:
            # Check if reserved
            is_reserved = self.db.query(models.Reservation).filter(
                models.Reservation.table_id == table.id,
                models.Reservation.slot == slot,
                models.Reservation.r_date == r_date
            ).first()
            if not is_reserved:
                available_tables.append(table)
        return available_tables

    def create_reservation(self, res: schemas.ReservationCreate, user_id: int):
        # Allow double booking? Assuming no for now based on 'check_availability'
        # Check if already reserved
        existing = self.db.query(models.Reservation).filter(
            models.Reservation.table_id == res.table_id,
            models.Reservation.slot == res.slot,
            models.Reservation.r_date == res.r_date
        ).first()
        if existing:
            return None # Already reserved

        db_res = models.Reservation(**res.dict(), user_id=user_id)
        self.db.add(db_res)
        self.db.commit()
        self.db.refresh(db_res)
        return db_res

    def delete_reservation(self, r_id: int):
        res = self.db.query(models.Reservation).filter(models.Reservation.id == r_id).first()
        if res:
            # Check if waiting list exists for this slot/table/date
            waiting = self.db.query(models.Waiting).filter(
                models.Waiting.table_id == res.table_id,
                models.Waiting.slot == res.slot,
                models.Waiting.r_date == res.r_date
            ).first()
            
            self.db.delete(res)
            
            # Promote waiting to reservation
            if waiting:
                new_res = models.Reservation(
                    user_id=waiting.user_id,
                    table_id=waiting.table_id,
                    slot=waiting.slot,
                    r_date=waiting.r_date
                )
                self.db.add(new_res)
                self.db.delete(waiting)
            
            self.db.commit()
            return True
        return False

    # --- Waiting ---
    def create_waiting(self, wait: schemas.WaitingCreate, user_id: int):
        db_wait = models.Waiting(**wait.dict(), user_id=user_id)
        self.db.add(db_wait)
        self.db.commit()
        self.db.refresh(db_wait)
        return db_wait
