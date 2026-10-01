module Jasper
  abstract class Plugin
    abstract def setup(pipeline : Pipeline) : Nil
  end
end
