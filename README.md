# 🐳 Projeto WordPress - Infraestrutura com Alta Disponibilidade na AWS
Este repositório tem como objetivo documentar a implementação de uma aplicação segura, resiliente, limpa e,principalmente, escalavel dentro da Amazon Web Services(AWS), ademais sendo tolerante a falhas. 

## 💻 Tecnolgias Utilizadas:

<p align="center">
  <a href="https://skillicons.dev">
    <img src="https://skillicons.dev/icons?i=aws,docker,wordpress" />
  </a>
</p>


## 📝 Sobre o Projeto:

Este projeto implementa uma solução completa para hospedar o WordPress na AWS, com foco em:

- Alta Disponibilidade: Recursos distribuídos em duas Zonas de Disponibilidade (AZs), garantindo tolerância a falhas.

- Escalabilidade: Auto Scaling Group, responsável por ajustar a quantidade de aplicações web de acordo com a demanda.

- Segurança: Arquitetura de 3 camadas (pública, aplicação e dados), utilizando sub-redes isoladas e grupos/regras de segurança (segurity groups) específicas para proteger tanto a aplicação quanto o fluxo de dados.

- Dados Persistentes e Compartilhados: Uso do Amazon EFS para armazenamento de mídia, plugins e temas, compartilhado entre todas as instâncias, e Amazon RDS para banco de dados gerenciado e resiliente.

- Automação: Implantação da aplicação conteinerizada com Docker via user-data.

Essa abordagem elimina pontos únicos de falha e permite lidar com aumento de tráfego sem comprometer a aplicação.

## 🎯 Objetivos
- Desenvolver competências práticas em Infraestrutura como Código (IaC).
- Provisionar recursos de forma segura e escalável.
- Implementar arquitetura resiliente para aplicações web.
- Explorar serviços essenciais da AWS no contexto de alta disponibilidade.

## ☁️ Arquitetura

A solução é composta por:
- **VPC personalizada** com subnets públicas e privadas.
- **Amazon RDS** (MySQL/MariaDB) para banco de dados relacional.
- **Amazon EFS** para armazenamento compartilhado.
- **Auto Scaling Group (ASG)** para instâncias EC2.
- **Application Load Balancer (ALB)** para balanceamento de carga.
- Configuração de **Security Groups** e permissões adequadas.

![Diagrama](images/diagrama.png)  

**Fluxo da Arquitetura:**
1. O tráfego chega ao **ALB** (subnets públicas).
2. O ALB distribui requisições para as instâncias EC2 (subnets privadas).
3. As instâncias acessam o banco de dados no **RDS** e arquivos no **EFS**.
4. O **ASG** escala automaticamente com base no uso de CPU.

## ⚙️ Etapas de Implementação do Projeto

### 1️⃣ Conhecer o WordPress localmente  
<p align="center">
  <a href="https://skillicons.dev">
    <img src="https://skillicons.dev/icons?i=docker" />
  </a>
</p>

