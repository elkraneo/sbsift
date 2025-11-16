class Sbsift < Formula
  desc "Context-efficient Swift build analysis tool for Claude agents"
  homepage "https://github.com/elkraneo/sbsift"
  url "https://github.com/elkraneo/sbsift/archive/refs/tags/v1.0.0.tar.gz"
  sha256 ""  # Will be filled when release is created
  license "MIT"

  depends_on :macos
  depends_on xcode: ["14.0", :build]

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/sbsift"
  end

  test do
    # Basic functionality test
    test_output = pipe_output("#{bin}/sbsift --format summary", "Test input")
    assert_match "sbsift", test_output
  end
end