# spec/math_edge_spec.cr
#
# Boundary and failure-path coverage for the scalar math helpers.
# A few of these pin quirky-but-current behavior so any change to it
# is a conscious decision, not an accident.

require "./spec_helper"

describe Native::Math do
  describe ".clamp" do
    it "keeps values sitting exactly on the boundaries" do
      Native::Math.clamp(0, 0, 10).should eq(0)
      Native::Math.clamp(10, 0, 10).should eq(10)
    end

    it "clamps floats below and above the range" do
      Native::Math.clamp(2.5, 0.0, 1.0).should eq(1.0)
      Native::Math.clamp(-0.5, 0.0, 1.0).should eq(0.0)
    end

    it "clamps negative ranges" do
      Native::Math.clamp(-1, -10, -5).should eq(-5)
      Native::Math.clamp(-20, -10, -5).should eq(-10)
    end

    it "returns the upper bound for an inverted range (documents current behavior)" do
      # clamp checks `value < min` first, so with min > max the larger
      # bound always wins regardless of the value.
      Native::Math.clamp(5, 10, 0).should eq(10)
      Native::Math.clamp(-100, 10, 0).should eq(10)
    end

    it "handles a degenerate min == max range" do
      Native::Math.clamp(-3, 2, 2).should eq(2)
      Native::Math.clamp(7, 2, 2).should eq(2)
      Native::Math.clamp(2, 2, 2).should eq(2)
    end
  end

  describe ".lerp" do
    it "returns a for t = 0 and b for t = 1" do
      Native::Math.lerp(3.0, 7.0, 0.0).should eq(3.0)
      Native::Math.lerp(3.0, 7.0, 1.0).should eq(7.0)
    end

    it "interpolates halfway exactly" do
      Native::Math.lerp(1.0, 2.0, 0.5).should eq(1.5)
    end

    it "works with negative endpoints" do
      Native::Math.lerp(-10.0, 10.0, 0.5).should eq(0.0)
    end

    it "clamps t outside [0, 1] instead of extrapolating (documents current behavior)" do
      Native::Math.lerp(0.0, 10.0, -1.0).should eq(0.0)
      Native::Math.lerp(0.0, 10.0, 2.0).should eq(10.0)
      Native::Math.lerp(0.0, 10.0, 1000.0).should eq(10.0)
    end

    it "returns a when both endpoints are equal, for any t" do
      Native::Math.lerp(5.0, 5.0, 0.7).should eq(5.0)
      Native::Math.lerp(5.0, 5.0, -3.0).should eq(5.0)
    end
  end

  describe ".map" do
    it "maps the midpoint of the source range to the midpoint of the target range" do
      Native::Math.map(5.0, 0.0, 10.0, 0.0, 100.0).should eq(50.0)
    end

    it "maps the range edges exactly" do
      Native::Math.map(0.0, 0.0, 10.0, 0.0, 100.0).should eq(0.0)
      Native::Math.map(10.0, 0.0, 10.0, 0.0, 100.0).should eq(100.0)
    end

    it "extrapolates outside the source range instead of clamping (documents current behavior)" do
      Native::Math.map(15.0, 0.0, 10.0, 0.0, 100.0).should eq(150.0)
      Native::Math.map(-5.0, 0.0, 10.0, 0.0, 100.0).should eq(-50.0)
    end

    it "handles an inverted source range" do
      Native::Math.map(5.0, 10.0, 0.0, 0.0, 100.0).should eq(50.0)
    end

    it "produces non-finite results for a zero-width source range (documents current behavior)" do
      # 0/0 -> NaN, x/0 -> Infinity; float math does not raise here.
      Native::Math.map(0.0, 0.0, 0.0, 0.0, 100.0).nan?.should be_true
      Native::Math.map(1.0, 0.0, 0.0, 0.0, 100.0).should eq(Float64::INFINITY)
    end
  end
end
