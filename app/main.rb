require "app/lowrez.rb"

DISALLOWED_KEYS  = ["i", "u", "v", "w", "m"]
ALLOWED_KEYS     = ("a".."z").to_a - DISALLOWED_KEYS
BOTTOM_Y         = 8
TOP_Y            = 55
DIFFICULTIES     = {
  easy: 4.0 * 60,
  medium: 3.0 * 60,
  hard: 2.0 * 60,
  very_hard: 1 * 60,
  impossible: 0.75 * 60,
  inferno: 0.5 * 60,
}
DIFFICULTY_SCORE = {
  easy: 1,
  medium: 2,
  hard: 3,
  very_hard: 4,
  impossible: 5,
  inferno: 6,
}

def tick args
  args.lowrez.background_color = [255, 255, 255]

  background_image args
  init_state args

  show_title? args
  show_instructions? args
  reset_game_state args

  main_loop args

  # render_debug args
end

def background_image args
  if args.state.wrong_key
    args.lowrez.sprites << {
      w: 64,
      h: 64,
      path: "sprites/pc-background-inverted-glitch.png",
    }
  else
    args.lowrez.sprites << {
      w: 64,
      h: 64,
      path: "sprites/pc-background-lavender.png",
    }
  end
end

def init_state args
  args.state.wrong_key ||= false
  args.state.score ||= 0
  args.state.player_name ||= ""
end

