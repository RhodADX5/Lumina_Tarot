from pydantic import BaseModel, EmailStr
from typing import List, Optional, Dict, Any

# --- ESQUEMAS DE USUARIO ---

# Para registrarse
class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    device_id: Optional[str] = None # Para vincular su historial de invitado

# Para hacer Login
class UserLogin(BaseModel):
    email: EmailStr
    password: str

# Para responder con datos del usuario (sin devolver la contraseña)
class UserDisplay(BaseModel):
    id: int
    full_name: Optional[str]
    email: Optional[str]
    plan_status: str
    credits: int

    class Config:
        from_attributes = True

# --- ESQUEMAS DE LECTURA ---
class ReadingRequest(BaseModel):
    user_device_id: Optional[str] = None # Puede ser nulo si el usuario ya hizo login (id real)
    user_id: Optional[int] = None        # ID real de base de datos
    question: str
    cards: List[str]
    spread_type: str = "simple"

class ReadingResponse(BaseModel):
    titulo_lectura: str
    atmosfera_emoji: str
    sintesis_narrativa: str
    consejo_accionable: Optional[str] = None
    frase_talisman: str
    analisis_cartas: List[Dict[str, Any]]