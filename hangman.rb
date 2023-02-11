require 'json'

module GameSaves
  def to_json
    hash = {}
    instance_variables.each do |var|
      hash[var] = instance_variable_get var
    end
    hash.to_json
  end

  def from_json!(string)
    JSON.parse(string).each do |var, val|
      instance_variable_set var, val
    end
  end

  def create_save(savename)
    Dir.mkdir('saved_games') unless Dir.exist?('saved_games')
    File.open("./saved_games/#{savename}.json", 'w') { |file| file.write(to_json) }
  end

  def load_save_file(savename)
    save = File.open("./saved_games/#{savename}.json", 'r').readline.chomp
    from_json!(save)
  end
end

module Hangman
  include GameSaves
  class Game
    attr_accessor :guesses, :secret_word, :guess_count

    def initialize
      @guesses = []
      @secret_word = select_word
      @guess_count = 10
    end

    def start 
      puts 'Welcome to the Hangman game!'

      puts 'Type 1 to start a new game, 2 to load a save'
      choice = 0
      loop do
        choice = gets.to_i
        if [1, 2].include?(choice)
          break
        else
          puts 'Invalid option.'
        end
      end

      case choice
      when 1
        play
      when 2
        loop do
          begin
            unless Dir.exist?('./saved_games')
              puts 'No save folder found'
              return
            end
            puts 'Enter save name:'
            save = gets.chomp
            load_save_file(save)
            print "\n"
            break
          rescue
            puts 'Wrong file name.'
            print "\n"
          end
        end
        play
      end
    end

    def play
      loop do
        display_guesses
        puts guess_count > 1 ? "You have #{guess_count} incorrect guesses left" : 'Last chance!'
        ask_for_input
        if check_status == 'complete'
          puts 'You Won!'
          return
        end

        if guess_count.zero?
          puts "You lost!\nThe word was #{secret_word}"
          return
        end
      end
    end

    def select_word
      filename = 'google-10000-english-no-swears.txt'
      word_dictionary = File.readlines(filename, chomp: true)
      word_dictionary.select { |word| word.strip.length.between?(5, 12) }.sample
    end

    def ask_for_input
      loop do
        print 'Enter a letter: '
        input = gets.chomp.to_s.downcase
        if input == 'save'
          puts 'Give the save file a name: '
          savename = gets.chomp
          create_save(savename)
          exit
        end

        if input.length == 1 && input =~ /[a-z]/
          if guesses.include?(input)
            puts "Letter '#{input}' has already been guessed"
            next
          else
            guesses.push(input)
            print "\n"
            if secret_word.split('').none? { |letter| letter == input }
              self.guess_count -= 1
              puts 'Wrong guess!'
            else
              puts 'Correct guess!'
            end
            return input
          end
        else
          puts 'Guess must be a single letter'
        end
      end
    end

    def check_status
      return 'complete' if secret_word.split('').all? { |letter| guesses.include?(letter) }
    end

    def display_guesses
      secret_word.split('').each do |letter|
        if guesses.include?(letter)
          print("#{letter} ")
        else
          print('_ ')
        end
      end
      print("\n")
    end
  end
end

include Hangman

Game.new.start
