#!/usr/bin/env python3
import asyncio

from mcp import ClientSession
from mcp.client.streamable_http import streamable_http_client


async def main() -> None:
    async with streamable_http_client("http://127.0.0.1:8000/mcp") as streams:
        async with ClientSession(streams[0], streams[1]) as session:
            await session.initialize()
            result = await session.call_tool("list_project_binaries", {})
            print("IS_ERROR", result.isError)
            print("STRUCTURED", repr(result.structuredContent))
            for item in result.content:
                print("CONTENT", repr(getattr(item, "text", item)))


asyncio.run(main())
