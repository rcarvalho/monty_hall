module MontyHall

  class DoorNotOpenError < StandardError
  end

  class DoorAlreadyOpenError < StandardError
  end

  class GameNotFinishedError < StandardError
  end

  class GameFinishedError < StandardError
  end

  class Door
    def initialize is_winning = false
      @open = false
      @is_winning = is_winning
    end

    def open?
      @open
    end

    def open!
      #shouldn't be opening already opened doors. prolly indicates logic error
      raise DoorAlreadyOpenError if open?

      @open = true
      @is_winning
    end

    def winning?
      #no peeking!
      raise DoorNotOpenException unless open?
      @is_winning
    end
  end

  class Game
    def initialize n_doors = 3
      @n_doors = n_doors

      @doors = []
      # - 1 because we add the winning door next
      (@n_doors - 1).times { @doors << Door.new }

      @winning_door_index = Random.rand(n_doors)
      @doors.insert @winning_door_index, Door.new(true)

      @guesses = 0
      @final_answer = nil
    end

    def open? door
      @doors[door].open?
    end

    def open! door
      if @guesses == 0
        #host opens the losing doors we didn't choose, ensuring there's always
        #my door and one other door left. one of them is the winning door
        open_hosts_doors door
      elsif @guesses == 1
        @doors[door].open!
        @final_answer = door
      else
        raise GameFinishedError
      end

      @guesses += 1
    end

    def closed_doors
      closed = []
      n_doors.times do |door_index|
        closed << door_index unless @doors[door_index].open?
      end
      closed
    end

    def open_doors
      open = []
      n_doors.times do |door_index|
        open << door_index unless @doors[door_index].open?
      end
      open
    end

    def n_doors
      @n_doors
    end

    def finished?
      @guesses == 2
    end

    def won?
      raise GameNotFinishedError unless finished? 
      @doors[@final_answer].winning?
    end
    
    private

    def winning_door_index
      @winning_door_index
    end

    def losing_doors_indexes
      doors = n_doors.times.to_a
      doors.delete(@winning_door_index)
      doors
    end

    #always have the host open the losing doors that you didn't choose
    def open_hosts_doors users_choice
      choices = losing_doors_indexes

      if choices.include? users_choice #if the user's chosen a loser
        choices.delete users_choice #don't open that loser, leaving this loser door and the winner door left
      else #if user chose the winner
        choices.delete choices.sample #remove a random loser from being opened, leaving the winner and this loser left
      end

      choices.each do |door|
        @doors[door].open!
      end
    end
  end

  class Strategy
    attr_reader :first_choice

    def initialize game
      @game = game
      @first_choice = Random.rand(game.n_doors)
    end
  end

  class AlwaysSwitchStrategy < Strategy
    def second_choice
      rem = @game.closed_doors
      rem.delete(@first_choice)
      rem.sample
    end
  end

  class NeverSwitchStrategy < Strategy
    def second_choice
      @first_choice
    end
  end

  class RandomSwitchStrategy < Strategy
    def second_choice
      rem = @game.closed_doors
      rem.sample
    end
  end

  class Simulation
    attr_reader :iterations, :strategy, :wins, :losses

    def initialize iterations, strategy, doors = 3
      @iterations = iterations
      @strategy = strategy

      @doors = doors

      @wins = 0
      @losses = 0
    end

    def simulate!
      @iterations.times do |i|
        g = Game.new @doors
        s = @strategy.new(g)

        g.open! s.first_choice
        g.open! s.second_choice

        if g.won?
          @wins += 1
        else
          @losses += 1
        end
      end
    end

    def print_results
      puts "In #{@iterations} simulations of strategy #{@strategy}, there were:"
      puts "\tWins: #{@wins} (#{(@wins*100/@iterations.to_f).round(2)}%)"
      puts "\tLosses: #{@losses} (#{(@losses*100/@iterations.to_f).round(2)}%)"
    end
  end
end

if __FILE__ == $0
  iterations = 10000
  doors = 3

  switch = MontyHall::Simulation.new(iterations, MontyHall::AlwaysSwitchStrategy, doors)
  switch.simulate!
  switch.print_results

  dont_switch = MontyHall::Simulation.new(iterations, MontyHall::NeverSwitchStrategy, doors)
  dont_switch.simulate!
  dont_switch.print_results

  rand_switch = MontyHall::Simulation.new(iterations, MontyHall::RandomSwitchStrategy, doors)
  rand_switch.simulate!
  rand_switch.print_results
end
