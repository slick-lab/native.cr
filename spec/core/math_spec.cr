# spec/core/math_spec.cr

require "../spec_helper"

describe Native::Math do
  describe "constants" do
    it "defines PI" do
      Native::Math::PI.should be_close(3.141592653589793, 0.000001)
    end

    it "defines TAU" do
      Native::Math::TAU.should be_close(6.283185307179586, 0.000001)
    end
  end

  describe ".clamp" do
    it "clamps value between min and max" do
      Native::Math.clamp(5, 0, 10).should eq(5)
      Native::Math.clamp(-5, 0, 10).should eq(0)
      Native::Math.clamp(15, 0, 10).should eq(10)
    end
  end

  describe ".lerp" do
    it "linearly interpolates between values" do
      Native::Math.lerp(0.0, 10.0, 0.5).should eq(5.0)
      Native::Math.lerp(0.0, 10.0, 0.0).should eq(0.0)
      Native::Math.lerp(0.0, 10.0, 1.0).should eq(10.0)
    end
  end

  describe ".map" do
    it "maps value from one range to another" do
      Native::Math.map(0.5, 0.0, 1.0, 0.0, 100.0).should eq(50.0)
    end
  end

  describe ".random" do
    it "returns random float between min and max" do
      10.times do
        val = Native::Math.random(0.0, 10.0)
        val.should be >= 0.0
        val.should be <= 10.0
      end
    end
  end

  describe ".random_int" do
    it "returns random integer between min and max inclusive" do
      10.times do
        val = Native::Math.random_int(1, 10)
        val.should be >= 1
        val.should be <= 10
      end
    end
  end

  describe Native::Math::Vector2 do
    it "adds two vectors" do
      v1 = Native::Math::Vector2.new(1.0, 2.0)
      v2 = Native::Math::Vector2.new(3.0, 4.0)
      result = v1 + v2
      result.x.should eq(4.0)
      result.y.should eq(6.0)
    end

    it "subtracts two vectors" do
      v1 = Native::Math::Vector2.new(5.0, 6.0)
      v2 = Native::Math::Vector2.new(3.0, 4.0)
      result = v1 - v2
      result.x.should eq(2.0)
      result.y.should eq(2.0)
    end

    it "multiplies vector by scalar" do
      v = Native::Math::Vector2.new(2.0, 3.0)
      result = v * 4.0
      result.x.should eq(8.0)
      result.y.should eq(12.0)
    end

    it "computes magnitude" do
      v = Native::Math::Vector2.new(3.0, 4.0)
      v.magnitude.should eq(5.0)
    end

    it "computes dot product" do
      v1 = Native::Math::Vector2.new(1.0, 2.0)
      v2 = Native::Math::Vector2.new(3.0, 4.0)
      v1.dot(v2).should eq(11.0)
    end

    it "computes distance between vectors" do
      v1 = Native::Math::Vector2.new(0.0, 0.0)
      v2 = Native::Math::Vector2.new(3.0, 4.0)
      v1.distance_to(v2).should eq(5.0)
    end
  end

  describe Native::Math::Color do
    it "creates color from RGB values" do
      color = Native::Math::Color.from_rgba(255, 128, 64, 255)
      color.r.should be_close(1.0, 0.01)
      color.g.should be_close(0.5, 0.01)
      color.b.should be_close(0.25, 0.01)
    end

    it "converts hex to color" do
      color = Native::Math::Color.from_hex(0xFF3366)
      color.r.should be_close(1.0, 0.01)
      color.g.should be_close(0.2, 0.01)
      color.b.should be_close(0.4, 0.01)
    end

    it "converts color to hex" do
      color = Native::Math::Color.from_rgba(255, 51, 102, 255)
      hex = color.to_hex
      expected = 0xFF3366FF
      hex.should eq(expected)
    end

    it "interpolates between colors" do
      c1 = Native::Math::Color.new(1.0, 0.0, 0.0, 1.0)
      c2 = Native::Math::Color.new(0.0, 0.0, 1.0, 1.0)
      result = c1.lerp(c2, 0.5)
      result.r.should be_close(0.5, 0.01)
      result.b.should be_close(0.5, 0.01)
    end

    it "returns white" do
      color = Native::Math::Color.white
      color.r.should eq(1.0)
      color.g.should eq(1.0)
      color.b.should eq(1.0)
      color.a.should eq(1.0)
    end

    it "returns black" do
      color = Native::Math::Color.black
      color.r.should eq(0.0)
      color.g.should eq(0.0)
      color.b.should eq(0.0)
      color.a.should eq(1.0)
    end
  end
end
