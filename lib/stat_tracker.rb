require "csv"
require_relative "./game"
require_relative "./team"
require_relative "./game_team"

class StatTracker
  attr_reader :games,
              :teams,
              :game_teams

  def self.from_csv(files)
    StatTracker.new(files)
  end

  def initialize(files)
    @games = (CSV.open files[:games], headers: true, header_converters: :symbol).map do |row|
      Game.new(row)
    end
    @teams = (CSV.open files[:teams], headers: true, header_converters: :symbol).map do |row|
      Team.new(row)
    end
    @game_teams = (CSV.open files[:game_teams], headers: true, header_converters: :symbol).map do |row|
      GameTeam.new(row)
    end
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

  ### LEAGUE STATS ###
  def count_of_teams
    @teams.count
  end

  def best_offense
    best_offense_id = total_games_played_by_team_in_games.max_by do |team_id, games|
      total_goals_by_team_in_games[team_id] / games.to_f
    end[0]

    get_team_name(best_offense_id)
  end

  def worst_offense
    worst_offense_id = total_games_played_by_team_in_games.min_by do |team_id, games|
      total_goals_by_team_in_games[team_id] / games.to_f
    end[0]

    get_team_name(worst_offense_id)
  end

  def highest_scoring_visitor
    away_pts_per_game = Hash.new(0)
    total_goals_by_away_team.each do |team_id, goals|
      away_pts_per_game[team_id] = (goals / total_games_played_by_team_in_games[team_id])
    end
    most_away_pts_per_game = away_pts_per_game.max_by do |_, pts_per_game|
      pts_per_game
    end
    get_team_name(most_away_pts_per_game[0])
  end

  def highest_scoring_home_team
    home_pts_per_game = Hash.new(0)
    total_goals_by_home_team.each do |team_id, goals|
      home_pts_per_game[team_id] = (goals / total_games_played_by_team_in_games[team_id])
    end
    most_home_pts_per_game = home_pts_per_game.max_by do |_, pts_per_game|
      pts_per_game
    end
    get_team_name(most_home_pts_per_game[0])
  end

  def lowest_scoring_visitor
    away_pts_per_game = Hash.new(0)
    total_goals_by_away_team.each do |team_id, goals|
      away_pts_per_game[team_id] = (goals / total_games_played_by_team_in_games[team_id])
    end
    lowest_away_pts_per_game = away_pts_per_game.min_by do |_, pts_per_game|
      pts_per_game
    end
    get_team_name(lowest_away_pts_per_game[0])
  end

  def lowest_scoring_home_team
    home_pts_per_game = Hash.new(0)
    total_goals_by_home_team.each do |team_id, goals|
      home_pts_per_game[team_id] = (goals / total_games_played_by_team_in_games[team_id])
    end
    lowest_home_pts_per_game = home_pts_per_game.min_by do |_, pts_per_game|
      pts_per_game
    end
    get_team_name(lowest_home_pts_per_game[0])
  end

  ### SEASON STATS ###
  def most_accurate_team(season)
    game_ids = games_by_season(season).map(&:game_id)
    filtered_game_teams = filter_game_teams(game_ids)

    most_accurate_team_id = find_total_shots_by_team(filtered_game_teams).max_by do |team_id, shots|
      find_total_goals_by_team(filtered_game_teams)[team_id] / shots.to_f
    end[0]

    get_team_name(most_accurate_team_id)
  end

  def least_accurate_team(season)
    game_ids = games_by_season(season).map(&:game_id)
    filtered_game_teams = filter_game_teams(game_ids)

    least_accurate_team_id = find_total_shots_by_team(filtered_game_teams).min_by do |team_id, shots|
      find_total_goals_by_team(filtered_game_teams)[team_id] / shots.to_f
    end[0]

    get_team_name(least_accurate_team_id)
  end

  ### HELPER METHODS ###
  def total_games_played_by_team_in_games
    total_games_played_by_team = Hash.new(0)

    @games.each do |game|
      total_games_played_by_team[game.home_team_id] += 1
      total_games_played_by_team[game.away_team_id] += 1
    end

    total_games_played_by_team
  end

  def total_goals_by_team_in_games
    total_goals_by_team = Hash.new(0)

    @games.each do |game|
      total_goals_by_team[game.home_team_id] += game.home_goals
      total_goals_by_team[game.away_team_id] += game.away_goals
    end

    total_goals_by_team
  end

  def total_goals_by_home_team
    home_goals = Hash.new(0)
    @game_teams.each do |game|
      home_goals[game.team_id] += game.goals.to_f if game.home?
    end
    home_goals
  end

  def total_goals_by_away_team
    away_goals = Hash.new(0)
    @game_teams.each do |game|
      away_goals[game.team_id] += game.goals.to_f unless game.home?
    end
    away_goals
  end

  def get_team_name(id)
    @teams.find do |team|
      team.id == id
    end.name
  end

  def games_by_season(season)
    @games.find_all do |game|
      game.season == season
    end
  end

  def filter_game_teams(game_ids)
    @game_teams.find_all do |game_team|
      game_ids.include?(game_team.game_id)
    end
  end

  def find_total_shots_by_team(game_teams)
    total_shots_by_team = Hash.new(0)

    game_teams.each do |game_team|
      total_shots_by_team[game_team.team_id] += game_team.shots
    end

    total_shots_by_team
  end

  def find_total_goals_by_team(game_teams)
    total_goals_by_team = Hash.new(0)

    game_teams.each do |game_team|
      total_goals_by_team[game_team.team_id] += game_team.goals
    end

    total_goals_by_team
  end
end
