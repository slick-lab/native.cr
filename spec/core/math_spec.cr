# spec/framework/math_spec.cr

require "../spec_helper"

describe Native::Math do
  describe "constants" do
    it "defines PI" do
      Native::Math::PI.should be_close(3.141592653589793, 0.000001)
    end
    
    it "defines TAU" do
      Native::Math::TAU.should be_close(6.283185307179586, 0.000001)
    end
    
    it "defines DEG_TO_RAD" do
      Native::Math::DEG_TO_RAD.should be_close(0.017453292519943295, 0.000001)
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
    
    it "clamps t between 0 and 1" do
      Native::Math.lerp(0.0, 10.0, -1.0).should eq(0.0)
      Native::Math.lerp(0.0, 10.0, 2.0).should eq(10.0)
    end
  end
  
  describe ".map" do
    it "maps value from one range to another" do
      Native::Math.map(0.5, 0.0, 1.0, 0.0, 100.0).should eq(50.0)
      Native::Math.map(0.0, 0.0, 1.0, 10.0, 20.0).should eq(10.0)
      Native::Math.map(1.0, 0.0, 1.0, 10.0, 20.0).should eq(20.0)
    end
  end
  
  describe ".random" do
    it "returns random float between min and max" do
      100.times do
        val = Native::Math.random(0.0, 10.0)
        val.should be >= 0.0
        val.should be <= 10.0
      end
    end
  end
  
  describe ".random_int" do
    it "returns random integer between min and max inclusive" do
      100.times do
        val = Native::Math.random_int(1, 10)
        val.should be >= 1
        val.should be <= 10
      end
    end
  end
end

describe Native::Math::Vector2 do
  describe ".new" do
    it "creates vector with default values" do
      v = Native::Math::Vector2.new
      v.x.should eq(0.0)
      v.y.should eq(0.0)
    end
    
    it "creates vector with custom values" do
      v = Native::Math::Vector2.new(3.0, 4.0)
      v.x.should eq(3.0)
      v.y.should eq(4.0)
    end
  end
  
  describe ".zero" do
    it "returns zero vector" do
      v = Native::Math::Vector2.zero
      v.x.should eq(0.0)
      v.y.should eq(0.0)
    end
  end
  
  describe ".one" do
    it "returns vector with ones" do
      v = Native::Math::Vector2.one
      v.x.should eq(1.0)
      v.y.should eq(1.0)
    end
  end
  
  describe ".up" do
    it "returns up vector" do
      v = Native::Math::Vector2.up
      v.x.should eq(0.0)
      v.y.should eq(1.0)
    end
  end
  
  describe ".down" do
    it "returns down vector" do
      v = Native::Math::Vector2.down
      v.x.should eq(0.0)
      v.y.should eq(-1.0)
    end
  end
  
  describe ".left" do
    it "returns left vector" do
      v = Native::Math::Vector2.left
      v.x.should eq(-1.0)
      v.y.should eq(0.0)
    end
  end
  
  describe ".right" do
    it "returns right vector" do
      v = Native::Math::Vector2.right
      v.x.should eq(1.0)
      v.y.should eq(0.0)
    end
  end
  
  describe "#+" do
    it "adds two vectors" do
      v1 = Native::Math::Vector2.new(1.0, 2.0)
      v2 = Native::Math::Vector2.new(3.0, 4.0)
      result = v1 + v2
      
      result.x.should eq(4.0)
      result.y.should eq(6.0)
    end
  end
  
  describe "#-" do
    it "subtracts two vectors" do
      v1 = Native::Math::Vector2.new(5.0, 6.0)
      v2 = Native::Math::Vector2.new(3.0, 4.0)
      result = v1 - v2
      
      result.x.should eq(2.0)
      result.y.should eq(2.0)
    end
  end
  
  describe "#*" do
    it "multiplies vector by scalar" do
      v = Native::Math::Vector2.new(2.0, 3.0)
      result = v * 4.0
      
      result.x.should eq(8.0)
      result.y.should eq(12.0)
    end
  end
  
  describe "#/" do
    it "divides vector by scalar" do
      v = Native::Math::Vector2.new(8.0, 12.0)
      result = v / 4.0
      
      result.x.should eq(2.0)
      result.y.should eq(3.0)
    end
  end
  
  describe "#-" do
    it "negates vector" do
      v = Native::Math::Vector2.new(3.0, -4.0)
      result = -v
      
      result.x.should eq(-3.0)
      result.y.should eq(4.0)
    end
  end
  
  describe "#magnitude" do
    it "returns length of vector" do
      v = Native::Math::Vector2.new(3.0, 4.0)
      v.magnitude.should eq(5.0)
    end
  end
  
  describe "#magnitude_squared" do
    it "returns squared length" do
      v = Native::Math::Vector2.new(3.0, 4.0)
      v.magnitude_squared.should eq(25.0)
    end
  end
  
  describe "#normalize" do
    it "returns unit vector" do
      v = Native::Math::Vector2.new(3.0, 4.0)
      normalized = v.normalize
      
      normalized.magnitude.should be_close(1.0, 0.0001)
    end
    
    it "returns zero for zero vector" do
      v = Native::Math::Vector2.zero
      normalized = v.normalize
      
      normalized.x.should eq(0.0)
      normalized.y.should eq(0.0)
    end
  end
  
  describe "#dot" do
    it "returns dot product" do
      v1 = Native::Math::Vector2.new(1.0, 2.0)
      v2 = Native::Math::Vector2.new(3.0, 4.0)
      
      v1.dot(v2).should eq(11.0)
    end
  end
  
  describe "#cross" do
    it "returns cross product magnitude" do
      v1 = Native::Math::Vector2.new(1.0, 2.0)
      v2 = Native::Math::Vector2.new(3.0, 4.0)
      
      v1.cross(v2).should eq(-2.0)
    end
  end
  
  describe "#distance_to" do
    it "returns distance between vectors" do
      v1 = Native::Math::Vector2.new(0.0, 0.0)
      v2 = Native::Math::Vector2.new(3.0, 4.0)
      
      v1.distance_to(v2).should eq(5.0)
    end
  end
  
  describe "#angle_to" do
    it "returns angle between vectors" do
      v1 = Native::Math::Vector2.right
      v2 = Native::Math::Vector2.up
      
      v1.angle_to(v2).should be_close(Native::Math::HALF_PI, 0.0001)
    end
  end
  
  describe "#angle" do
    it "returns angle of vector" do
      v = Native::Math::Vector2.right
      v.angle.should eq(0.0)
    end
  end
  
  describe "#rotate" do
    it "rotates vector by radians" do
      v = Native::Math::Vector2.right
      rotated = v.rotate(Native::Math::HALF_PI)
      
      rotated.x.should be_close(0.0, 0.0001)
      rotated.y.should be_close(1.0, 0.0001)
    end
  end
  
  describe "#lerp" do
    it "linearly interpolates to another vector" do
      v1 = Native::Math::Vector2.new(0.0, 0.0)
      v2 = Native::Math::Vector2.new(10.0, 10.0)
      
      result = v1.lerp(v2, 0.5)
      
      result.x.should eq(5.0)
      result.y.should eq(5.0)
    end
  end
  
  describe "#==" do
    it "returns true for equal vectors" do
      v1 = Native::Math::Vector2.new(1.0, 2.0)
      v2 = Native::Math::Vector2.new(1.0, 2.0)
      
      (v1 == v2).should be_true
    end
    
    it "returns false for different vectors" do
      v1 = Native::Math::Vector2.new(1.0, 2.0)
      v2 = Native::Math::Vector2.new(3.0, 4.0)
      
      (v1 == v2).should be_false
    end
  end
  
  describe "#to_s" do
    it "returns string representation" do
      v = Native::Math::Vector2.new(1.0, 2.0)
      v.to_s.should eq("(1.0, 2.0)")
    end
  end
