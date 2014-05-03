#!/usr/bin/env ruby

require 'rubygems' # only necessary in Ruby 1.8
require 'gosu'

class HamburgerTime < Gosu::Window

  WIDTH = 640
  HEIGHT = 480
  WALL = 10
  LEFT_WALL = WALL
  RIGHT_WALL = WIDTH - (WALL + 100)
  HORIZ_CENTER = WIDTH / 2
  VERT_CENTER = HEIGHT / 2
  FLOOR = HEIGHT - 50
  MAX_FLOOR_BURGERS = 10
  EAT_DISTANCE = 50
  MAX_BURGER_RATE = 30 # two per sec.
  INITIAL_BURGER_RATE = 120 # one every ~2s

  def initialize
    super(WIDTH, HEIGHT, false)
    self.caption = 'Hamburger time!'
    @hamburgers = []
    @player = Player.new(self)
    @burgers_eaten = 0
    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
  end

  def draw
    if floor_burgers >= MAX_FLOOR_BURGERS
      draw_scores
      @font.draw("Game Over :(", 10, 50, 0, 1.0, 1.0, 0xffff00ff)
    else
      @player.draw
      @hamburgers.each(&:draw)
      draw_scores
    end
  end

  def draw_scores
    @font.draw(':D ' + @burgers_eaten.to_s, 10, 10, 0, 1.0, 1.0, 0xffffff00)
    @font.draw(':( ' + floor_burgers.to_s, 10, 30, 0, 1.0, 1.0, 0xffff00ff)
  end

  def floor_burgers
    @hamburgers.count(&:floor?)
  end

  def button_down(id)
    if id == Gosu::KbEscape
      close
    end
  end

  def burger_rate
    [INITIAL_BURGER_RATE - @burgers_eaten, MAX_BURGER_RATE].max
  end

  def update
    @burgers_eaten += @hamburgers.count(&:eaten?)
    @hamburgers.reject!(&:eaten?)

    @player.update
    @hamburgers.each(&:update)
    @player.eat_burgers(@hamburgers)

    if button_down? Gosu::KbLeft or button_down? Gosu::GpLeft then
      @player.move_left
    end
    if button_down? Gosu::KbRight or button_down? Gosu::GpRight then
      @player.move_right
    end

    if rand(burger_rate) == 1
      @hamburgers << Hamburger.new(self)
    end
  end
end

class Hamburger

  EATING_TIME = 10
  GRAVITY = 0.01

  attr_accessor :x, :y

  def initialize(window)
    @images = {
      burger: Gosu::Image.new(window, "media/burger.png", false)
    }
    @x = rand(HamburgerTime::WIDTH - 100) + 50
    @y = 50.0
    @v = 0.0
    @state = :delicious
    @eating_timer = EATING_TIME
  end

  def draw
    @images[:burger].draw(@x, @y, 0)
  end

  def update
    if @y >= HamburgerTime::FLOOR
      @y = HamburgerTime::FLOOR
      @state = :floor
    else
      @v += GRAVITY
      @y += @v
    end

    if @state == :eating
      if @eating_timer > 1
        @eating_timer -= 1
      else
        @state = :eaten
      end
    end
  end

  def start_eating
    @state = :eating
  end

  def eaten?
    @state == :eaten
  end

  def floor?
    @state == :floor
  end
end

class Player

  DIGESTION_TIME = 60
  SPEED = 5

  def initialize(window)
    @images = {
      hungry: Gosu::Image.new(window, "media/monsters/blue01.png", false),
      eating: Gosu::Image.new(window, "media/monsters/blue02.png", false),
      full: Gosu::Image.new(window, "media/monsters/blue03.png", false)
    }
    @x = HamburgerTime::HORIZ_CENTER
    @y = HamburgerTime::FLOOR - 100 - HamburgerTime::EAT_DISTANCE
    @state = :hungry
    @digestion = DIGESTION_TIME
  end

  def move_left
    if @x <= HamburgerTime::LEFT_WALL
      @x = HamburgerTime::LEFT_WALL
    else
      @x -= SPEED
    end
  end

  def move_right
    if @x >= HamburgerTime::RIGHT_WALL
      @x = HamburgerTime::RIGHT_WALL
    else
      @x += SPEED
    end
  end

  def draw
    @images[@state].draw(@x, @y, 0)
  end

  def eat_burgers(burgers)
    burgers.each do |b|
      dist = Gosu::distance(@x, @y, b.x, b.y)
      if dist <= HamburgerTime::EAT_DISTANCE
        @state = :eating
        b.start_eating
        return
      end
    end

    # sadly, no burgers nearby ...
    if @state == :eating
      @state = :full
      @digestion = DIGESTION_TIME
    elsif @digestion <= 0
      @state = :hungry
    end
  end

  def update
    if @digestion > 0
      @digestion -= 1
    end
  end
end

window = HamburgerTime.new
window.show
