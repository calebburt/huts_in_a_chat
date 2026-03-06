CI = Struct.new(:run) do
  def initialize
    super(method(:default_run))
  end

  private

  def default_run
    step "Run tests" do
      system! "bin/rails test"
    end

    step "Run system tests" do
      system! "bin/rails test:system"
    end

    step "Lint with RuboCop" do
      system! "bin/rubocop"
    end

    step "Scan for security vulnerabilities" do
      system! "bin/brakeman --no-pager"
    end
  end

  def step(name, &block)
    puts "\n--- #{name} ---"
    block.call
  end

  def system!(*args)
    system(*args, exception: true)
  end
end.new
