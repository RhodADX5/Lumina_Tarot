import google.generativeai as genai
import json
import os
import re 
from dotenv import load_dotenv

load_dotenv()

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# --- CAMBIO AQUÍ: Usamos el modelo que sí tienes en tu lista ---
# Usamos el alias genérico, que suele apuntar al modelo estable gratuito
model = genai.GenerativeModel('models/gemini-flash-latest')

SYSTEM_PROMPT = """
ACTÚA COMO "LUMINA", UNA TAROTISTA MÍSTICA.

Tu tarea es interpretar una tirada de tarot y DEVOLVER SOLO UN OBJETO JSON VÁLIDO.
NO escribas nada fuera del JSON (ni "aquí tienes", ni comillas ```json).

El formato JSON debe ser exactamente así:
{
  "titulo_lectura": "Título corto y místico",
  "atmosfera_emoji": "🔮",
  "analisis_cartas": [
    {"carta": "Nombre Carta", "mensaje_clave": "Frase corta", "interpretacion_directa": "Significado"}
  ],
  "sintesis_narrativa": "Interpretación completa y empática conectando las cartas.",
  "consejo_accionable": "Un consejo práctico.",
  "frase_talisman": "Una frase corta."
}
"""

def get_tarot_reading(question: str, cards: list):
    try:
        prompt_usuario = f"""
        {SYSTEM_PROMPT}
        
        --- DATOS DE LA LECTURA ---
        Pregunta del usuario: "{question}"
        Cartas: {', '.join(cards)}
        
        RESPONDE SOLO CON EL JSON:
        """

        response = model.generate_content(prompt_usuario)
        texto_respuesta = response.text

        # Limpiar bloques de código Markdown si la IA los pone
        texto_limpio = re.sub(r"```json|```", "", texto_respuesta).strip()

        return json.loads(texto_limpio)

    except Exception as e:
        print(f"Error Gemini: {e}")
        return {
            "titulo_lectura": "Interferencia Cósmica",
            "atmosfera_emoji": "⚡",
            "sintesis_narrativa": f"Error técnico: {str(e)}",
            "analisis_cartas": [],
            "consejo_accionable": "Intenta de nuevo.",
            "frase_talisman": "El universo se recalibra."
        }