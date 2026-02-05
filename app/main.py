from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware # <--- ESTO ES NUEVO
from sqlalchemy.orm import Session
from . import models, schemas, database, ai_service

# Crear las tablas en la base de datos al iniciar
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="Lumina Tarot API")

# --- CONFIGURACIÓN DE SEGURIDAD (CORS) ---
# Esto permite que Chrome/Flutter Web hable con el servidor
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # "*" significa: Acepta conexiones de TODOS lados
    allow_credentials=True,
    allow_methods=["*"], # Acepta POST, GET, PUT, etc.
    allow_headers=["*"],
)

# --- ENDPOINT 1: Hacer una lectura ---
@app.post("/api/reading", response_model=schemas.ReadingResponse)
def create_reading(request: schemas.ReadingRequest, db: Session = Depends(database.get_db)):
    
    # 1. Buscar o crear usuario
    user = db.query(models.User).filter(models.User.device_id == request.user_device_id).first()
    if not user:
        user = models.User(device_id=request.user_device_id)
        db.add(user)
        db.commit()
        db.refresh(user)

    # 2. Verificar créditos (Lógica simple para MVP)
    #if user.credits <= 0 and not user.is_premium:
        # Nota: Para pruebas, puedes comentar esta línea si te quedas sin créditos
        #pass 
        # raise HTTPException(status_code=402, detail="Sin créditos cósmicos. Recarga o suscríbete.")

    # 3. Llamar a la IA (Lumina)
    ai_result = ai_service.get_tarot_reading(request.question, request.cards)

    # 4. Guardar en Base de Datos
    new_reading = models.Reading(
        user_id=user.id,
        question=request.question,
        spread_type=request.spread_type,
        drawn_cards=request.cards,
        ai_response=ai_result
    )
    
    # Restar crédito
    if not user.is_premium:
        user.credits -= 1
        
    db.add(new_reading)
    db.add(user) # Actualizar créditos
    db.commit()

    return ai_result

# --- ENDPOINT 2: Ver estado del usuario ---
@app.get("/api/user/{device_id}")
def get_user_status(device_id: str, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.device_id == device_id).first()
    if not user:
        return {"credits": 1, "is_premium": False, "status": "New User"}
    return {"credits": user.credits, "is_premium": user.is_premium}