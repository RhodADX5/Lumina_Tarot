import google.generativeai as genai
import os
from dotenv import load_dotenv

# Cargar la llave
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=api_key)

print(f"--- Usando API Key: {api_key[:10]}... ---")
print("Consultando a Google qué modelos tienes disponibles...\n")

try:
    # Listar todos los modelos disponibles para tu llave
    for m in genai.list_models():
        # Solo queremos los que sirven para generar texto (chat)
        if 'generateContent' in m.supported_generation_methods:
            print(f"- {m.name}")
            
except Exception as e:
    print(f"❌ Error fatal: {e}")