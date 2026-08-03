#!/usr/bin/env python3
import html
import json
import logging
import subprocess
import time

import requests

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)


def load_conf(path="/etc/hometele-ai.conf"):
    data = {}
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, value = line.split("=", 1)
        data[key] = value.strip().strip('"')
    return data


cfg = load_conf()
MATRIX_SERVER = cfg["MATRIX_SERVER"]
MATRIX_USER = cfg["MATRIX_USER"]
MATRIX_PASSWORD = cfg["MATRIX_PASSWORD"]
ALLOWED_USER = cfg["ALLOWED_USER"]
LOCAL_AI_BASE_URL = cfg.get("LOCAL_AI_BASE_URL", "http://10.93.0.10:8080/v1").rstrip("/")
LOCAL_AI_MODEL = cfg.get("LOCAL_AI_MODEL", "qwen3-coder-30b-a3b-q4km")
MODEL_INFO = (
    "Сейчас работает Qwen3-Coder-30B-A3B-Instruct Q4_K_M "
    "(`qwen3-coder-30b-a3b-q4km`) на локальной ИИ-станции. "
    "Это не Qwen3-14B."
)

session = requests.Session()


def login():
    response = session.post(
        f"{MATRIX_SERVER}/_matrix/client/v3/login",
        json={
            "type": "m.login.password",
            "user": MATRIX_USER,
            "password": MATRIX_PASSWORD,
        },
        timeout=20,
    )
    response.raise_for_status()
    data = response.json()
    logging.info("Logged in as %s", data.get("user_id"))
    return data["access_token"]


TOKEN = login()
HEADERS = {"Authorization": f"Bearer {TOKEN}"}


def send(room_id, text):
    txn = str(time.time_ns())
    body = {
        "msgtype": "m.text",
        "body": text,
        "format": "org.matrix.custom.html",
        "formatted_body": "<pre>" + html.escape(text) + "</pre>",
    }
    response = session.put(
        f"{MATRIX_SERVER}/_matrix/client/v3/rooms/{room_id}/send/m.room.message/{txn}",
        headers=HEADERS,
        json=body,
        timeout=20,
    )
    if response.status_code >= 300:
        logging.error("Send failed %s %s", response.status_code, response.text[:300])


def join_room(room_id):
    response = session.post(
        f"{MATRIX_SERVER}/_matrix/client/v3/rooms/{room_id}/join",
        headers=HEADERS,
        json={},
        timeout=20,
    )
    if response.status_code < 300:
        logging.info("Joined room %s", room_id)
        send(room_id, "🤖 HomeTele AI подключился к локальному Qwen.\nНапиши !help")
    else:
        logging.error("Join failed %s %s", response.status_code, response.text[:300])


def ask_local_ai(prompt):
    system = (
        "Ты HomeTele AI, корпоративный помощник администратора. "
        "Отвечай по-русски, кратко и практично. "
        "Если задача опасная для сервера, не выполняй её, а попроси подтверждение. "
        "Ты работаешь через локальную модель "
        "Qwen3-Coder-30B-A3B-Instruct Q4_K_M с идентификатором "
        "qwen3-coder-30b-a3b-q4km на ИИ-станции HomeTele. "
        "Никогда не называй себя Qwen3-14B."
    )
    response = requests.post(
        f"{LOCAL_AI_BASE_URL}/chat/completions",
        headers={"Content-Type": "application/json"},
        json={
            "model": LOCAL_AI_MODEL,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.3,
            "max_tokens": 1200,
        },
        timeout=300,
    )
    if response.status_code != 200:
        return f"Ошибка локального AI API: HTTP {response.status_code}\n{response.text[:1000]}"
    return response.json()["choices"][0]["message"]["content"]


def handle_command(room_id, sender, body):
    if sender != ALLOWED_USER:
        logging.info("Ignored message from %s", sender)
        return

    text = body.strip()
    logging.info("Command from %s in %s: %s", sender, room_id, text[:80])

    if text in ("!help", "help", "помощь"):
        send(
            room_id,
            """🤖 HomeTele AI — локальный Qwen3-Coder

Команды:
!ai текст вопроса
!model
!status
!backup

Пример:
!ai напиши короткую инструкцию для нового сотрудника Matrix""",
        )
        return

    if text in ("!model", "/model", "модель"):
        send(room_id, MODEL_INFO)
        return

    if text == "!status":
        out = subprocess.getoutput(
            "systemctl is-active nginx matrix-synapse coturn docker fail2ban ufw; "
            "df -h /; free -h"
        )
        send(room_id, "📊 Статус сервера:\n\n" + out)
        return

    if text == "!backup":
        out = subprocess.getoutput("/usr/local/bin/matrix-local-backup 2>&1 | tail -80")
        send(room_id, "💾 Бэкап Matrix:\n\n" + out)
        return

    if text.startswith("!ai "):
        prompt = text[4:].strip()
        if not prompt:
            send(room_id, "Напиши вопрос после !ai")
            return
        normalized = prompt.casefold()
        if any(
            phrase in normalized
            for phrase in ("какая модель", "какую модель", "что за модель", "твоя модель")
        ):
            send(room_id, MODEL_INFO)
            return
        send(room_id, "🤖 Думаю на локальной ИИ-станции...")
        answer = ask_local_ai(prompt)
        send(room_id, answer)


def initial_sync():
    """Advance to the current Matrix token without replaying old commands."""
    response = session.get(
        f"{MATRIX_SERVER}/_matrix/client/v3/sync",
        headers=HEADERS,
        params={"timeout": 0},
        timeout=20,
    )
    response.raise_for_status()
    return response.json().get("next_batch")


def main():
    next_batch = initial_sync()
    logging.info("Initial Matrix sync completed; waiting for new commands")

    while True:
        try:
            params = {"timeout": 30000}
            if next_batch:
                params["since"] = next_batch

            response = session.get(
                f"{MATRIX_SERVER}/_matrix/client/v3/sync",
                headers=HEADERS,
                params=params,
                timeout=45,
            )
            response.raise_for_status()
            data = response.json()
            next_batch = data.get("next_batch", next_batch)

            invites = data.get("rooms", {}).get("invite", {})
            for room_id in invites.keys():
                logging.info("Invite received for %s", room_id)
                join_room(room_id)

            rooms = data.get("rooms", {}).get("join", {})
            for room_id, room in rooms.items():
                events = room.get("timeline", {}).get("events", [])
                for event in events:
                    if event.get("type") != "m.room.message":
                        continue
                    sender = event.get("sender")
                    content = event.get("content", {})
                    if content.get("msgtype") != "m.text":
                        continue
                    if sender == MATRIX_USER:
                        continue
                    handle_command(room_id, sender, content.get("body", ""))

        except Exception:
            logging.exception("Loop error")
            time.sleep(5)


if __name__ == "__main__":
    main()
