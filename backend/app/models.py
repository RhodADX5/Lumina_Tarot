from sqlalchemy import Column, Integer, String, Boolean, DateTime, JSON, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # --- IDENTIDAD ---
    # device_id: Para invitados que aún no se registran
    device_id = Column(String, unique=True, index=True, nullable=True)
    
    # email y password: Para usuarios registrados
    full_name = Column(String, nullable=True)
    email = Column(String, unique=True, index=True, nullable=True)
    hashed_password = Column(String, nullable=True)
    
    # --- ESTATUS Y NEGOCIO ---
    # "free", "premium_monthly", "premium_yearly"
    plan_status = Column(String, default="free") 
    
    # Saldo de lecturas (para el plan free o paquetes extra)
    credits = Column(Integer, default=3) 
    
    # Fecha de registro
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relación: Un usuario tiene muchas lecturas
    readings = relationship("Reading", back_populates="user")

class Reading(Base):
    __tablename__ = "readings"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    question = Column(String)
    spread_type = Column(String)
    
    # Guardamos los datos técnicos de la tirada
    drawn_cards = Column(JSON) 
    ai_response = Column(JSON) 
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="readings")