end

describe Native::Math::Vector3 do
  describe ".new" do
    it "creates vector with default values" do
      v = Native::Math::Vector3.new
      v.x.should eq(0.0)
      v.y.should eq(0.0)
      v.z.should eq(0.0)
    end
    
    it "creates vector with custom values" do
      v = Native::Math::Vector3.new(1.0, 2.0, 3.0)
      v.x.should eq(1.0)
      v.y.should eq(2.0)
      v.z.should eq(3.0)
    end
  end
  
  describe "#+" do
    it "adds two vectors" do
      v1 = Native::Math::Vector3.new(1.0, 2.0, 3.0)
      v2 = Native::Math::Vector3.new(4.0, 5.0, 6.0)
      result = v1 + v2
      
      result.x.should eq(5.0)
      result.y.should eq(7.0)
      result.z.should eq(9.0)
    end
  end
  
  describe "#-" do
    it "subtracts two vectors" do
      v1 = Native::Math::Vector3.new(5.0, 6.0, 7.0)
      v2 = Native::Math::Vector3.new(2.0, 3.0, 4.0)
      result = v1 - v2
      
      result.x.should eq(3.0)
      result.y.should eq(3.0)
      result.z.should eq(3.0)
    end
  end
  
  describe "#magnitude" do
    it "returns length of vector" do
      v = Native::Math::Vector3.new(1.0, 2.0, 2.0)
      v.magnitude.should eq(3.0)
    end
  end
  
  describe "#dot" do
    it "returns dot product" do
      v1 = Native::Math::Vector3.new(1.0, 2.0, 3.0)
      v2 = Native::Math::Vector3.new(4.0, 5.0, 6.0)
      
      v1.dot(v2).should eq(32.0)
    end
  end
  
  describe "#cross" do
    it "returns cross product" do
      v1 = Native::Math::Vector3.new(1.0, 0.0, 0.0)
      v2 = Native::Math::Vector3.new(0.0, 1.0, 0.0)
      result = v1.cross(v2)
      
      result.x.should eq(0.0)
      result.y.should eq(0.0)
      result.z.should eq(1.0)
    end
  end
