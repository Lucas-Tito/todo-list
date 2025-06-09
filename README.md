### Comandos Docker Compose

Agora, no seu terminal, na raiz do projeto:

1.  **Buildar as imagens (só precisa na primeira vez ou se mudar o `Dockerfile.dev` ou `Gemfile`):**
    ```bash
    docker-compose build
    ```

2.  **Iniciar os serviços (app e db):**
    ```bash
    docker-compose up
    ```
    Você verá os logs do Rails e do PostgreSQL. Sua aplicação Rails estará acessível em `http://localhost:3000`.

3.  **Para parar os serviços:**
    Pressione `Ctrl+C` no terminal onde o `docker-compose up` está rodando. Depois, para garantir que os containers parem e sejam removidos (mas os volumes de dados persistam):
    ```bash
    docker-compose down
    ```

4.  **Executar comandos Rails (como criar o banco, migrations, console):**
    Com os serviços rodando (após `docker-compose up`), abra um **novo terminal** e use `docker-compose exec app ...`:

    * **Criar os bancos de dados (só na primeira vez):**
        ```bash
        docker-compose exec app rails db:create
        ```
    * **Rodar migrations:**
        ```bash
        docker-compose exec app rails db:migrate
        ```
    * **Acessar o console do Rails:**
        ```bash
        docker-compose exec app rails console
        ```
    * **Acessar o terminal dentro do container da aplicação:**
        ```bash
        docker-compose exec app bash
        ```

### Próximos Passos e Considerações:

* **`.dockerignore`**: Crie um arquivo `.dockerignore` na raiz do seu projeto para evitar copiar arquivos desnecessários para dentro do container (como `log/*`, `tmp/*`, `.git`, `node_modules` se você gerencia eles localmente, etc.), o que acelera os builds.
    Exemplo de `.dockerignore`:
    ```
    .git
    .gitignore
    node_modules/
    tmp/
    log/
    storage/ # Se você não quiser que o storage local vá para a imagem
    public/assets/ # Se você pré-compila localmente e não quer na imagem
    .DS_Store
    Dockerfile
    Dockerfile.dev
    docker-compose.yml
    README.md
    .env # Se você usar um arquivo .env para senhas, não o copie para a imagem
    ```
* **Persistência de Dados**: O volume `postgres_data` no `docker-compose.yml` garante que os dados do seu banco PostgreSQL não sejam perdidos quando você rodar `docker-compose down`.
* **Credenciais**: Evite colocar senhas diretamente no `docker-compose.yml` se o projeto for compartilhado. Uma prática comum é usar arquivos `.env` (e adicionar `.env` ao `.gitignore`). O Docker Compose pode ler variáveis de um arquivo `.env` automaticamente.

Esta configuração deve fornecer um ambiente de desenvolvimento Rails com PostgreSQL robusto e portátil usando Docker! Pode parecer muita coisa no início, mas os benefícios a longo prazo são enormes.











### Others

sudo docker-compose down -v
sudo docker-compose run --rm app rails db:create db:migrate


sudo lsof -i :5432
sudo kill <pid>