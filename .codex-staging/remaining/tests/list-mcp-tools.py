#!/usr/bin/env python3
import asyncio
import json

from mcp import ClientSession
from mcp.client.streamable_http import streamable_http_client


async def main() -> None:
    async with streamable_http_client("http://127.0.0.1:8000/mcp") as streams:
        read_stream, write_stream = streams[:2]
        async with ClientSession(read_stream, write_stream) as session:
            await session.initialize()
            result = await session.list_tools()
            print(
                json.dumps(
                    [
                        {"name": tool.name, "description": tool.description, "inputSchema": tool.inputSchema}
                        for tool in result.tools
                    ],
                    ensure_ascii=False,
                    indent=2,
                )
            )


asyncio.run(main())
