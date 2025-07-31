
# 🔐 validador-senha-api

API desenvolvida para validar senhas com regras específicas de segurança. Projeto construído com Java 17 e Spring Boot, seguindo boas práticas de Clean Code, autenticação via `client_credentials`, validação com token JWT e deploy automatizado na AWS.

## 📌 Funcionalidade

A API valida se uma senha enviada cumpre os critérios exigidos:

- Possui pelo menos 9 caracteres
- Contém pelo menos uma letra minúscula
- Contém pelo menos uma letra maiúscula
- Contém pelo menos um dígito
- Contém pelo menos um caractere especial (!@#$%^&*()-+)
- Não possui caracteres repetidos
- Não possui espaços em branco

## 🔑 Autenticação

A API utiliza o fluxo `client_credentials`.

1. O frontend envia `client_id`, `client_secret` e `grant_type` para o endpoint:

```
POST /oauth/token
```

2. A API gera um token JWT válido de acesso.

3. Para validar a senha, o frontend envia o token no header `Authorization: Bearer <token>` para:

```
POST /api/validar
```

## 📥 Exemplo de Requisição

### Gerar token

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&
client_id=frontend-itau&
client_secret=segredo123
```

### Validar senha

```
POST /api/validar
Authorization: Bearer <token>
Content-Type: application/json

{
  "senha": "Senha@123"
}
```

## 📤 Resposta da API

```json
{
  "valida": true,
  "motivos": []
}
```

Se inválida:

```json
{
  "valida": false,
  "motivos": [
    "A senha deve conter ao menos uma letra maiúscula.",
    "A senha não pode conter caracteres repetidos."
  ]
}
```

## ⚙️ Tecnologias Utilizadas

| Tecnologia        | Descrição                                 |
|-------------------|---------------------------------------------|
| Java 17           | Linguagem principal                        |
| Spring Boot       | Framework para criação da API REST         |
| JWT (jjwt)        | Geração e validação de tokens              |
| Maven             | Gerenciador de dependências                |
| GitHub Actions    | CI/CD e deploy automatizado na AWS         |
| Terraform         | Infraestrutura como código (IaC)           |
| AWS EC2           | Execução do backend em ambiente de nuvem   |
| API Gateway       | Exposição da API de forma segura           |

## 🚀 Como Rodar Localmente

1. Clone o projeto:

```bash
git clone https://github.com/seu-usuario/validador-senha-api.git
cd validador-senha-api
```

2. Configure as variáveis no `.env` ou em `application.properties`:

```properties
CLIENT_ID=frontend-itau
CLIENT_SECRET=segredo123
JWT_SECRET=itau-secret-itau-secret-itau-secret
```

3. Rode o projeto:

```bash
./mvnw spring-boot:run
```

4. Acesse:

```
http://localhost:8080
```

## 🛠️ Estrutura do Projeto

```
src/
├── controller/          # Endpoints REST
├── service/             # Lógica de negócio da senha
├── model/               # Request e Response
├── config/              # Configuração CORS e JWT
└── application.properties
```

## ⚠️ Observação sobre CORS

Atualmente, a integração entre o frontend hospedado na AWS (S3 + API Gateway) e este backend pode falhar por **erro de CORS**. Esse problema será corrigido em breve com ajustes adicionais na configuração da API Gateway e CORS.

## 📁 Deploy

- O deploy está automatizado via GitHub Actions e Terraform.
- Cada push na branch `main` promove o backend para o ambiente `dev` na AWS EC2.

## 🧪 Testes

Testes unitários implementados para validar as regras da senha.

## 👩‍💻 Autora

**Angelita Vilas Boas**  
Contadora em transição para tecnologia | Desenvolvedora Java & Angular  
[LinkedIn](https://www.linkedin.com/in/angelitavilasboas)





