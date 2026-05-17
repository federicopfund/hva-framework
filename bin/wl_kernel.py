#!/usr/bin/env python3
"""
wl_kernel.py — Jupyter kernel wrapper para Wolfram Language.

Implementa el protocolo Jupyter (jupyter_client) sobre un proceso
wolfram -noinit iniciado localmente. La sincronización usa marcadores
Print únicos para detectar el fin de cada evaluación.

Uso (kernel.json):
  "argv": ["python3", "/workspaces/hva-framework/bin/wl_kernel.py", "-f", "{connection_file}"]
"""

import sys
import os
import uuid
import threading
import queue
import subprocess
import traceback

from ipykernel.kernelbase import Kernel


class WolframKernel(Kernel):
    implementation = "WolframLanguage"
    implementation_version = "1.0"
    language = "Wolfram Language"
    language_version = "14.3"
    language_info = {
        "name": "Wolfram Language",
        "mimetype": "text/x-wolfram",
        "file_extension": ".wl",
        "pygments_lexer": "mathematica",
        "codemirror_mode": "mathematica",
    }
    banner = "Wolfram Language 14 — HVA Framework kernel"

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self._wl_proc = None
        self._stdout_q = queue.Queue()
        self._reader_thread = None
        self._start_wolfram()

    # ------------------------------------------------------------------
    # Proceso Wolfram
    # ------------------------------------------------------------------

    def _start_wolfram(self):
        """Inicia el proceso wolfram y el hilo lector de stdout."""
        self._wl_proc = subprocess.Popen(
            ["/usr/local/bin/wolfram", "-noinit", "-noicon"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            bufsize=0,
        )
        self._reader_thread = threading.Thread(
            target=self._stdout_reader, daemon=True
        )
        self._reader_thread.start()
        # Drena el banner de inicio (espera al primer prompt "In[1]:=")
        self._drain_until_prompt(timeout=60)

    def _stdout_reader(self):
        """Lee stdout del proceso byte a byte y encola líneas completas."""
        buf = ""
        while True:
            ch = self._wl_proc.stdout.read(1)
            if not ch:
                break
            ch = ch.decode("utf-8", errors="replace")
            if ch == "\n":
                self._stdout_q.put(buf + "\n")
                buf = ""
            else:
                buf += ch
        if buf:
            self._stdout_q.put(buf)

    def _drain_until_prompt(self, timeout=30):
        """Descarta output hasta ver un prompt 'In[N]:='."""
        import time
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                line = self._stdout_q.get(timeout=0.5)
                if "In[" in line and "]:=" in line:
                    return
            except queue.Empty:
                continue

    def _collect_until_marker(self, marker, timeout=120):
        """
        Recopila líneas hasta ver el marcador impreso.
        Devuelve (output_lines, error_lines).
        """
        import time
        lines = []
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                line = self._stdout_q.get(timeout=0.5)
            except queue.Empty:
                continue
            # El marcador aparece como: MARKER\n  o al final de un prompt
            if marker in line:
                break
            # Filtrar prompts del kernel (In[N]:= , Out[N]= )
            if line.startswith("In[") and "]:=" in line:
                continue
            if line.startswith("Out[") and "]=" in line:
                # La línea de Out incluye el resultado; la conservamos
                # pero quitamos "Out[N]= " del prefijo
                idx = line.index("]=") + 2
                result = line[idx:].lstrip()
                if result.strip():
                    lines.append(result)
                continue
            lines.append(line)
        return lines

    def _send(self, code: str):
        """Envía una línea al stdin del proceso wolfram."""
        self._wl_proc.stdin.write((code + "\n").encode("utf-8"))
        self._wl_proc.stdin.flush()

    # ------------------------------------------------------------------
    # Protocolo Jupyter
    # ------------------------------------------------------------------

    def do_execute(
        self,
        code,
        silent,
        store_history=True,
        user_expressions=None,
        allow_stdin=False,
    ):
        if not code.strip():
            return {
                "status": "ok",
                "execution_count": self.execution_count,
                "payload": [],
                "user_expressions": {},
            }

        marker = "HVA_DONE_" + uuid.uuid4().hex

        # Enviar el código del usuario
        self._send(code)
        # Enviar el marcador como evaluación separada
        self._send(f'Print["{marker}"]')

        # Recopilar output
        output_lines = self._collect_until_marker(marker)

        if not silent:
            text = "".join(output_lines).rstrip()
            if text:
                self.send_response(
                    self.iopub_socket,
                    "stream",
                    {"name": "stdout", "text": text + "\n"},
                )

        return {
            "status": "ok",
            "execution_count": self.execution_count,
            "payload": [],
            "user_expressions": {},
        }

    def do_complete(self, code, cursor_pos):
        return {
            "status": "ok",
            "matches": [],
            "cursor_start": cursor_pos,
            "cursor_end": cursor_pos,
            "metadata": {},
        }

    def do_shutdown(self, restart):
        if self._wl_proc:
            try:
                self._wl_proc.terminate()
            except Exception:
                pass
        return {"status": "ok", "restart": restart}


if __name__ == "__main__":
    from ipykernel.kernelapp import IPKernelApp
    IPKernelApp.launch_instance(kernel_class=WolframKernel)
