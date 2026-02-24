import os
import requests
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes

TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN")
SONARR_URL = os.getenv("SONARR_URL")
SONARR_API_KEY = os.getenv("SONARR_API_KEY")
ALLOWED_USER = int(os.getenv("TELEGRAM_ALLOWED_USER"))

def sonarr_headers():
    return {"X-Api-Key": SONARR_API_KEY}

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user.id != ALLOWED_USER:
        return
    await update.message.reply_text(
        "Commands:\n"
        "/search <show>\n"
        "/add <show> <1080p|4k>\n"
        "/addanime <show> <1080p|4k>\n"
        "/status"
    )

async def search(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user.id != ALLOWED_USER:
        return
    query = " ".join(context.args)
    if not query:
        await update.message.reply_text("Usage: /search <show name>")
        return
    r = requests.get(f"{SONARR_URL}/api/v3/series/lookup?term={query}", headers=sonarr_headers())
    results = r.json()[:5]
    if not results:
        await update.message.reply_text("No results found.")
        return
    msg = ""
    for i, s in enumerate(results):
        msg += f"{i+1}. {s['title']} ({s.get('year', 'N/A')})\n"
    await update.message.reply_text(msg)

async def add_show(update: Update, context: ContextTypes.DEFAULT_TYPE, root_folder: str):
    if update.effective_user.id != ALLOWED_USER:
        return
    if len(context.args) < 2:
        await update.message.reply_text(f"Usage: /add <show name> <1080p|4k>")
        return
    quality = context.args[-1].lower()
    query = " ".join(context.args[:-1])
    if quality == "4k":
        profile_id = 5
    elif quality == "1080p":
        profile_id = 4
    else:
        await update.message.reply_text("Quality must be 1080p or 4k")
        return
    r = requests.get(f"{SONARR_URL}/api/v3/series/lookup?term={query}", headers=sonarr_headers())
    results = r.json()
    if not results:
        await update.message.reply_text("No results found.")
        return
    show = results[0]
    payload = {
        "title": show["title"],
        "tvdbId": show["tvdbId"],
        "qualityProfileId": profile_id,
        "rootFolderPath": root_folder,
        "monitored": True,
        "addOptions": {"searchForMissingEpisodes": True}
    }
    r = requests.post(f"{SONARR_URL}/api/v3/series", json=payload, headers=sonarr_headers())
    if r.status_code == 201:
        await update.message.reply_text(f"Added {show['title']} ({quality}) to Sonarr.")
    else:
        await update.message.reply_text(f"Failed to add: {r.text}")

async def add(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await add_show(update, context, "/shows")

async def addanime(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await add_show(update, context, "/anime-shows")

async def status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user.id != ALLOWED_USER:
        return
    r = requests.get(f"{SONARR_URL}/api/v3/queue", headers=sonarr_headers())
    items = r.json().get("records", [])
    if not items:
        await update.message.reply_text("Nothing downloading.")
        return
    msg = ""
    for item in items[:5]:
        pct = round((1 - item.get("sizeleft", 0) / item.get("size", 1)) * 100)
        msg += f"{item['title']} - {pct}%\n"
    await update.message.reply_text(msg)

if __name__ == "__main__":
    app = Application.builder().token(TELEGRAM_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("search", search))
    app.add_handler(CommandHandler("add", add))
    app.add_handler(CommandHandler("addanime", addanime))
    app.add_handler(CommandHandler("status", status))
    app.run_polling()