- Executar via **Docker Compose**: [Imagem Oficial](https://hub.docker.com/_/wordpress)  

---

### 2️⃣ Criar a VPC  
- Criar **subnets públicas e privadas**.  
- Configurar **Internet Gateway (IGW)** e **NAT Gateway**.   

![Criação da VPC](images/vpc1.png)  

![Criação da VPC](images/vpc2.png)  

- 🔎 *Nota*: em produção o ideal é usar **2 NAT Gateways** (um por AZ). 

---

### 3️⃣ Criar os Security Groups  

| Security Group | Direção  | Protocolo | Porta | Origem/Destino | Observação                         |
| -------------- | -------- | --------- | ----- | -------------- | ---------------------------------- |
| **ALB**        | Inbound  | TCP       | 80    | 0.0.0.0/0      | HTTP aberto para o público         |
|                | Inbound  | TCP       | 443   | 0.0.0.0/0      | HTTPS aberto para o público        |
|                | Outbound | All       | All   | 0.0.0.0/0      | Necessário para encaminhar tráfego |
| **EC2**        | Inbound  | TCP       | 80    | SG do ALB      | Recebe tráfego HTTP do ALB         |
|                | Outbound | TCP       | 3306  | SG do RDS      | Conecta ao banco MySQL/Aurora      |
|                | Outbound | TCP       | 2049  | SG do EFS      | Monta o EFS                        |
|                | Outbound | TCP       | 443   | 0.0.0.0/0      | Acessa serviços externos via HTTPS |
| **RDS**        | Inbound  | TCP       | 3306  | SG da EC2      | Somente EC2 pode acessar o banco   |
|                | Outbound | Nenhuma   | -     | -              | RDS não inicia conexões            |
| **EFS**        | Inbound  | TCP       | 2049  | SG da EC2      | Somente EC2 pode montar o EFS      |
|                | Outbound | Nenhuma   | -     | -              | Não é necessário outbound          | 

---

### 4️⃣ Criar o RDS  
- Banco **MySQL**  
- **Free Tier**  
- Tipo: `db.t3.micro`  
- Associar à **VPC**  
- Selecionar **Security Group** do RDS  
- Nome do banco igual ao identificador (`DbWordPress`)  

![Criação da RDS](images/rds1.png)  

![Criação da RDS](images/rds2.png)

![Criação da RDS](images/rds3.png)  

![Criação da RDS](images/rds4.png)  

![Criação da RDS](images/rds5.png)  

![Criação da RDS](images/rds6.png)

![Criação da RDS](images/rds7.png)  

- 🔎 *Nota*: em produção, recomenda-se usar **AWS Secrets Manager** para credenciais.  

---

### 5️⃣ Criar o EFS  
- Criar **EFS** e selecionar **Personalizar**.  

![Criação da EFS](images/efs1.png)    

- Configurar nas **subnets privadas 3 e 4**.  

![Criação da EFS](images/efs2.png)  

- Configurar o **Security Group** do EFS (entrada/saída em NFS).  

---

### 6️⃣ Criar o Launch Template  
- SO: **Amazon Linux**  
- Tipo: `t2.micro`  
- Associar **Security Group** das EC2  
- Selecionar **VPC** (sem especificar subnets)  
- Adicionar script [`Userdata.sh`](./Userdata.sh) para:  
  - Instalar Docker e WordPress  
  - Montar EFS  
  - Conectar ao RDS  

![Criação da Lauch](images/lauchTemplate1.png) 

![Criação da Lauch](images/lauchTemplate2.png) 

![Criação da Lauch](images/lauchTemplate3.png) 

![Criação da Lauch](images/lauchTemplate4.png) 

---

### 7️⃣ Configurar o Target Group  
- **Tipo**: Instances  

![Target Group](images/target1.png)   

- **Health Check Path**: `/` ou `/wp-admin/images/wordpress-logo.svg`  

![Target Group](images/target2.png)  

- 🔎 *Nota*: usar códigos de sucesso `200` e `302`  

---

### 8️⃣ Criar o Application Load Balancer  
- Associar às **subnets públicas**  
- Direcionar para o **Target Group**  

![ALB](images/load1.png)  

![ALB](images/load2.png)

![ALB](images/load3.png)

![ALB](images/load4.png)  

---

### 9️⃣ Configurar o Auto Scaling Group  
- Utilizar a **imagem criada** (ou Launch Template)  

![ASG](images/auto1.png)  

- Associar ao **ALB**  

![ASG](images/auto2.png)   

- Associar ao **Target** 

![ASG](images/auto3.png) 

- Definir capacidade:  
  - **Desejado**: 2  
  - **Mínimo**: 2  
  - **Máximo**: 4 

![ASG](imgs/auto4.png)  
---

### 🔟 Resultado Final  
Se tudo ocorrer corretamente:  

![RESULTADO](images/resultado.png) 

- O ALB distribui tráfego entre as instâncias.  
- Uploads de mídia e temas são armazenados no **EFS**.  
- O banco de dados é persistido no **RDS**.  
- O **ASG** substitui instâncias em caso de falha.  

---

## 🔐 Boas Práticas e Observações  

- As contas AWS utilizadas em ambiente de estudo possuem limitações → **excluir recursos após o uso**.  
- Monitorar custos no **Cost Explorer**.  
- Restrições para este projeto didático:  
  - Instâncias EC2 podem precisar conter tags obrigatórias.  
  - RDS deve ser **db.t3g.micro**.  
---

## ✅ Conclusão  

Este projeto demonstrou como implementar o **WordPress em alta disponibilidade na AWS**, aplicando boas práticas de arquitetura em nuvem, segurança e escalabilidade.  
Ele consolida conhecimentos em:  

- Infraestrutura como Código  
- Configuração de redes e sub-redes privadas/públicas  
- Uso de serviços gerenciados (RDS, EFS, ALB, ASG)  
- Automação com *user-data* e Docker  

🔎 Embora tenha sido feito em um ambiente de estudo, os conceitos aplicados podem ser expandidos para **ambientes de produção reais**, adicionando melhorias como **o monitoramento com CloudWatch
 e uso de Secrets Manager**.  

Assim, este projeto serve como base sólida para **ambientes web escaláveis, resilientes e prontos para crescimento**.  

---

✍️ **Autor:** Matheus José
