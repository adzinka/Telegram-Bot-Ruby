require 'telegram/bot'
require 'open-uri'
require 'json'

json = File.read('inform.json')
jil = JSON.parse(json)

token = ''

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|

    case message

    when Telegram::Bot::Types::Message
      case message.text
      when '/start'
        bot.api.send_message(chat_id: message.chat.id, text: "Шалом, #{message.from.first_name}")
      when '/stop'
        bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
      when '/classes'

      kb = [

      [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '1 класс', callback_data: 'class1'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '2 класс', callback_data: 'class2'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '3 класс', callback_data: 'class3')
      ],
      [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '4 класс', callback_data: 'class4'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '5 класс', callback_data: 'class5'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '6 класс', callback_data: 'class6')
      ],
      [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '7 класс', callback_data: 'class7'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '8 класс', callback_data: 'class8'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '9 класс', callback_data: 'class9')
      ],
      [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '10 класс', callback_data: 'class10'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: '11 класс', callback_data: 'class11')
      ]

      ]
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
      bot.api.send_message(chat_id: message.chat.id, text: 'Выбери класс', reply_markup: markup)

      when /book(\d+)/
        clas_index = message.text[/\d+/].to_i
        book_index = message.text.reverse[/\d+/].reverse.to_i
        clas = message.text[/\d+/].rjust(2, '0')
        books = message.text.reverse[/\d+/].reverse.rjust(2, '0')
        book = jil[clas_index][book_index]
        name = book['name']
        blank = []
        book['tasks'].each_slice(5) { |a| blank.push(a) }
        chapters_list = ""
        id = "#{clas}" + "#{books}"
        p blank.count
        next if blank.count == 0

        blank[0].each_with_index do |task, index|
          title = task['title']
          start = task['start']
          last = task['last']
          chapters_list = chapters_list + "#{title}" + "\t" + "#{start}" + "-" + "#{last}" + "\n" + "id:#{id}#{index.to_s.rjust(2, '0')}" + "\n"  +  "\n"
        end

        info = "<b>Название: #{name}</b>" + "\n" + "#{chapters_list}"

        page_amount = blank.count

        kb = []
        row = []
        if page_amount < 5
          page_amount.times do |index|
            if page_amount == 1
            else
              if index == 0
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{index}·", callback_data: "page_current"))
              else
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: index+1, callback_data: "page#{clas}_#{books}_#{index}"))
              end
            end
          end

        elsif page_amount > 5
          pages = [0, 1, 2, 3, page_amount-1]
          pages.each do |num|
            if num == 0
              row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{num+1}·", callback_data: "page_current"))
            else
              row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "page#{clas}_#{books}_#{num}"))
            end
          end
        end


        kb.push(row)

        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
        bot.api.send_message(chat_id: message.chat.id, parse_mode: 'HTML', text: info, reply_markup: markup)

      when /(\d{2})(\d{2})(\d{2})\_(\d+)/
      tet = /(\d{2})(\d{2})(\d{2})\_(\d+)/.match(message.text)
      clas = tet[1].to_i
      book_index = tet[2].to_i
      glava_index = tet[3].to_i
      number_index = tet[4]
      book = jil[clas][book_index]
      begin
        book.nil? || book['tasks'][glava_index].nil?
        glava = book['tasks'][glava_index]
        gdzname = book['link']
        lnk = glava['link'].gsub("%t%", number_index)
        link = "https://megaresheba.com/json#{gdzname}/#{lnk}"

        page = open(link).read

        info = JSON.parse(page)

        images = ""

        editions = info['editions']
        editions.each do |image|
          url = image['images'][0]
          images = "https://megaresheba.com" + url['url']
          bot.api.send_message(chat_id: message.chat.id, text: images)
        end

      rescue
        puts "Сохранение не удалось. Ошибка: #{$!}"
        bot.api.send_message(chat_id: message.chat.id, text: "Такого задания нет(")
      end
    end

    when Telegram::Bot::Types::CallbackQuery
      case message.data

      when /class(\d+)/
        list = ""
        clas = message.data[/\d+/].to_i
        group = []

        jil[clas].each_slice(5) { |a| group.push(a) }
        next if group.count == 0

        group[0].each_with_index do |ki, index|
         list = list + "<b>#{ki['name']}</b>" + "\n" + "#{ki['authors']}" + "\n" + "/book#{clas}_#{index}" + "\n"  +  "\n"
        end
        page_amount = group.count

        kb = []
        row = []

        if page_amount < 5
          page_amount.times do |index|
            if page_amount == 1
            else
              if index == 0
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{index+1}·", callback_data: "page_current"))
              else
              row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: index+1, callback_data: "books#{clas}_#{index}"))
              end
            end
          end

        elsif page_amount > 5
          pages = [0, 1, 2, 3, page_amount-1]
          pages.each do |num|
            if num == 0
              row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{num+1}·", callback_data: "page_current"))
            else
              row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "books#{clas}_#{num}"))
            end
          end
        end

        kb.push(row)

        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
        bot.api.send_message(chat_id: message.message.chat.id, parse_mode: 'HTML', text: list, reply_markup: markup)

      when /page(\d+)_(\d+)_(\d+)/
        date = /(\d+)_(\d+)_(\d+)/.match(message.data)
        clas = date[1].to_i
        books = date[2].to_i
        page = date[3].to_i
        book = jil[clas][books]
        name = book['name']
        k = 5

        blank = []

        book['tasks'].each_slice(5) { |a| blank.push(a) }
        chapters_list = ""
        id = "#{clas}" + "#{books}"
        p blank.count, page
        blank[page].each_with_index do |task, index|
          di = page * k + index
          title = task['title']
          start = task['start']
          last = task['last']
          chapters_list = chapters_list + "#{title}" + "\t" + "#{start}" + "-" + "#{last}" + "\n" + "id:#{id}#{di}" + "\n"  +  "\n"
        end

        info = "<b>Название: #{name}</b>" + "\n" + "#{chapters_list}"

        page_amount = blank.count

        kb = []
        row = []

        if page_amount > 5

          if page == 0
            pages = [0, 1, 2, 3, page_amount-1]
            pages.each do |num|
              if page == num
              row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{page+1}·", callback_data: "page_current"))
              else
              row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "page#{clas}_#{books}_#{num}"))

              end
            end

          elsif page == 1
            pages = [0, 1, 2, 3, page_amount-1]
            pages.each do |num|
              if page == num
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{page+1}·", callback_data: "page_current"))
              else
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "page#{clas}_#{books}_#{num}"))
              end
            end

          elsif page == page_amount-1
            pages = [0, page_amount-4, page_amount-3, page_amount-2, page_amount-1]
            pages.each do |num|
              if page == num
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{page+1}·", callback_data: "page_current"))
              else
              row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "page#{clas}_#{books}_#{num}"))
              end
            end

          elsif page == page_amount-2
            pages = [0, page_amount-4, page_amount-3, page_amount-2, page_amount-1]
            pages.each do |num|
              if page == num
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{page+1}·", callback_data: "page_current"))
              else
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "page#{clas}_#{books}_#{num}"))
              end
            end

          elsif page == page_amount-3
            pages = [0, page_amount-4, page_amount-3, page_amount-2, page_amount-1]
            pages.each do |num|
              if page == num
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{page+1}·", callback_data: "page_current"))
              else
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "page#{clas}_#{books}_#{num}"))
              end
            end

          elsif
            pages = [0, page-1, page, page+1, page_amount-1]
            pages.each do |num|
              if page == num
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{page+1}·", callback_data: "page_current"))
              else
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "page#{clas}_#{books}_#{num}"))
              end
            end
          end

        else
           page_amount.times do |index|
           if page == index
             row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{index+1}·", callback_data: "page_current"))
           else
             row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: index+1, callback_data: "page#{clas}_#{books}_#{index}"))
           end
          end
        end

        kb.push(row)

        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
        bot.api.edit_message_text(chat_id: message.message.chat.id, message_id: message.message.message_id, parse_mode: 'HTML', text: info, reply_markup: markup)


      when /books(\d+)_(\d+)/
        date = /(\d+)_(\d+)/.match(message.data)
        clas = date[1].to_i
        page = date[2].to_i
        k = 5
        list = ""
