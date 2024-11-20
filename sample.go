package main

import (
    "context"
    "os"
    "os/signal"
    "fmt"

    "github.com/go-telegram/bot"
    "github.com/go-telegram/bot/models"
)

// Send any text message to the bot after the bot has been started

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    opts := []bot.Option{
        bot.WithDefaultHandler(handler),
    }

    b, err := bot.New("5684161024:AAHHpI6R9JtM3EnN-ycZbdbUncTDBBOrD1s", opts...)
    if err != nil {
        panic(err)
    }

    b.RegisterHandler(bot.HandlerTypeMessageText, "/start", bot.MatchTypeExact, helloHandler)

    b.Start(ctx)
}

type BotState int

const (
    Registration BotState = iota
    CreatePoll
    Vote
)

var global_state = Registration;


func helloHandler(ctx context.Context, b *bot.Bot, update *models.Update) {
    b.SendMessage(ctx, &bot.SendMessageParams{
        ChatID:    update.Message.Chat.ID,
        Text:      "Hello, *" + bot.EscapeMarkdown(update.Message.From.FirstName) + "*",
        ParseMode: models.ParseModeMarkdown,
    })
    b.SendMessage(ctx, &bot.SendMessageParams{
        ChatID:    update.Message.Chat.ID,
        Text:      "Please, register: *" + bot.EscapeMarkdown(update.Message.From.FirstName) + "*",
        ParseMode: models.ParseModeMarkdown,
    })

    kb := &models.InlineKeyboardMarkup{
        InlineKeyboard: [][]models.InlineKeyboardButton{
            {
                {Text: "Yes", CallbackData: "yes"},
                {Text: "No", CallbackData: "no"},
            },
        },
    }

    b.SendMessage(ctx, &bot.SendMessageParams{
        ChatID:      update.Message.Chat.ID,
        Text:        "Do you already have a Nil-wallet?",
        ReplyMarkup: kb,
    })
}

func handler(ctx context.Context, b *bot.Bot, update *models.Update) {
    fmt.Println("handler begin")
    
    if global_state == Registration {
      b.AnswerCallbackQuery(ctx, &bot.AnswerCallbackQueryParams{
          CallbackQueryID: update.CallbackQuery.ID,
          ShowAlert:       true,
      })
      b.SendMessage(ctx, &bot.SendMessageParams{
          ChatID: update.CallbackQuery.Message.Message.Chat.ID,
          Text:   fmt.Sprintf("Selected options: %v", update.CallbackQuery.Data),
      })
    } else {
      b.SendMessage(ctx, &bot.SendMessageParams{
          ChatID: update.CallbackQuery.Message.Message.Chat.ID,
          Text:   fmt.Sprintf("I am confused :("),
      })
    }
    fmt.Println("handler end")
}
