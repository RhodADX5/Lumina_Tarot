from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from . import models, schemas, database, ai_service, security

# Crear tablas (Esto se ejecutará en Render y creará la estructura nueva en Postgres)
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="Lumina Tarot API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- ENDPOINT REGISTRO ---
@app.post("/api/register", response_model=schemas.UserDisplay)
def register_user(user_data: schemas.UserCreate, db: Session = Depends(database.get_db)):
    # 1. Verificar si el email ya existe
    existing_user = db.query(models.User).filter(models.User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Este correo ya está registrado.")

    # 2. Si tenía historial como invitado (device_id), lo actualizamos
    # Si no, creamos uno nuevo.
    user = None
    if user_data.device_id:
        user = db.query(models.User).filter(models.User.device_id == user_data.device_id).first()
    
    if user:
        # Actualizamos el usuario invitado a usuario registrado
        user.email = user_data.email
        user.full_name = user_data.full_name
        user.hashed_password = security.get_password_hash(user_data.password)
        # Le regalamos créditos extra por registrarse
        user.credits += 5 
    else:
        # Usuario nuevo desde cero
        user = models.User(
            full_name=user_data.full_name,
            email=user_data.email,
            hashed_password=security.get_password_hash(user_data.password),
            credits=5 # Bono de bienvenida
        )
        db.add(user)

    db.commit()
    db.refresh(user)
    return user

# --- ENDPOINT LOGIN ---
@app.post("/api/login", response_model=schemas.UserDisplay)
def login_user(login_data: schemas.UserLogin, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.email == login_data.email).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")
    
    if not security.verify_password(login_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Contraseña incorrecta.")
    
    return user

# --- ENDPOINT LECTURA (ACTUALIZADO PARA SOPORTAR LOGIN) ---
@app.post("/api/reading", response_model=schemas.ReadingResponse)
def create_reading(request: schemas.ReadingRequest, db: Session = Depends(database.get_db)):
    
    user = None
    
    # Caso A: Usuario Logueado (tiene user_id)
    if request.user_id:
        user = db.query(models.User).filter(models.User.id == request.user_id).first()
    
    # Caso B: Usuario Invitado (tiene device_id)
    elif request.user_device_id:
        user = db.query(models.User).filter(models.User.device_id == request.user_device_id).first()
        if not user:
            user = models.User(device_id=request.user_device_id)
            db.add(user)
            db.commit()
            db.refresh(user)
    
    if not user:
        raise HTTPException(status_code=400, detail="No se pudo identificar al usuario.")

    # Lógica de créditos
    if user.credits <= 0 and user.plan_status == "free":
        # Aquí lanzaremos el error para que el Frontend muestre la pantalla de pago
        pass 
        # raise HTTPException(status_code=402, detail="Sin créditos.")

    # IA
    ai_result = ai_service.get_tarot_reading(request.question, request.cards)

    # Guardar
    new_reading = models.Reading(
        user_id=user.id,
        question=request.question,
        spread_type=request.spread_type,
        drawn_cards=request.cards,
        ai_response=ai_result
    )
    
    if user.plan_status == "free":
        user.credits -= 1
        
    db.add(new_reading)
    db.add(user)
    db.commit()

    return ai_result