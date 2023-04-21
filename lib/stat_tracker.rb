require "csv"
require_relative "./game"

class StatTracker
  attr_reader :games

  def self.from_csv(files)
    StatTracker.new(files)
  end

  def initialize(files)
    @games = (CSV.open files[:games], headers: true, header_converters: :symbol).map { |row| Game.new(row) }
  end

  ### GAME STATS ###
  def highest_total_score
    highest_game = @games.max_by do |game|
      game.away_goals + game.home_goals
    end
    highest_game.away_goals + highest_game.home_goals
  end

  def lowest_total_score
    lowest_game = @games.min_by do |game|
      game.away_goals + game.home_goals
    end
    lowest_game.away_goals + lowest_game.home_goals
  end

  def percentage_home_wins
    number_of_games = @games.count.to_f
    home_wins = @games.find_all do |game|
      game.home_goals > game.away_goals
    end
    (home_wins.count / number_of_games).round(2)
  end

  def percentage_visitor_wins
    number_of_games = @games.count.to_f
    visitor_wins = @games.find_all do |game|
      game.home_goals < game.away_goals
    end
    (visitor_wins.count / number_of_games).round(2)
  end

  def percentage_ties
    number_of_games = @games.count.to_f
    tie_games = @games.find_all do |game|
      game.home_goals == game.away_goals
    end
    (tie_games.count / number_of_games).round(2)
  end

  def count_of_games_by_season
    count_of_games = Hash.new(0)
    season_count = @games.map { |game| game.season }
    season_count.each { |season| count_of_games[season] += 1 }
    count_of_games
  end

  def average_goals_per_game
    number_of_games = @games.count.to_f
    average_goals = @games.map do |game|
      game.away_goals + game.home_goals
    end
    (average_goals.sum.to_f / number_of_games).round(2)
  end

  def average_goals_by_season
    season_total_goals = Hash.new(0)
    @games.each do |game|
      season_total_goals[game.season] += game.away_goals + game.home_goals
    end
    season_average_goals = Hash.new(0)
    season_total_goals.each do |season, _|
      season_average_goals[season] = (season_total_goals[season].to_f / count_of_games_by_season[season]).round(2)
    end
    season_average_goals
  end

  ### LEAGUE STATS ###
  ### TEAM STATS ###
end
