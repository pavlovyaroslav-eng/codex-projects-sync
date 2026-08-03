#!/usr/bin/env python3
import asyncio
import json
import pathlib
import re
import sys

from mcp import ClientSession
from mcp.client.streamable_http import streamable_http_client


def content_text(result) -> str:
    parts = []
    for item in result.content:
        text = getattr(item, "text", None)
        if text is not None:
            parts.append(text)
        else:
            parts.append(json.dumps(item.model_dump(mode="json"), ensure_ascii=False))
    return "\n".join(parts)


async def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("usage: test-ghidra-mcp.py STAGED_DEBUG STAGED_STRIPPED REPORT")
    staged_debug, staged_stripped, report_path = sys.argv[1:]
    calls = []

    async with streamable_http_client("http://127.0.0.1:8000/mcp") as streams:
        read_stream, write_stream = streams[:2]
        async with ClientSession(read_stream, write_stream) as session:
            await session.initialize()

            async def call(name: str, arguments: dict) -> str:
                result = await session.call_tool(name, arguments)
                text = content_text(result)
                calls.append({"tool": name, "arguments": arguments, "isError": bool(result.isError), "result": text})
                if result.isError:
                    raise RuntimeError(f"{name} failed: {text}")
                return text

            debug_prefix = pathlib.Path(staged_debug).name
            stripped_prefix = pathlib.Path(staged_stripped).name
            binaries_text = await call("list_project_binaries", {})

            def binary_names(text: str) -> list[str]:
                try:
                    payload = json.loads(text)
                    return [
                        item["name"].lstrip("/")
                        for item in payload.get("programs", [])
                        if item.get("analysis_complete")
                    ]
                except (json.JSONDecodeError, TypeError, KeyError):
                    return re.findall(r"- /([^\s]+)", text)

            names = binary_names(binaries_text)
            debug_import = "already imported"
            stripped_import = "already imported"
            if not any(name.startswith(debug_prefix) for name in names):
                debug_import = await call("import_binary", {"binary_path": staged_debug})
            if not any(name.startswith(stripped_prefix) for name in names):
                stripped_import = await call("import_binary", {"binary_path": staged_stripped})

            for _ in range(90):
                binaries_text = await call("list_project_binaries", {})
                names = binary_names(binaries_text)
                if any(name.startswith(debug_prefix) for name in names) and any(
                    name.startswith(stripped_prefix) for name in names
                ):
                    break
                await asyncio.sleep(2)
            else:
                raise RuntimeError(f"Imported binaries did not become ready: {binaries_text}")

            debug_name = next(name for name in names if name.startswith(debug_prefix))
            stripped_name = next(name for name in names if name.startswith(stripped_prefix))
            functions = await call(
                "search_symbols_by_name",
                {"binary_name": debug_name, "query": ".*", "functions_only": True, "limit": 100},
            )
            main_search = await call(
                "search_symbols_by_name",
                {"binary_name": debug_name, "query": "^main$", "functions_only": True, "limit": 10},
            )
            add_search = await call(
                "search_symbols_by_name",
                {"binary_name": debug_name, "query": "^add_numbers$", "functions_only": True, "limit": 10},
            )
            imports = await call("list_imports", {"binary_name": debug_name, "limit": 100})
            strings = await call("search_strings", {"binary_name": debug_name, "query": "Result", "limit": 20})
            main_decompile = await call(
                "decompile_function",
                {"binary_name": debug_name, "name_or_address": "main", "include_callees": True, "include_strings": True, "include_xrefs": True},
            )
            add_decompile = await call(
                "decompile_function",
                {"binary_name": debug_name, "name_or_address": "add_numbers", "include_xrefs": True},
            )
            xrefs = await call("list_xrefs", {"binary_name": debug_name, "name_or_address": "add_numbers"})
            comment = await call(
                "set_comment",
                {"binary_name": debug_name, "target": "add_numbers", "comment": "Safe MCP verification: adds two integers.", "comment_type": "decompiler"},
            )
            saved = await call("save", {})
            stripped_main = await call(
                "search_symbols_by_name",
                {"binary_name": stripped_name, "query": "^main$", "functions_only": True, "limit": 10},
            )

    summary = {
        "debug_import": debug_import,
        "stripped_import": stripped_import,
        "project_binaries": binaries_text,
        "function_list": functions,
        "main_search": main_search,
        "add_numbers_search": add_search,
        "imports": imports,
        "strings": strings,
        "main_decompile": main_decompile,
        "add_numbers_decompile": add_decompile,
        "xrefs": xrefs,
        "comment": comment,
        "save": saved,
        "stripped_main_search": stripped_main,
        "calls": calls,
    }
    pathlib.Path(report_path).write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(report_path)


asyncio.run(main())
