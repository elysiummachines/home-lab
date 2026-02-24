FROM python:3.13-slim

WORKDIR /app

COPY bot.py .

RUN pip install pyTelegramBotAPI anthropic

CMD ["python", "bot.py"]