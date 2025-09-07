import tkinter as tk
from tkinter import ttk
import serial
import time

# === PLANTILLAS BASE ===

PLANTILLA_SUMA = [
    0x0E, 0x2F, 0x5E, 0x60,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x04, 0x01
]

PLANTILLA_RESTA = [
    0x0E, 0x3F, 0x5E, 0x60,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x04, 0x01
]

# === CONFIGURACIÓN DE VENTANA ===

root = tk.Tk()
root.title("Editor y Envío de Instrucciones")
root.geometry("550x400")
root.resizable(False, False)

resultado = tk.StringVar()
estado_serial = tk.StringVar()
entry_personalizados = []

# === FUNCIONES ===

def actualizar_visibilidad_personalizado(event=None):
    operacion = combo_operacion.get()
    if operacion == "Personalizada":
        frame_personalizado.pack()
        frame_operandos.pack_forget()
    else:
        frame_personalizado.pack_forget()
        frame_operandos.pack()

def obtener_instrucciones():
    operacion = combo_operacion.get()

    if operacion == "Suma":
        instrucciones = PLANTILLA_SUMA.copy()
    elif operacion == "Resta":
        instrucciones = PLANTILLA_RESTA.copy()
    else:
        instrucciones = []
        try:
            for entry in entry_personalizados:
                val = entry.get().strip()
                # Eliminamos el prefijo '0x' si el usuario lo incluye, y procesamos la entrada como hexadecimal.
                if val.startswith("0x"):
                    val = val[2:]  # Elimina el prefijo '0x' para poder convertir el valor correctamente
                # Convertimos el valor como hexadecimal
                byte = int(val, 16)  
                if not (0 <= byte <= 255):
                    raise ValueError
                instrucciones.append(byte)
        except ValueError:
            resultado.set("Valores inválidos en personalizado.")
            return None
        if len(instrucciones) != 16:
            resultado.set("Debes ingresar 16 valores.")
            return None
        return instrucciones

    # Suma o resta: ajustar operandos
    try:
        op1 = int(entry_op1.get())
        op2 = int(entry_op2.get())
        if 0 <= op1 <= 255 and 0 <= op2 <= 255:
            instrucciones[14] = op1
            instrucciones[15] = op2
        else:
            resultado.set("Operandos fuera de rango.")
            return None
    except ValueError:
        resultado.set("Operandos inválidos.")
        return None

    return instrucciones

def actualizar_instrucciones():
    instrucciones = obtener_instrucciones()
    if instrucciones is None:
        return
    resultado.set(", ".join(f"0x{b:02X}" for b in instrucciones))

def enviar_por_serial():
    instrucciones = obtener_instrucciones()
    if instrucciones is None:
        estado_serial.set("❌ Error: instrucciones no válidas")
        return

    puerto = entry_puerto.get().strip()
    if not puerto:
        estado_serial.set("❌ Especifica un puerto COM (ej. COM3)")
        return

    # Verifica si alguna instrucción inicia con 0x4X
    inicia_con_4 = any((inst & 0xF0) == 0x40 for inst in instrucciones)
    flag = 0x01 if inicia_con_4 else 0x00

    paquete = [0xAA] + instrucciones + [flag] + [0xFF]

    try:
        ser = serial.Serial(puerto, 9600, timeout=1)
        time.sleep(2)
        ser.write(bytes(paquete))
        ser.close()
        estado_serial.set(f"✅ Instrucciones enviadas por {puerto}")
    except Exception as e:
        estado_serial.set(f"❌ Error al enviar: {e}")


# === INTERFAZ ===

# Frame para puerto COM
frame_puerto = tk.Frame(root, pady=10)
frame_puerto.pack()
tk.Label(frame_puerto, text="Puerto COM:").pack(side="left", padx=5)
entry_puerto = tk.Entry(frame_puerto, width=10)
entry_puerto.pack(side="left")
entry_puerto.insert(0, "COM10")  # Valor por defecto

# Frame para selección de operación
frame_op = tk.Frame(root, pady=10)
frame_op.pack()
tk.Label(frame_op, text="Operación:").pack(side="left", padx=5)
combo_operacion = ttk.Combobox(frame_op, values=["Suma", "Resta", "Personalizada"], width=15)
combo_operacion.pack(side="left")
combo_operacion.current(0)
combo_operacion.bind("<<ComboboxSelected>>", actualizar_visibilidad_personalizado)

# Frame operandos
frame_operandos = tk.Frame(root, pady=10)
frame_operandos.pack()

tk.Label(frame_operandos, text="Operando 1 (bit 14):").grid(row=0, column=0, padx=5, pady=5, sticky="e")
entry_op1 = tk.Entry(frame_operandos, width=10)
entry_op1.grid(row=0, column=1, padx=5)
entry_op1.insert(0, "00")

tk.Label(frame_operandos, text="Operando 2 (bit 15):").grid(row=1, column=0, padx=5, pady=5, sticky="e")
entry_op2 = tk.Entry(frame_operandos, width=10)
entry_op2.grid(row=1, column=1, padx=5)
entry_op2.insert(0, "00")

# Frame personalizado (16 entradas)
frame_personalizado = tk.Frame(root, pady=10)
for i in range(16):
    tk.Label(frame_personalizado, text=f"B{i:02}").grid(row=i//4, column=(i % 4)*2, padx=3, pady=3)
    entry = tk.Entry(frame_personalizado, width=5)
    entry.grid(row=i//4, column=(i % 4)*2 + 1, padx=3)
    entry.insert(0, "00")
    entry_personalizados.append(entry)
frame_personalizado.pack_forget()  # Ocultar al inicio

# Botones centrados
frame_botones = tk.Frame(root, pady=15)
frame_botones.pack()
tk.Button(frame_botones, text="Generar Instrucciones", command=actualizar_instrucciones, width=20).pack(side="left", padx=10)
tk.Button(frame_botones, text="Enviar por Serial", command=enviar_por_serial, width=20).pack(side="left", padx=10)

# Resultado
frame_resultado = tk.Frame(root)
frame_resultado.pack(pady=10)
tk.Label(frame_resultado, text="Instrucciones generadas:").pack()
tk.Label(frame_resultado, textvariable=resultado, wraplength=500, justify="left", fg="black").pack()

# Estado del puerto serial
tk.Label(root, textvariable=estado_serial, fg="blue").pack(pady=5)

# Inicializar visibilidad
actualizar_visibilidad_personalizado()

# Iniciar la app
root.mainloop()
