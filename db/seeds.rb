# db/seeds.rb

# Criar Boards
puts "Seed: criando boards..."
work_board = Board.find_or_create_by!(name: "Trabalho") do |board|
  board.description = "Tarefas relacionadas ao trabalho."
end

personal_board = Board.find_or_create_by!(name: "Pessoal") do |board|
  board.description = "Tarefas pessoais e do dia a dia."
end

study_board = Board.find_or_create_by!(name: "Estudos") do |board|
  board.description = "Tarefas e metas de estudo."
end
puts "Seed: boards criados com sucesso!"

# Criar Tarefas e associá-las a Boards
if Task.exists?
  puts "Seed: tarefas já existem, associando a boards ou pulando criação."
else
  puts "Seed: criando tarefas iniciais e associando a boards..."

  Task.create!(
    title: "Prova de Semiótica",
    description: "Parte básica de semiótica, a prova tem folhinha com textos e imagens.",
    due_date: Date.today + 7.days,
    priority: :high,
    board: study_board # Associando ao board de Estudos
  )

  Task.create!(
    title: "Apresentação de Artigos",
    description: "Pesquisar artigos relacionados a semiótica e apresentar em grupo.",
    due_date: Date.today + 14.days,
    priority: :medium,
    board: study_board # Associando ao board de Estudos
  )

  Task.create!(
    title: "Reunião de Planejamento Sprint",
    description: "Definir as prioridades para a próxima sprint.",
    due_date: Date.today + 2.days,
    priority: :high,
    board: work_board # Associando ao board de Trabalho
  )

  Task.create!(
    title: "Comprar mantimentos",
    description: "Lista de compras para a semana.",
    due_date: Date.today + 1.day,
    priority: :medium,
    board: personal_board # Associando ao board Pessoal
  )

  puts "Seed: tarefas criadas e associadas com sucesso!"
end

puts "Seed finalizado!"