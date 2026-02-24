import telebot
import anthropic
import os

TELEGRAM_TOKEN = os.environ["TELEGRAM_TOKEN"]
CLAUDE_API_KEY = os.environ["CLAUDE_API_KEY"]

bot = telebot.TeleBot(TELEGRAM_TOKEN)
client = anthropic.Anthropic(api_key=CLAUDE_API_KEY)

conversation_history = {}

@bot.message_handler(commands=['cld'])
def handle_claude(message):
    prompt = message.text.replace('/cld', '').strip()
    if not prompt:
        bot.reply_to(message, "Please add a question after /cld")
        return

    chat_id = message.chat.id
    if chat_id not in conversation_history:
        conversation_history[chat_id] = []

    conversation_history[chat_id].append({"role": "user", "content": prompt})
    conversation_history[chat_id] = conversation_history[chat_id][-5:]

    # Ensure history always ends with a user message
    if conversation_history[chat_id][-1]["role"] != "user":
        conversation_history[chat_id] = [{"role": "user", "content": prompt}]

    try:
        bot.reply_to(message, "Thinking...")
    except Exception:
        pass

    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        messages=conversation_history[chat_id]
    )

    reply = response.content[0].text
    conversation_history[chat_id].append({"role": "assistant", "content": reply})

    try:
        bot.reply_to(message, reply)
    except Exception:
        bot.send_message(chat_id, reply)

@bot.message_handler(commands=['cld_reset'])
def reset(message):
    conversation_history[message.chat.id] = []
    bot.reply_to(message, "Conversation reset!")

bot.infinity_polling()