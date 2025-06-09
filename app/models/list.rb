class List < ApplicationRecord
    # acts_as_list gerencia a coluna 'position'
    acts_as_list

    has_many :tasks, dependent: :destroy
    validates :name, presence: true

    # O default_scope para ordenar por posição é uma boa prática com acts_as_list
    default_scope { order(position: :asc) }

end