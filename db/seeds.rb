# db/seeds.rb

# 1. Primeiro, crie ou encontre um Board padrão.
puts "Seed: garantindo a existência de um board padrão..."
default_board = Board.find_or_create_by!(name: "Meu Primeiro Board")
puts "Seed: board padrão '#{default_board.name}' pronto."


# 2. Agora, crie as Lists DENTRO do board padrão.
puts "Seed: criando lists..."
# Note a mudança: default_board.lists.find_or_create_by!
work_list = default_board.lists.find_or_create_by!(name: "Trabalho") do |list|
  list.description = "Tarefas relacionadas ao trabalho."
end

personal_list = default_board.lists.find_or_create_by!(name: "Pessoal") do |list|
  list.description = "Tarefas pessoais e do dia a dia."
end

study_list = default_board.lists.find_or_create_by!(name: "Estudos") do |list|
  list.description = "Tarefas e metas de estudo."
end
puts "Seed: lists criados com sucesso!"


# 3. Criar Tarefas e associá-las a Lists (esta parte não precisa de alteração)
# A associação com o board já está garantida através da lista.
if Task.exists?
  puts "Seed: tarefas já existem, pulando criação."
else
  puts "Seed: criando tarefas iniciais e associando a lists..."

  Task.create!(
    title: "Prova de Semiótica",
    description: "Parte básica de semiótica, a prova tem folhinha com textos e imagens.",
    due_date: Date.today + 7.days,
    priority: :high,
    list: study_list # Associando ao list de Estudos
  )

  Task.create!(
    title: "Apresentação de Artigos",
    description: "Pesquisar artigos relacionados a semiótica e apresentar em grupo.",
    due_date: Date.today + 14.days,
    priority: :medium,
    list: study_list # Associando ao list de Estudos
  )

  Task.create!(
    title: "Reunião de Planejamento Sprint",
    description: "Definir as prioridades para a próxima sprint.",
    due_date: Date.today + 2.days,
    priority: :high,
    list: work_list # Associando ao list de Trabalho
  )

  Task.create!(
    title: "Comprar mantimentos",
    description: "Lista de compras para a semana.",
    due_date: Date.today + 1.day,
    priority: :medium,
    list: personal_list # Associando ao list Pessoal
  )

  puts "Seed: tarefas criadas e associadas com sucesso!"
end

puts "Seed finalizado!"
