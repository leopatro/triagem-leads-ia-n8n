Triagem de Leads Comerciais com IA

Automação que recebe leads comerciais (via formulário ou API), usa um LLM para classificar prioridade e categoria, aplica validação de segurança contra prompt injection, notifica o time comercial e registra tudo de forma estruturada — com tratamento de erro em cada ponto de falha possível.

Não é um projeto tecnicamente complexo. É um fluxo simples de automação com IA, construído com o cuidado que normalmente só se vê em sistemas de produção: validação de entrada, resiliência a falhas, e rastreabilidade. A maioria das automações que vejo por aí não tem nem isso.

Problema de negócio

Times comerciais recebem leads por múltiplos canais (formulário do site, WhatsApp, planilhas manuais) sem padronização de triagem. O resultado comum: leads urgentes demoram para ser vistos, leads de baixo interesse consomem tempo da mesma forma que leads quentes, e não existe registro estruturado para medir volume, origem ou tempo de resposta.

Solução

Um pipeline de automação que:

Recebe o lead por formulário (demo visual) ou webhook (integração via API).
Valida a mensagem contra tamanho excessivo e padrões de manipulação de prompt antes de qualquer chamada de IA.
Envia os dados para um LLM (Groq, modelo openai/gpt-oss-120b), que classifica prioridade (alta/média/baixa), categoria e gera um resumo com justificativa.
Roteia o lead por prioridade, disparando e-mail de confirmação ao lead e, quando a prioridade é alta, um alerta imediato ao time comercial com a justificativa da IA incluída (transparência da decisão).
Registra todos os leads processados em uma planilha, com status de cada etapa — inclusive os rejeitados na validação e os que falharam na chamada de API.
Arquitetura
┌─────────────┐     ┌─────────────┐
│ Form Trigger│     │   Webhook   │
└──────┬──────┘     └──────┬──────┘
       └──────────┬────────┘
                   ▼
          ┌─────────────────┐
          │ Validar Mensagem│  (sanitização + anti prompt-injection)
          └────────┬────────┘
                   ▼
              ┌────────┐
              │   If   │── false ──▶ Rejeitado (log)
              └───┬────┘
          true    │
      ┌───────────┴────────────┐
      ▼                        ▼
┌──────────┐           ┌───────────────┐
│ E-mail   │           │  HTTP Request │── error ──▶ Erro API (log)
│confirmação│          │ (Groq LLM)    │
└──────────┘           └───────┬───────┘
                      success  ▼
                        ┌─────────────┐
                        │Extrai campos│
                        └──────┬──────┘
                               ▼
                          ┌─────────┐
                          │ Switch  │── alta/média/baixa/erro_classificação
                          └────┬────┘
                   alta        │
              ┌────────────────┼──────────────┐
              ▼                                ▼
      ┌───────────────┐              ┌──────────────────┐
      │ Alerta interno│              │ Registro estrutu- │
      │  (e-mail)     │              │ rado (Sheets)     │
      └───────────────┘              └──────────────────┘
Tecnologias
n8n (self-hosted via Docker) — orquestração
Groq API (openai/gpt-oss-120b) — classificação via LLM
JavaScript (node Code) — parsing, validação e normalização de dados
Google Sheets API — registro estruturado
Gmail API — notificações
Docker — ambiente isolado e reprodutível
Decisões técnicas e por quê

HTTP Request genérico em vez de node nativo de IA: escolhido deliberadamente para demonstrar entendimento de como uma chamada de API de LLM funciona por baixo (estrutura de mensagens, roles, temperatura), em vez de depender de uma integração pronta que abstrai esse conhecimento.

Validação contra prompt injection antes da chamada à IA: o campo de mensagem vem de um formulário público — texto livre de usuário indo direto para o prompt é um vetor clássico de manipulação. A validação implementada (limite de tamanho + regex contra padrões conhecidos) não é uma solução completa — é uma primeira camada de defesa. Defesa robusta de verdade também depende de isolar o system prompt do input do usuário na própria estrutura da API (já feito aqui, com role: system separado de role: user) e, em produção real, um classificador dedicado revisando o input antes do processamento principal.

Switch com fallback output: como a IA é probabilística, nada garante que sempre devolva exatamente alta, media ou baixa no formato esperado. O fallback captura qualquer resposta fora do padrão em vez de deixar o lead desaparecer silenciosamente do fluxo.

Continue on Fail no HTTP Request: sem isso, uma falha na API da Groq (rate limit, timeout, chave expirada) travaria o workflow inteiro e o lead se perderia sem rastro. Com a saída de erro dedicada, a falha é registrada e pode ser reprocessada.

Suporte a dois formatos de entrada (Form e Webhook): o n8n entrega os dados de formas diferentes dependendo do trigger (campos na raiz do JSON vs. aninhados em body). O node de validação normaliza os dois formatos em um só ponto, mantendo o resto do pipeline agnóstico à origem do dado.

Limitações conhecidas
Não há validação de schema na resposta da IA: se o modelo devolver um JSON malformado, o JSON.parse falha sem tratamento específico (ficaria dentro do fluxo de erro genérico, mas sem diagnóstico direcionado).
Sem observabilidade real: o projeto registra o resultado de cada execução, mas não monitora latência, custo por execução ou taxa de erro ao longo do tempo.
Escopo de um único caso de uso — não há reuso de componentes entre múltiplos fluxos.
A defesa contra prompt injection é básica (regex), não uma solução robusta de produção.
Como rodar
Suba o n8n via Docker:
   docker run -d --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n -e GROQ_API_KEY="SUA_CHAVE_AQUI" -e N8N_BLOCK_ENV_ACCESS_IN_NODE=false docker.n8n.io/n8nio/n8n
Importe o arquivo workflow/triagem-leads-ia-n8n-groq.json no n8n.
Crie uma chave de API gratuita em console.groq.com.
Crie uma planilha Google com as colunas: Data, Nome, Email, Empresa, Mensagem, Prioridade, Categoria, Resumo, Status, e conecte via credencial OAuth do Google Sheets no node correspondente.
Conecte uma credencial OAuth do Gmail para os nodes de e-mail, e ajuste o destinatário do alerta interno.
Ative o workflow e teste via formulário ou enviando um POST para o endpoint do Webhook.
Autor

Leonardo Patro — github.com/leopatro
