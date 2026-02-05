from pydantic import BaseModel
from typing import List, Optional, Dict, Any

# Lo que envía el celular para pedir una lectura
class ReadingRequest(BaseModel):
    user_device_id: str
    question: str
    cards: List[str] # Las cartas que eligió el usuario en el frontend
    spread_type: str = "simple"

# Lo que respondemos (Estructura de Lumina)
class ReadingResponse(BaseModel):
    titulo_lectura: str
    atmosfera_emoji: str
    sintesis_narrativa: str
    consejo_accionable: Optional[str] = None
    frase_talisman: str
    analisis_cartas: List[Dict[str, Any]]