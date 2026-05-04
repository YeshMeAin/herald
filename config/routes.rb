Herald::Engine.routes.draw do
  post "webhook", to: "webhook#receive"
end