p clas, page
        group = []
        jil[clas].each_slice(5) { |a| group.push(a) }

        group[page].each_with_index do |ki, index|
          id = page * k + index
         list = list + "<b>#{ki['name']}</b>" + "\n" + "#{ki['authors']}" + "\n" + "/book#{clas}_#{id}" + "\n"  +  "\n"
        end

        page_amount = group.count

        kb = []
        row = []

        if page_amount > 5

          if page == 0
            pages = [0, 1, 2, 3, page_amount-1]
            pages.each do |num|
              if page == num
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{page+1}·", callback_data: "page_current"))
              else
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "books#{clas}_#{num}"))
              end
            end

          elsif page == 1
            pages = [0, 1, 2, 3, page_amount-1]
            pages.each do |num|
              if page == num
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{page+1}·", callback_data: "page_current"))
              else
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "books#{clas}_#{num}"))
              end
            end

          elsif page == page_amount-1
            pages = [0, page_amount-4, page_amount-3, page_amount-2, page_amount-1]
            pages.each do |num|
              if page == num
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{page+1}·", callback_data: "page_current"))
              else
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "books#{clas}_#{num}"))
              end
            end

          elsif page == page_amount-2
            pages = [0, page_amount-4, page_amount-3, page_amount-2, page_amount-1]
            pages.each do |num|
              if page == num
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{page+1}·", callback_data: "page_current"))
              else
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "books#{clas}_#{num}"))
              end
            end

          elsif page == page_amount-3
            pages = [0, page_amount-4, page_amount-3, page_amount-2, page_amount-1]
            pages.each do |num|
              if page == num
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{page+1}·", callback_data: "page_current"))
              else
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "books#{clas}_#{num}"))
              end
            end

          else
            pages = [0, page-1, page, page+1, page_amount-1]
            pages.each do |num|
              if page == num
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{page+1}·", callback_data: "page_current"))
              else
                row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: num+1, callback_data: "books#{clas}_#{num}"))
              end
            end
          end

        else page_amount < 5
         page_amount.times do |index|
           if page == index
             row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "·#{index+1}·", callback_data: "page_current"))
           else
             row.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: index+1, callback_data: "books#{clas}_#{index}"))
           end
         end
       end



        kb.push(row)

        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
        bot.api.edit_message_text(chat_id: message.message.chat.id, message_id: message.message.message_id, parse_mode: 'HTML', text: list, reply_markup: markup)
      end
    end
  end
end
