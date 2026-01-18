from sqlalchemy.orm import Session
from ..common import models, schemas
from datetime import date

class TableService:
    def __init__(self, db: Session):
        self.db = db

    # --- Tables ---
    def get_tables(self, restaurant_id: int = 1):
        return self.db.query(models.Table).filter(models.Table.restaurant_id == restaurant_id).all()

    def create_table(self, table: schemas.TableCreate):
        r_id = table.restaurant_id if table.restaurant_id else 1
        db_table = models.Table(name=table.name, seat=table.seat, restaurant_id=r_id)
        self.db.add(db_table)
        self.db.commit()
        self.db.refresh(db_table)
        return db_table

    # --- Reservations ---
    def get_reservations(self, restaurant_id: int = 1):
        return self.db.query(models.Reservation).filter(models.Reservation.restaurant_id == restaurant_id).all()

    def check_availability(self, slot: int, r_date: date, person: int, restaurant_id: int = 1):
        """
        Return available tables for specific slot/date/restaurant
        """
        # Get all tables for this restaurant linked to reservations for that slot+date
        reserved_table_ids = self.db.query(models.Reservation.table_id).filter(
            models.Reservation.slot == slot,
            models.Reservation.r_date == r_date,
            models.Reservation.restaurant_id == restaurant_id
        ).subquery()

        # Find tables that are NOT in reserved list and match seat count
        available_tables = self.db.query(models.Table).filter(
            models.Table.restaurant_id == restaurant_id,
            models.Table.seat >= person,
            ~models.Table.id.in_(reserved_table_ids)
        ).all()
        
        return available_tables

    def create_reservation(self, res: schemas.ReservationCreate, user_id: int):
        # Verify availability first
        # Note: Ideally call check_availability logic, but for now strict check:
        # Check if table belongs to requested restaurant (if passed) or inherit
        # Assuming table exists.
        
        # Check if slot already taken
        exists = self.db.query(models.Reservation).filter(
            models.Reservation.table_id == res.table_id,
            models.Reservation.slot == res.slot,
            models.Reservation.r_date == res.r_date
        ).first()
        
        if exists:
            return None
            
        r_id = res.restaurant_id if res.restaurant_id else 1
        
        db_res = models.Reservation(
            table_id=res.table_id, 
            slot=res.slot, 
            r_date=res.r_date, 
            user_id=user_id,
            restaurant_id=r_id
        )
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
                    r_date=waiting.r_date,
                    restaurant_id=waiting.restaurant_id
                )
                self.db.add(new_res)
                self.db.delete(waiting)
            
            self.db.commit()
            return True
        return False

    # --- Waiting ---
    def create_waiting(self, wait: schemas.WaitingCreate, user_id: int):
        r_id = wait.restaurant_id if wait.restaurant_id else 1
        
        db_wait = models.Waiting(
            table_id=wait.table_id,
            slot=wait.slot,
            r_date=wait.r_date,
            user_id=user_id,
            restaurant_id=r_id
        )
        self.db.add(db_wait)
        self.db.commit()
        self.db.refresh(db_wait)
        return db_wait