def main_loop args
  # args.state.flames ||= []

  # args.lowrez.sprites << args.state.flames.map do |p|
  #   [(6..31).to_a.sample, (9..54).to_a.sample, 3, 3,
  #   'sprites/flame.png', 0,
  #   255 * 1].sprite
  # end

  # args.lowrez.sprites << args.state.flames.map do |p|
  #   [(32..58).to_a.sample, (9..54).to_a.sample, 3, 3,
  #   'sprites/flame.png', 0,
  #   255 * 1].sprite
  # end

  # args.state.flames.clear if args.state.flames.all?(&:old?)

  case args.state.screen
  when :title
    args.lowrez.sprites << {
      x: 12,
      y: 31,
      w: 40,
      h: 24,
      path: "sprites/logo.png",
    }
    args.lowrez.labels << { x: 33, y: 30, text: "press the",
                            size_enum: LOWREZ_FONT_SM, alignment_enum: 1,
                            r: 153, g: 229, b: 80, a: 255,
                            font: "fonts/pixel-4x5.ttf" }

    args.lowrez.labels << { x: 33, y: 23, text: "enter key",
                            size_enum: LOWREZ_FONT_SM, alignment_enum: 1,
                            r: 153, g: 229, b: 80, a: 255,
                            font: "fonts/pixel-4x5.ttf" }

    args.lowrez.labels << { x: 16, y: 16, text: "to start",
                            size_enum: LOWREZ_FONT_SM, alignment_enum: 0,
                            r: 153, g: 229, b: 80, a: 255,
                            font: "fonts/pixel-4x5.ttf" }
  when :instructions
    args.lowrez.sprites << {
      x: 12,
      y: 31,
      w: 40,
      h: 24,
      path: "sprites/logo.png",
    }
    args.lowrez.labels << { x: 33, y: 30, text: "enter the",
                            size_enum: LOWREZ_FONT_SM, alignment_enum: 1,
                            r: 153, g: 229, b: 80, a: 255,
                            font: "fonts/pixel-4x5.ttf" }

    args.lowrez.labels << { x: 33, y: 23, text: "keys in",
                            size_enum: LOWREZ_FONT_SM, alignment_enum: 1,
                            r: 153, g: 229, b: 80, a: 255,
                            font: "fonts/pixel-4x5.ttf" }

    args.lowrez.labels << { x: 33, y: 16, text: "sequence",
                            size_enum: LOWREZ_FONT_SM, alignment_enum: 1,
                            r: 153, g: 229, b: 80, a: 255,
                            font: "fonts/pixel-4x5.ttf" }
  when :game
    if args.state.wrong_key
      args.lowrez.labels << { x: 23, y: 43, text: chosen_key?(args),
                            size_enum: 1.5, alignment_enum: 0,
                            r: 0, g: 0, b: 0, a: 255,
                            font: "fonts/pixel-4x5.ttf" }
      args.lowrez.labels << { x: 7, y: 53, text: "score: #{args.state.score}",
                            size_enum: LOWREZ_FONT_SM, alignment_enum: 0,
                            r: 0, g: 0, b: 0, a: 255,
                            font: "fonts/lowrez.ttf" }
    else
      args.lowrez.labels << { x: 23, y: 43, text: chosen_key?(args),
                            size_enum: 1.5, alignment_enum: 0,
                            r: 155, g: 173, b: 183, a: 255,
                            font: "fonts/pixel-4x5.ttf" }
      args.lowrez.labels << { x: 7, y: 53, text: "score: #{args.state.score}",
                            size_enum: LOWREZ_FONT_SM, alignment_enum: 0,
                            r: 155, g: 173, b: 183, a: 255,
                            font: "fonts/lowrez.ttf" }
    end
  when :leaderboard
    args.lowrez.labels << { x: 8, y: 52, text: "1. #{current_player_name(args)}:",
                            size_enum: LOWREZ_FONT_SM, alignment_enum: 0,
                            r: 153, g: 229, b: 80, a: 255,
                            font: "fonts/pixel-4x5.ttf" }
    args.lowrez.labels << { x: 17, y: 45, text: "#{args.state.score}",
                            size_enum: LOWREZ_FONT_SM, alignment_enum: 0,
                            r: 153, g: 229, b: 80, a: 255,
                            font: "fonts/pixel-4x5.ttf" }
  when :game_over
    args.state.wrong_key = false

    if args.inputs.keyboard.key_down.truthy_keys.length > 0 && args.inputs.keyboard.key_down.truthy_keys[0] == :char && args.inputs.keyboard.key_down.truthy_keys[2].length == 1 && args.state.player_name.length < 5
      args.state.player_name += args.inputs.keyboard.key_down.truthy_keys[2].to_s
    end

    if args.state.player_name.length == 5
      $gtk.http_get "https://tiny-tty-server.herokuapp.com/save_score/#{args.state.player_name}/#{args.state.score}"
      args.state.screen = :leaderboard
    end

    args.lowrez.sprites << {
      x: 12,
      y: 31,
      w: 40,
      h: 24,
      path: "sprites/logo.png",
    }
    args.lowrez.labels << { x: 33, y: 30, text: "enter your",
                            size_enum: LOWREZ_FONT_SM, alignment_enum: 1,
                            r: 153, g: 229, b: 80, a: 255,
                            font: "fonts/pixel-4x5.ttf" }

    args.lowrez.labels << { x: 33, y: 23, text: "name:",
                            size_enum: LOWREZ_FONT_SM, alignment_enum: 1,
                            r: 153, g: 229, b: 80, a: 255,
                            font: "fonts/pixel-4x5.ttf" }

    args.lowrez.labels << { x: 33, y: 16, text: current_player_name(args),
                            size_enum: LOWREZ_FONT_SM, alignment_enum: 1,
                            r: 153, g: 229, b: 80, a: 255,
                            font: "fonts/pixel-4x5.ttf" }
  end

  if args.state.screen == :game
    if (args.state.tick_count % 1) == 0
      args.state.time_passed += 1
    end

    args.state.difficulty ||= :easy
    args.state.upper_barrier ||= (100..110).to_a.sample

    # This calculates where the upper line should be, ratio between the lower
    # BOTTOM_Y and the upper TOP_Y
    case args.state.correct_keys
    when 0..10
      args.state.difficulty = :easy
    when 10..25
      args.state.difficulty = :medium
    when 25..50
      args.state.difficulty = :hard
    when 50..75
      args.state.difficulty = :very_hard
    when 75..args.state.upper_barrier
      args.state.difficulty = :impossible
    else
      args.state.difficulty = :inferno
    end

    ratio_done = args.state.time_passed / DIFFICULTIES[args.state.difficulty]
    ratio_left = 1 - ratio_done
    upper_line = ((TOP_Y * ratio_done) + (BOTTOM_Y * ratio_left)).to_i

    (BOTTOM_Y..upper_line).each do |x|
      if args.state.wrong_key
        args.lowrez.lines << { x: 5, y: x,
                               x2: 58, y2: x,
                               r: 203, g: 219, b: 252, a: 128 }
        if (args.state.wrong_key_time + 30) < args.state.tick_count
          args.state.wrong_key = false
          args.state.wrong_key_time = 0
        end
      else
        args.lowrez.lines << { x: 5, y: x,
                               x2: 58, y2: x,
                               r: 203, g: 219, b: 252, a: 48 }
      end
    end

    if ratio_done >= 1
      # reset_game_state(args, true)
      args.state.screen = :game_over
    end
  end

  # args.lowrez.lines << { x: 5, y: 9, x2: 58, y2:  9, r: 203, g: 219, b: 252, a: 255 * 0.8 }
  # args.lowrez.lines << { x: 5, y: 10, x2: 58, y2:  10, r: 203, g: 219, b: 252, a: 255 * 0.8 }
  # args.lowrez.lines << { x: 5, y: 11, x2: 58, y2:  11, r: 203, g: 219, b: 252, a: 255 * 0.8 }
