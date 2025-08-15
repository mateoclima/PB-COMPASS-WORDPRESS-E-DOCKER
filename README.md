# 🐳 Projeto AWS utilizando Docker:  Arquitetura de Alta Disponibilidade na AWS.

## 📖 Descrição
Este projeto tem como objetivo implantar a plataforma **WordPress** na nuvem **AWS** com foco em **escalabilidade**, **alta disponibilidade** e **tolerância a falhas**.  
A arquitetura proposta utiliza serviços gerenciados e recursos distribuídos para simular um ambiente de produção robusto, seguro e de fácil manutenção.

> A implementação foi feita com base em boas práticas de arquitetura na AWS, considerando separação de camadas, redundância e automação.

---

## 🎯 Objetivos
- Desenvolver competências práticas em **Infraestrutura como Código (IaC)** (opcionalmente usando Terraform ou AWS CloudFormation).
- Provisionar recursos de forma **segura**, **automatizada** e **escalável**.
- Implementar uma arquitetura **resiliente** para aplicações web críticas.
- Explorar serviços essenciais da **AWS** para ambientes **altamente disponíveis**.

---

## 🏗 Arquitetura da Solução

### Componentes Principais
- **VPC personalizada** com subnets públicas e privadas distribuídas em múltiplas zonas de disponibilidade (AZs).
- **Amazon RDS (MySQL/MariaDB)** para banco de dados relacional gerenciado.
- **Amazon EFS** para armazenamento compartilhado entre instâncias.
- **EC2 Auto Scaling Group (ASG)** para execução do WordPress com capacidade ajustável.
- **Application Load Balancer (ALB)** para distribuição de tráfego.
- **Security Groups** configurados para isolar camadas de rede e controlar acessos.

---

### Fluxo de Dados
1. O usuário acessa o **ALB** nas subnets públicas.
2. O **ALB** encaminha requisições para instâncias EC2 no ASG (em subnets privadas).
3. As instâncias EC2:
   - Acessam o **RDS** para dados do WordPress.
   - Utilizam o **EFS** para armazenar uploads e arquivos compartilhados.
4. O **ASG** escala automaticamente com base em métricas (ex.: CPU ≥ 70%).

---

## 📊 Diagrama da Arquitetura
> [Referência: ARQUITETURA.png]

---

## 🛠 Serviços AWS Utilizados
- **Amazon VPC** → Criação de rede isolada com roteamento configurado.
- **Subnets Públicas e Privadas** → Separação de camadas web e banco de dados.
- **Internet Gateway (IGW)** → Permitir acesso externo às subnets públicas.
- **NAT Gateway** → Permitir que instâncias privadas acessem a internet para atualizações.
- **Amazon EC2** → Execução do WordPress.
- **Amazon RDS** → Banco de dados relacional gerenciado.
- **Amazon EFS** → Armazenamento compartilhado persistente.
- **Application Load Balancer (ALB)** → Balanceamento e health checks.
- **Auto Scaling Group (ASG)** → Escalabilidade automática.
- **AWS CloudWatch** *(opcional)* → Monitoramento e alarmes.

---

## 📋 Etapas de Implementação

### 1️⃣ Conhecer o WordPress localmente
Antes de implantar na AWS, teste o WordPress usando Docker:
```bash
docker-compose up -d
```
[Imagem Oficial no Docker Hub](https://hub.docker.com/_/wordpress)

---

### 2️⃣ Criar a VPC
- Criar **1 VPC personalizada** (ex.: `10.0.0.0/16`).
- Criar **2 subnets públicas** e **4 privadas**, distribuídas em pelo menos **2 AZs**.
- Associar um **Internet Gateway** às subnets públicas.
- Criar um **NAT Gateway** em cada subnet pública para permitir acesso à internet nas privadas.

[Referência: VPC.png]

---

### 3️⃣ Criar os Security Groups
Seguir **princípio do menor privilégio**.

**SG-ALB**  
- Entrada: HTTP (0.0.0.0/0)  
- Saída: HTTP (SG-EC2)

**SG-EC2**  
- Entrada: HTTP (SG-ALB), MySQL (SG-RDS), NFS (SG-NFS)  
- Saída: Qualquer (apenas quando necessário)

**SG-RDS**  
- Entrada: MySQL (SG-EC2)  
- Saída: MySQL (SG-EC2)

**SG-NFS**  
- Entrada: NFS (SG-EC2)  
- Saída: NFS (SG-EC2)

---

### 4️⃣ Criar o RDS
- Engine: **MySQL** ou **MariaDB**  
- Classe: `db.t3.micro` (Free Tier)  
- Multi-AZ (opcional em ambientes de estudo)  
- Desativar acesso público (Public Access = No)  
- Associar **SG-RDS**  
- Criar banco com nome igual ao do identificador.

---

### 5️⃣ Criar o EFS
- Criar **EFS** com configuração personalizada.
- Ativar pontos de montagem nas subnets privadas 3 e 4.
- Associar **SG-NFS**.
- Ativar criptografia em repouso.

[Referência: EFS1.png]  
[Referência: EFS2.png]

---

### 6️⃣ Criar o Launch Template
- SO: **Amazon Linux 2** ou **Ubuntu Server**.
- Tipo: `t2.micro` (Free Tier) ou superior.
- Associar **SG-EC2**.
- User Data (`USERDATA.sh`):
  - Instalar PHP, Apache/Nginx e pacotes do WordPress.
  - Montar EFS (ex.: `/var/www/html/wp-content/uploads`).
  - Configurar conexão com o banco no `wp-config.php`.

---

### 7️⃣ Criar o Target Group
- Tipo: **Instances**.
- Health Check Path: `/` ou `/wp-admin/images/wordpress-logo.svg`.

[Referência: TG.png]

---

### 8️⃣ Criar o Application Load Balancer
- Associar às **subnets públicas**.
- Configurar listener HTTP:80 → Target Group.
- Adicionar **Redirect HTTP → HTTPS** se usar certificado SSL no futuro.

[Referência: ALB.png]

---

### 9️⃣ Criar o Auto Scaling Group
- Usar o **Launch Template** criado.
- Associar ao **Target Group**.
- Definir:
  - Desejado: `2`
  - Mínimo: `2`
  - Máximo: `4`
- Política de escalabilidade: CPU > 70% por 2 minutos.

[Referência: ASG1.png]  
[Referência: ASG2.png]

---

### 🔟 Resultado Final
Se configurado corretamente:
- O ALB distribui tráfego para as EC2.
- O WordPress utiliza RDS e EFS de forma compartilhada.
- Escalabilidade automática e alta disponibilidade garantidas.

[Referência: image.png]

---

## ⚠️ Boas Práticas e Considerações
- **Tags**:
  - Contas AWS utilizadas para estudo possuem **restrições**:  
  - Por exemplo: Instâncias EC2 podem exigir tags para efetuar a criação.
- **Custos**:
  - Encerrar recursos após o uso para evitar cobranças.
  - Monitorar gastos utilizando o **Cost Explorer**.
- **Backup**:
  - Ativar snapshots automáticos no RDS.
  - Fazer backup periódico do EFS.
---
