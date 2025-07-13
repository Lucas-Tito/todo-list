# Create or find a default User.
puts "Seed: ensuring the existence of a default user..."
default_user = User.find_or_create_by!(email: 'default_user@example.com') do |user|
  user.name = 'Default User'
  user.uid = 'default_user_uid' 
end
puts "Seed: default user '#{default_user.name}' ready."

# Create or find a default Board associated with default user.
puts "Seed: ensuring the existence of a default board..."
default_board = default_user.boards.find_or_create_by!(name: "Meu Primeiro Board")
puts "Seed: default board '#{default_board.name}' ready."


# Create lists inside default board.
puts "Seed: creating lists..."
work_list = default_board.lists.find_or_create_by!(name: "Trabalho") do |list|
  list.description = "Tarefas relacionadas ao trabalho."
end

personal_list = default_board.lists.find_or_create_by!(name: "Pessoal") do |list|
  list.description = "Tarefas pessoais e do dia a dia."
end

study_list = default_board.lists.find_or_create_by!(name: "Estudos") do |list|
  list.description = "Tarefas e metas de estudo."
end
puts "Seed: lists created with success!"


# Create Tasks and associate with lists
if Task.exists?
  puts "Seed: Tasks already exist, skipping creation."
else
  puts "Seed: creating initial tasks and associating with lists..."

  Task.create!(
    title: "Prova de Semiótica",
    description: "Parte básica de semiótica, a prova tem folhinha com textos e imagens.",
    due_date: Date.today + 7.days,
    priority: :high,
    list: study_list
  )

  Task.create!(
    title: "Apresentação de Artigos",
    description: "Pesquisar artigos relacionados a semiótica e apresentar em grupo.",
    due_date: Date.today + 14.days,
    priority: :medium,
    list: study_list
  )

  Task.create!(
    title: "Reunião de Planejamento Sprint",
    description: "Definir as prioridades para a próxima sprint.",
    due_date: Date.today + 2.days,
    priority: :high,
    list: work_list
  )

  Task.create!(
    title: "Comprar mantimentos",
    description: "Lista de compras para a semana.",
    due_date: Date.today + 1.day,
    priority: :medium,
    list: personal_list
  )

  puts "Seed: tasks created and associated with success!"
end

puts "Seed finished!"
