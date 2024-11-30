import asyncio
import websockets
import os
from datetime import datetime
import ssl  # Import the SSL module

# Create a log file in a folder named with the current date and time
current_time = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
log_dir = f"logs/{current_time}"
os.makedirs(log_dir, exist_ok=True)
log_file_path = os.path.join(log_dir, "client_messages.log")

# Function to write client messages to the log file
def log_client_message(message):
    with open(log_file_path, "a") as log_file:
        log_file.write(f"{message}\n\n")

# WebSocket server handler
async def server_handler(websocket, path):
    print(f"Connection established with {websocket.remote_address}")
    try:
        while True:
            try:
                # Wait for any message from the client
                message = await asyncio.wait_for(websocket.recv(), timeout=30)  # Adjust timeout as needed
                log_client_message(message)  # Log only the client message
                print(f"Received: {message}")

                # Send acknowledgment to the client
                response = f"Server received: {message}"
                await websocket.send(response)
            except asyncio.TimeoutError:
                # Send a ping to the client to check the connection
                await websocket.ping()
                print("Sent keepalive ping")
    except websockets.ConnectionClosed as e:
        print(f"Connection closed: {e}")

# Start the WebSocket server
async def main():
    # Set up SSL context
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_context.load_cert_chain(certfile="certs/cert.pem", keyfile="certs/key.pem")  # Use your certificate and key files

    # Start the WebSocket server with SSL/TLS
    server = await websockets.serve(
        server_handler,
        "10.0.0.1",
        8765,
        ssl=ssl_context,  # Enable SSL/TLS
        ping_interval=None,  # Disable default ping interval
    )
    print("WebSocket server started on wss://10.0.0.1:8765")
    await server.wait_closed()

if __name__ == "__main__":
    asyncio.run(main())
