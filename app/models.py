from sqlalchemy import Column, Integer, String, Boolean, DateTime, JSON, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String, unique=True, index=True) # ID único del celular
    is_premium = Column(Boolean, default=False)
    credits = Column(Integer, default=1) # 1 tirada gratis al inicio
    created_at = Column(DateTime, default=datetime.utcnow)
    
    readings = relationship("Reading", back_populates="user")

class Reading(Base):
    __tablename__ = "readings"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    question = Column(String)
    spread_type = Column(String) # "simple", "cruz_celta"
    
    # Guardamos listas y diccionarios como JSON
    drawn_cards = Column(JSON) # Ej: ["El Loco", "El Mago"]
    ai_response = Column(JSON) # El JSON completo que devuelve Lumina
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="readings")