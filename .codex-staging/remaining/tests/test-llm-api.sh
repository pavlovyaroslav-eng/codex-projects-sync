#!/usr/bin/env bash
set -Eeuo pipefail

base_url="${LLM_BASE_URL:-http://127.0.0.1:8012}"
model="${LLM_MODEL:-qwen3-coder-30b-a3b-q4km}"

curl --fail --silent --show-error --max-time 10 "${base_url}/health" | jq -e '.status == "ok"' >/dev/null
curl --fail --silent --show-error --max-time 10 "${base_url}/v1/models" \
    | jq -e --arg model "${model}" '.data[] | select(.id == $model)' >/dev/null

response="$(curl --fail --silent --show-error --max-time 180 \
    -H 'Content-Type: application/json' \
    -d "{\"model\":\"${model}\",\"messages\":[{\"role\":\"system\",\"content\":\"Ты локальный помощник. Отвечай кратко по-русски.\"},{\"role\":\"user\",\"content\":\"Напиши функцию Python add(a, b), возвращающую сумму.\"}],\"max_tokens\":128,\"temperature\":0}" \
    "${base_url}/v1/chat/completions")"
jq -e '.choices[0].message.content | length > 0' <<<"${response}" >/dev/null
printf '%s\n' "${response}" | jq .

stream="$(curl --fail --silent --show-error --max-time 180 --no-buffer \
    -H 'Content-Type: application/json' \
    -d "{\"model\":\"${model}\",\"messages\":[{\"role\":\"user\",\"content\":\"Ответь: поток работает\"}],\"max_tokens\":32,\"temperature\":0,\"stream\":true}" \
    "${base_url}/v1/chat/completions")"
grep -q '^data:' <<<"${stream}"
printf 'LLM_API_TEST=PASS\n'
