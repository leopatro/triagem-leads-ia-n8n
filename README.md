Triagem de Leads Comerciais com IA

Automação que recebe leads comerciais, usa um LLM para classificar prioridade e categoria, valida as mensagens contra tentativas de manipulação de prompt, notifica o time comercial e registra tudo de forma estruturada numa planilha.

Não é um projeto tecnicamente complexo. É um fluxo simples de automação com IA, construído com o cuidado que normalmente só se vê em sistemas pensados para produção: validação de entrada, resiliência a falhas e rastreabilidade. A maioria das automações que vejo por aí não tem nem isso.

O problema

Times comerciais recebem leads por vários canais — formulário do site, WhatsApp, planilha manual — sem nenhuma padronização de triagem. Na prática, isso significa que um lead urgente pode ficar esperando o mesmo tempo que um lead só curioso, e ninguém tem um registro confiável de volume, origem ou tempo de resposta.

Como funciona

O lead entra pelo formulário (pensado para demonstração visual) ou por um webhook, para quem quiser integrar via API. Os dois caminhos convergem no mesmo pipeline.

Antes de qualquer coisa, a mensagem passa por uma validação: ela checa o tamanho do texto e procura por padrões conhecidos de tentativa de manipular o prompt da IA — afinal, é um campo de texto livre vindo de um formulário público, e isso é exatamente o tipo de entrada que merece desconfiança.

Se a mensagem é válida, duas coisas acontecem em paralelo: o lead recebe um e-mail de confirmação na hora, e os dados seguem para a IA (rodando na Groq, modelo openai/gpt-oss-120b), que analisa o conteúdo e devolve uma prioridade (alta, média ou baixa), uma categoria, um resumo e a justificativa da decisão.

A partir daí, o lead é roteado conforme a prioridade. Todo lead processado vai para uma planilha, com todos os campos e o status de cada etapa. Quando a prioridade é alta, além do registro, dispara um e-mail de alerta para o time comercial — incluindo a justificativa que a IA deu, para que quem recebe o alerta entenda o motivo da urgência, não só o resultado.

Se a chamada à IA falhar por qualquer motivo (limite de requisições, timeout, chave expirada), o lead não se perde: ele cai numa rota de erro separada, registrada para reprocessamento depois, em vez de travar o fluxo inteiro.

Tecnologias

n8n rodando via Docker, Groq API para a classificação via LLM, JavaScript nos nodes de código para parsing e validação, Google Sheets para o registro e Gmail para as notificações.

Algumas decisões que valem explicar

Optei por usar um node de HTTP Request genérico para chamar a IA, em vez de uma integração pronta — queria entender e mostrar como uma chamada de API de LLM funciona por baixo dos panos (estrutura de mensagens, roles, temperatura), não só consumir algo já abstraído.

A validação contra manipulação de prompt é só uma primeira camada, não uma solução definitiva — isso é importante deixar claro. Ela pega tentativas óbvias, mas defesa de verdade também depende de manter o system prompt isolado do input do usuário (o que já faço aqui) e, num cenário de produção real, provavelmente envolveria um segundo modelo revisando as entradas antes do processamento principal.

O roteamento por prioridade tem uma quarta saída, além de alta/média/baixa, para qualquer resposta da IA que fuja do padrão esperado — porque modelo de linguagem é probabilístico, e nada garante que ele sempre devolva exatamente o que você pediu no formato que você pediu.

Também reparei, construindo isso, que o formulário e o webhook entregam os dados em formatos diferentes (um na raiz do JSON, outro aninhado dentro de body). A normalização desses dois formatos acontece num único ponto do fluxo, para que o resto do pipeline não precise se preocupar com a origem do dado.

O que ainda falta

Não tem validação de schema na resposta da IA — se o modelo devolver um JSON malformado, o parse simplesmente falha, sem um tratamento específico para esse caso. Também não tem observabilidade de verdade: o projeto registra o resultado de cada lead, mas não acompanha latência, custo por execução ou taxa de erro ao longo do tempo. E é, no fim das contas, um único caso de uso — não há reuso de componentes entre fluxos diferentes.

Para rodar

Suba o n8n via Docker:

docker run -d --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n -e GROQ_API_KEY="SUA_CHAVE_AQUI" -e N8N_BLOCK_ENV_ACCESS_IN_NODE=false docker.n8n.io/n8nio/n8n

Importe o arquivo triagem-leads-ia-n8n-groq.json no n8n, crie uma chave gratuita em console.groq.com, configure uma planilha Google com as colunas Data, Nome, Email, Empresa, Mensagem, Prioridade, Categoria, Resumo e Status, e conecte suas próprias credenciais do Google Sheets e Gmail nos nodes correspondentes.

Autor

Leonardo Patro — github.com/leopatro
