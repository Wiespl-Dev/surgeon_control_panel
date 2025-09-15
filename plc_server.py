import asyncio
import websockets
import signal
import logging
import sys
from websockets.exceptions import ConnectionClosed
from aiohttp import web
from aiohttp.web_middlewares import middleware

# ========== Logging Setup ==========
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger("PLC-WebSocket")

# ========== Global State ==========
connected_clients = set()
latest_state = None  # Store the last full payload to send to new clients

# ========== Message Validation ==========
def is_valid_message(message: str) -> bool:
    """Check if the message follows the expected PLC format."""
    return message.startswith("{,") and message.endswith("}")

# ========== WebSocket Handler ==========
async def handler(websocket):
    client_ip = websocket.remote_address[0]

    if websocket not in connected_clients:
        logger.info(f"New client connected: {client_ip}")
        connected_clients.add(websocket)

    # Send the latest state to the new client, if available
    if latest_state:
        try:
            await websocket.send(latest_state)
        except Exception as e:
            logger.error(f"Error sending initial state to {client_ip}: {e}")

    try:
        async for message in websocket:
            logger.info(f"Received from {client_ip}: {message}")
            if is_valid_message(message):
                await broadcast(message)
            else:
                logger.warning(f"Invalid message format received from {client_ip}: {message}")
    except ConnectionClosed:
        logger.info(f"Client disconnected: {client_ip}")
    finally:
        connected_clients.discard(websocket)

# ========== Broadcast ==========
async def broadcast(message):
    global latest_state
    latest_state = message
    disconnected_clients = set()

    for client in connected_clients:
        try:
            await client.send(message)
        except ConnectionClosed:
            disconnected_clients.add(client)

    connected_clients.difference_update(disconnected_clients)

# ========== HTTP CORS Middleware ==========
@middleware
async def cors_middleware(request, handler):
    response = await handler(request)
    response.headers['Access-Control-Allow-Origin'] = '*'
    return response

# ========== HTTP Info API ==========
async def http_info_handler(request):
    return web.json_response({
        "connected_clients": len(connected_clients),
        "latest_state": latest_state
    })

async def start_http_server():
    app = web.Application(middlewares=[cors_middleware])
    app.add_routes([web.get('/info', http_info_handler)])
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, '0.0.0.0', 8081)  # <-- Changed to 0.0.0.0 for HTTP
    await site.start()
    logger.info("HTTP server running at http://192.168.0.43:8081/info")

# ========== Main Server ==========
async def main():
    logger.info("WebSocket server starting on ws://0.0.0.0:8080")  # <-- Log updated
    try:
        async with websockets.serve(
            handler,
            "0.0.0.0",  # <-- Changed to 0.0.0.0 for WebSocket
            8080,
            ping_interval=20,     # keep-alive
            ping_timeout=10
        ):
            await start_http_server()
            await asyncio.Future()  # run forever
    finally:
        logger.info("WebSocket server shutting down...")

# ========== Graceful Shutdown ==========
def shutdown():
    logger.info("Shutting down gracefully...")
    for task in asyncio.all_tasks():
        task.cancel()
    sys.exit(0)

# ========== Entry ==========
if __name__ == "__main__":
    signal.signal(signal.SIGINT, lambda s, f: shutdown())
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Server manually stopped.")