end

def chosen_key?(args)
  args.state.correct_keys ||= 0

  if @chosen_key && args.inputs.keyboard.key_down.send(@chosen_key)
    @chosen_key = (ALLOWED_KEYS - [@chosen_key]).sample
    args.state.time_passed = 0 # countdown for subsequent keys
    args.state.correct_keys += 1 # countdown for subsequent keys
    args.state.score += DIFFICULTY_SCORE[args.state.difficulty] * 100
    # 5.times do |n|
    #   args.state.flames << args.state.new_entity(:flames,
    #                                  { angle: 360.randomize(:ratio),
    #                                    speed: 20.randomize(:ratio),
    #                                    lifetime: 10,
    #                                    x: 20,
    #                                    y: 20,
    #                                    max_alpha: 255 })
    # end
  elsif @chosen_key && args.inputs.keyboard.key_down.truthy_keys.length > 0 && args.inputs.keyboard.key_down.truthy_keys[0] == :char
    args.state.wrong_key = true
    args.state.wrong_key_time = args.state.tick_count
    if args.state.score > 0
      args.state.score -= DIFFICULTY_SCORE[args.state.difficulty] * 100
    end
  end

  @chosen_key ||= ALLOWED_KEYS.sample
end

def current_player_name(args)
  args.state.player_name.ljust(5, "_")
end

def show_instructions?(args)
  if args.state.screen == :instructions && args.inputs.keyboard.key_down.enter!
    args.state.screen = :game
    args.state.time_passed = 0 # countdown for first key
  end
end

def show_title?(args)
  args.state.screen ||= :title

  args.lowrez.solids << { x: 7, y: 7, w: 4, h: 4, r: 255, g: 0, b: 0 }

  if args.state.screen == :title && args.inputs.keyboard.key_down.enter!
    args.state.screen = :instructions
  end
end

def reset_game_state(args, force = false)
  if args.inputs.keyboard.key_down.escape! || force == true
    @chosen_key = nil
    args.state.screen = :title
    args.state.time_passed = 0
    args.state.correct_keys = 0
    args.state.wrong_key = false
    args.state.wrong_key_time = 0
    args.state.score = 0
    args.state.difficulty = :easy
    args.state.player_name = ""
  end
end

def render_debug args
  if !args.state.grid_rendered
    65.map_with_index do |i|
      args.outputs.static_debug << {
        x:  LOWREZ_X_OFFSET,
        y:  LOWREZ_Y_OFFSET + (i * 10),
        x2: LOWREZ_X_OFFSET + LOWREZ_ZOOMED_SIZE,
        y2: LOWREZ_Y_OFFSET + (i * 10),
        r: 128,
        g: 128,
        b: 128,
        a: 80
      }.line

      args.outputs.static_debug << {
        x:  LOWREZ_X_OFFSET + (i * 10),
        y:  LOWREZ_Y_OFFSET,
        x2: LOWREZ_X_OFFSET + (i * 10),
        y2: LOWREZ_Y_OFFSET + LOWREZ_ZOOMED_SIZE,
        r: 128,
        g: 128,
        b: 128,
        a: 80
      }.line
    end
  end

  args.state.grid_rendered = true

  args.state.label_style  = { size_enum: -1.5 }

  args.state.watch_list = [
    "args.state.tick_count is:       #{args.state.tick_count}",
    "args.lowrez.mouse_position is:  #{args.lowrez.mouse_position.x}, #{args.lowrez.mouse_position.y}",
    "args.state.time_passed:         #{args.state.time_passed}",
    "args.state.screen:              #{args.state.screen}",
    "args.state.correct_keys:        #{args.state.correct_keys}",
    "args.state.difficulty:          #{args.state.difficulty}",
    "args.state.score:               #{args.state.score}",
    "@chosen_key:                    #{@chosen_key}",
  ]

  args.outputs.debug << args.state
                            .watch_list
                            .map_with_index do |text, i|
    {
      x: 5,
      y: 720 - (i * 20),
      text: text,
      size_enum: -1.5
    }.label
  end
end

$gtk.reset