end

describe Native::Math::Rect do
  describe ".new" do
    it "creates rect with default values" do
      r = Native::Math::Rect.new
      r.x.should eq(0.0)
      r.y.should eq(0.0)
      r.width.should eq(0.0)
      r.height.should eq(0.0)
    end
    
    it "creates rect with custom values" do
      r = Native::Math::Rect.new(10.0, 20.0, 100.0, 200.0)
      r.x.should eq(10.0)
      r.y.should eq(20.0)
      r.width.should eq(100.0)
      r.height.should eq(200.0)
    end
  end
  
  describe "#left" do
    it "returns left edge" do
      r = Native::Math::Rect.new(10.0, 20.0, 100.0, 200.0)
      r.left.should eq(10.0)
    end
  end
  
  describe "#right" do
    it "returns right edge" do
      r = Native::Math::Rect.new(10.0, 20.0, 100.0, 200.0)
      r.right.should eq(110.0)
    end
  end
  
  describe "#top" do
    it "returns top edge" do
      r = Native::Math::Rect.new(10.0, 20.0, 100.0, 200.0)
      r.top.should eq(20.0)
    end
  end
  
  describe "#bottom" do
    it "returns bottom edge" do
      r = Native::Math::Rect.new(10.0, 20.0, 100.0, 200.0)
      r.bottom.should eq(220.0)
    end
  end
  
  describe "#center_x" do
    it "returns center X" do
      r = Native::Math::Rect.new(10.0, 20.0, 100.0, 200.0)
      r.center_x.should eq(60.0)
    end
  end
  
  describe "#center_y" do
    it "returns center Y" do
      r = Native::Math::Rect.new(10.0, 20.0, 100.0, 200.0)
      r.center_y.should eq(120.0)
    end
  end
  
  describe "#contains_point?" do
    it "returns true when point is inside" do
      r = Native::Math::Rect.new(10.0, 20.0, 100.0, 200.0)
      point = Native::Math::Vector2.new(50.0, 100.0)
      
      r.contains_point(point).should be_true
    end
    
    it "returns false when point is outside" do
      r = Native::Math::Rect.new(10.0, 20.0, 100.0, 200.0)
      point = Native::Math::Vector2.new(200.0, 300.0)
      
      r.contains_point(point).should be_false
    end
  end
  
  describe "#intersects?" do
    it "returns true when rects intersect" do
      r1 = Native::Math::Rect.new(10.0, 10.0, 100.0, 100.0)
      r2 = Native::Math::Rect.new(50.0, 50.0, 100.0, 100.0)
      
      r1.intersects(r2).should be_true
    end
    
    it "returns false when rects don't intersect" do
      r1 = Native::Math::Rect.new(10.0, 10.0, 100.0, 100.0)
      r2 = Native::Math::Rect.new(200.0, 200.0, 100.0, 100.0)
      
      r1.intersects(r2).should be_false
    end
  end
end

describe Native::Math::Color do
  describe ".from_rgba" do
    it "converts 0-255 values to 0-1" do
      color = Native::Math::Color.from_rgba(255, 128, 64, 255)
      
      color.r.should eq(1.0)
      color.g.should be_close(0.50196, 0.0001)
      color.b.should be_close(0.25098, 0.0001)
      color.a.should eq(1.0)
    end
  end
  
  describe ".from_hex" do
    it "converts hex to color" do
      color = Native::Math::Color.from_hex(0xFF3366)
      
      color.r.should eq(1.0)
      color.g.should eq(0.2)
      color.b.should eq(0.4)
    end
  end
  
  describe ".white" do
    it "returns white" do
      color = Native::Math::Color.white
      
      color.r.should eq(1.0)
      color.g.should eq(1.0)
      color.b.should eq(1.0)
      color.a.should eq(1.0)
    end
  end
  
  describe ".black" do
    it "returns black" do
      color = Native::Math::Color.black
      
      color.r.should eq(0.0)
      color.g.should eq(0.0)
      color.b.should eq(0.0)
      color.a.should eq(1.0)
    end
  end
  
  describe "#lerp" do
    it "interpolates between colors" do
      c1 = Native::Math::Color.red
      c2 = Native::Math::Color.blue
      
      result = c1.lerp(c2, 0.5)
      
      result.r.should eq(0.5)
      result.g.should eq(0.0)
      result.b.should eq(0.5)
    end
  end
  
  describe "#with_alpha" do
    it "returns new color with different alpha" do
      color = Native::Math::Color.red
      new_color = color.with_alpha(0.5)
      
      new_color.r.should eq(1.0)
      new_color.g.should eq(0.0)
      new_color.b.should eq(0.0)
      new_color.a.should eq(0.5)
    end
  end
  
  describe "#to_hex" do
    it "converts color to hex" do
      color = Native::Math::Color.from_rgba(255, 51, 102, 255)
      hex = color.to_hex
      
      hex.should eq(0xFF3366FF)
    end
  end
end
