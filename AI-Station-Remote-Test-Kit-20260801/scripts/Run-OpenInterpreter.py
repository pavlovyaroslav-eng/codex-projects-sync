"""Start Open Interpreter against the HomeTele OpenAI-compatible endpoint."""

from interpreter import interpreter


interpreter.offline = True
interpreter.llm.model = "openai/qwen3-14b-q4km"
interpreter.llm.api_base = "http://10.93.0.10:8080/v1"
interpreter.llm.api_key = "local-vpn"
interpreter.llm.context_window = 8192
interpreter.llm.max_tokens = 2048
interpreter.llm.temperature = 0
interpreter.llm.supports_functions = False
interpreter.llm.supports_vision = False
interpreter.auto_run = False

print("HomeTele AI / Qwen3-14B")
print("The model is remote. Generated code executes on this computer after approval.")
print("Do not approve commands you do not understand. Press Ctrl+C to exit.\n")

interpreter.chat()

