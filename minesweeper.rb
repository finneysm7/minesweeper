require 'yaml'

class Board
  attr_reader :grid
  
  def initialize
    @grid = Array.new(9) { |i| Array.new(9) { |j| Tile.new(i, j, self) }}
    randomize_bombs
  end
  
  def randomize_bombs
    bomb_pos = []
    
    until bomb_pos.size == 10
      rand_pos = [rand(0...9), rand(0...9)]
      bomb_pos << rand_pos unless bomb_pos.include?(rand_pos)
    end
    
    bomb_pos.each do |b_pos|
      @grid[b_pos[0]][b_pos[1]].contains_bomb = true      
    end
    
  end
  
  def [](pos)
    @grid[pos[0]][pos[1]]
  end
  
  def lost?
    @grid.each do |row|
      if row.any? { |cell| cell.revealed && cell.contains_bomb }
        return true
      end
    end
    false
  end
  
  def won?
  bomb_tiles = []  
  safe_tiles = []
  
    @grid.each do |el|
      el.each do |cell|
        bomb_tiles << cell if cell.contains_bomb
        safe_tiles << cell unless cell.contains_bomb
      end
    end   
    bomb_tiles.all? { |tile| tile.flagged } && safe_tiles.all? { |tile| tile.revealed }
  end
    
end

class Tile
  attr_accessor :contains_bomb, :revealed, :pos, :bomb_count, :flagged
  
  def initialize(i, j, board)
    @board = board
    @pos = [i, j]
    @contains_bomb = false
    @revealed = false
    @flagged = false
  end
  
  def reveal
    self.revealed = true
    
    @bomb_count = self.neighbor_bomb_count
    return @bomb_count if self.neighbor_bomb_count > 0
     
    self.neighbors.each do |neighbor|
      neighbor.reveal unless neighbor.revealed || neighbor.flagged
    end
  end
  
  def flag
    @flagged = true
  end
  
  def neighbors
    moves = [[1, 1],
            [1, 0],
            [0, 1],
            [-1, -1],
            [0, -1],
            [-1, 0],
            [1, -1],
            [-1, 1]]
    i = self.pos[0]
    j = self.pos[1]
    neighbor_pos = []
    moves.each do |move| # Consider refactoring into helper method
      unless i + move[0] > 8 ||
        i + move[0] < 0 ||
        j + move[1] > 8 ||
        j + move[1] < 0
        
        neighbor_pos << @board[[i + move[0], j + move[1]]]
      end
    end
    neighbor_pos
  end
  
  def neighbor_bomb_count
    bomb_count = 0
    neighbors.each do |n_pos|
      bomb_count += 1 if n_pos.contains_bomb 
    end
    bomb_count
  end
  
  def display_value
    return ["*"] if self.revealed == false && self.flagged == false
    if self.revealed
      if self.bomb_count > 0
        return ["#{self.bomb_count}"]
      else
        return ["_"]
      end
    elsif self.flagged
      return ["F"]
    end
  end
end

class Game
  attr_accessor :board
  def initialize
    @board = Board.new()
  end
  
  def display # put in Board class
    big_display_grid = []
    board.grid.each do |el|
      display_grid = []
      el.each do |cell|
        display_grid << cell.display_value
      end
       p display_grid
    end
  end
  
  def play
  
    until game_over? || @break_loop
      display
      get_user_input
    end

    game_over_condition
    
  end
  
  def self.menu
    puts "Would you like to load a game? (y/n)"
    input = gets.chomp
    if input == "y"
      g = Game.load_game
    elsif input == "n"
      g = Game.new
    end
    g.play
  end
  
  def get_user_input
    puts "Enter a coordinate position to reveal or flag like so: horizontal, vertical"
    pos = gets.chomp.split(',').map {|i| i.to_i}
    puts "Do you want to reveal or flag this position or save your game? [r or f or s]"
    input = gets.chomp
    handle_user_input(input, pos)
  end
  
  def handle_user_input(input, pos)
        
      self.board[pos].reveal if input == "r"
      self.board[pos].flag if input == "f"
      save_game if input == "s"
  end
  
  def game_over?
    @board.won? || @board.lost?
  end
  
  def game_over_condition
      puts "You lost" if @board.lost?
      puts "YOU WIN!!!!!!!" if @board.won?
  end
  
  def save_game
    File.open('saved_games.txt', 'w') { |file| file.write(self.to_yaml) }
    puts "Game Saved, GOODBYE"
    @break_loop = true
  end
  
  def self.load_game
    output = YAML.load_file('saved_games.txt')
  end
end

if __FILE__ == $PROGRAM_NAME
  g = Game.menu
end