# db/seeds.rb
if Task.exists?
    puts "Seed: tarefas já existem, pulando criação."
  else
    puts "Seed: criando tarefas iniciais..."
  
    Task.create!(
      title: "Prova de Semiótica",
      description: "Parte básica de semiótica, a prova tem folhinha com textos e imagens.",
      due_date: Date.today + 7.days,
      priority: :high
    )
  
    Task.create!(
      title: "Apresentação de Artigos",
      description: "Pesquisar artigos relacionados a semiótica e apresentar em grupo.",
      due_date: Date.today + 14.days,
      priority: :medium
    )
  
    Task.create!(
      title: "Trabalho Final",
      description: "Produzir projeto de aplicação prática envolvendo semiótica.",
      due_date: Date.today + 30.days,
      priority: :low
    )
  
    puts "Seed: tarefas criadas com sucesso!"
  end
  