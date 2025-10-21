import asyncio
import base64

import cv2
import numpy as np
from loguru import logger
from openai import AsyncOpenAI

MIN = 1_500
MAX = 1_600
ITER = 100
CONCURRENCY = 10
TIMEOUT = 300.0


def mocked_image():
    shape = np.random.randint(MIN, MAX, (2))
    logger.info(f"{shape=}")
    image = np.random.randint(0, 256, (*shape, 3), dtype=np.uint8)
    _, buffer = cv2.imencode(".png", image)
    return base64.b64encode(buffer).decode("utf-8")


async def send_request(client, model, request_id):
    logger.info(f"======= {request_id=} / {ITER} =======")
    image = mocked_image()
    messages = [
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "Describe this image in detail. Please provide as much information as possible.",
                },
                {
                    "type": "image_url",
                    "image_url": {"url": f"data:image/jpeg;base64,{image}"},
                },
            ],
        }
    ]
    response = await client.chat.completions.create(
        model=model, messages=messages, stream=True
    )
    async for chunk in response:
        if not chunk.choices:
            continue
        # print(f"[{request_id}] {chunk.choices[0].delta.content}", end="", flush=True)
    logger.info(f"[{request_id}] Request completed")


async def main():
    client = AsyncOpenAI(
        api_key="null", base_url="http://{VLLM_IP}:8000/v1", timeout=TIMEOUT
    )
    models = await client.models.list()
    model = models.data[0].id

    semaphore = asyncio.Semaphore(CONCURRENCY)

    async def bounded_request(request_id):
        async with semaphore:
            await send_request(client, model, request_id)

    tasks = [bounded_request(i) for i in range(ITER)]
    await asyncio.gather(*tasks)


if __name__ == "__main__":
    asyncio.run(main())
