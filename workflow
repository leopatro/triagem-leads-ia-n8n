{
  "name": "Triagem de Leads com IA - n8n + Groq",
  "nodes": [
    {
      "parameters": {
        "formTitle": "Cadastro de Lead Comercial",
        "formDescription": "Preencha os dados para contato",
        "formFields": {
          "values": [
            {
              "fieldLabel": "Nome"
            },
            {
              "fieldLabel": "E-mail",
              "fieldType": "email"
            },
            {
              "fieldLabel": "Empresa"
            },
            {
              "fieldLabel": "Mensagem",
              "fieldType": "textarea"
            }
          ]
        },
        "options": {}
      },
      "type": "n8n-nodes-base.formTrigger",
      "typeVersion": 2.6,
      "position": [
        -48,
        32
      ],
      "id": "8566d7fd-70cf-43d4-91e7-ead94ab8061e",
      "name": "On form submission",
      "webhookId": "c57a5fc8-9cf1-46df-9702-fc098a5ad3d4"
    },
    {
      "parameters": {
        "method": "POST",
        "url": "https://api.groq.com/openai/v1/chat/completions",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {
              "name": "Authorization",
              "value": "=Bearer {{ $env.GROQ_API_KEY }}"
            },
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ]
        },
        "sendBody": true,
        "specifyBody": "json",
        "jsonBody": "={\n  \"model\": \"openai/gpt-oss-120b\",\n  \"messages\": [\n    {\n      \"role\": \"system\",\n      \"content\": \"Você é um assistente de qualificação de leads comerciais. Analise os dados do lead e responda APENAS em JSON válido, sem texto adicional, no formato: {\\\"prioridade\\\": \\\"alta|media|baixa\\\", \\\"categoria\\\": \\\"string curta\\\", \\\"resumo\\\": \\\"resumo de 1 frase\\\", \\\"justificativa\\\": \\\"por que essa prioridade\\\"}\"\n    },\n    {\n      \"role\": \"user\",\n      \"content\": \"Nome: {{ $json.Nome }}\\nEmail: {{ $json['E-mail'] }}\\nEmpresa: {{ $json.Empresa }}\\nMensagem: {{ $json.Mensagem }}\"\n    }\n  ],\n  \"temperature\": 0.2\n}",
        "options": {}
      },
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.5,
      "position": [
        624,
        -256
      ],
      "id": "34860668-cfa7-4d22-8ce7-959619de3a22",
      "name": "HTTP Request",
      "onError": "continueErrorOutput"
    },
    {
      "parameters": {
        "jsCode": "for (const item of $input.all()) {\n  const respostaIA = item.json.choices[0].message.content;\n  const dadosExtraidos = JSON.parse(respostaIA);\n\n  const dadosOriginais = $('Validar Mensagem').first().json;\n\n  item.json.Nome = dadosOriginais.Nome;\n  item.json['E-mail'] = dadosOriginais['E-mail'];\n  item.json.Empresa = dadosOriginais.Empresa;\n  item.json.Mensagem = dadosOriginais.Mensagem;\n\n  item.json.prioridade = dadosExtraidos.prioridade;\n  item.json.categoria = dadosExtraidos.categoria;\n  item.json.resumo = dadosExtraidos.resumo;\n  item.json.justificativa = dadosExtraidos.justificativa;\n}\n\nreturn $input.all();"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        848,
        -160
      ],
      "id": "fcb0e8b0-fede-4dcd-aafd-c2a009454246",
      "name": "Code in JavaScript"
    },
    {
      "parameters": {
        "rules": {
          "values": [
            {
              "conditions": {
                "options": {
                  "caseSensitive": true,
                  "leftValue": "",
                  "typeValidation": "strict",
                  "version": 3
                },
                "conditions": [
                  {
                    "leftValue": "={{ $json.prioridade }}",
                    "rightValue": "alta",
                    "operator": {
                      "type": "string",
                      "operation": "equals"
                    },
                    "id": "a949fa34-7e35-4419-861e-6d6f11e37c30"
                  }
                ],
                "combinator": "and"
              },
              "renameOutput": true,
              "outputKey": "alta"
            },
            {
              "conditions": {
                "options": {
                  "caseSensitive": true,
                  "leftValue": "",
                  "typeValidation": "strict",
                  "version": 3
                },
                "conditions": [
                  {
                    "id": "c47626dd-f9a7-4674-baa9-17a1c13bcdcb",
                    "leftValue": "={{ $json.prioridade }}",
                    "rightValue": "media",
                    "operator": {
                      "type": "string",
                      "operation": "equals",
                      "name": "filter.operator.equals"
                    }
                  }
                ],
                "combinator": "and"
              },
              "renameOutput": true,
              "outputKey": "media"
            },
            {
              "conditions": {
                "options": {
                  "caseSensitive": true,
                  "leftValue": "",
                  "typeValidation": "strict",
                  "version": 3
                },
                "conditions": [
                  {
                    "id": "b542b941-a81e-4d5d-833d-73e4b6e4695a",
                    "leftValue": "={{ $json.prioridade }}",
                    "rightValue": "baixa",
                    "operator": {
                      "type": "string",
                      "operation": "equals",
                      "name": "filter.operator.equals"
                    }
                  }
                ],
                "combinator": "and"
              },
              "renameOutput": true,
              "outputKey": "baixa"
            }
          ]
        },
        "options": {
          "fallbackOutput": "extra",
          "renameFallbackOutput": "erro_classificacao"
        }
      },
      "type": "n8n-nodes-base.switch",
      "typeVersion": 3.4,
      "position": [
        1072,
        -192
      ],
      "id": "c8885753-99ea-4bda-85e9-76c1dbd59255",
      "name": "Switch"
    },
    {
      "parameters": {
        "jsCode": "for (const item of $input.all()) {\n  const dados = item.json.body ? item.json.body : item.json;\n\n  item.json.Nome = dados.Nome;\n  item.json['E-mail'] = dados['E-mail'];\n  item.json.Empresa = dados.Empresa;\n  item.json.Mensagem = dados.Mensagem;\n\n  const mensagem = dados.Mensagem || \"\";\n\n  const MAX_CARACTERES = 1000;\n  const padroesSuspeitos = [\n    /ignore\\s+(as\\s+)?instru[cç][oõ]es/i,\n    /ignore\\s+previous\\s+instructions/i,\n    /system\\s*:/i,\n    /you\\s+are\\s+now/i,\n    /voc[eê]\\s+agora\\s+[eé]/i,\n    /\\bprompt\\b.*\\b(injection|override)\\b/i\n  ];\n\n  item.json.mensagem_valida = true;\n  item.json.motivo_invalidacao = null;\n\n  if (mensagem.length > MAX_CARACTERES) {\n    item.json.mensagem_valida = false;\n    item.json.motivo_invalidacao = `Mensagem excede ${MAX_CARACTERES} caracteres`;\n  }\n\n  for (const padrao of padroesSuspeitos) {\n    if (padrao.test(mensagem)) {\n      item.json.mensagem_valida = false;\n      item.json.motivo_invalidacao = \"Padrão suspeito de manipulação de prompt detectado\";\n      break;\n    }\n  }\n}\n\nreturn $input.all();"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        176,
        -64
      ],
      "id": "15f32fb0-02e0-4a6e-b5ff-1f3de4604cab",
      "name": "Validar Mensagem"
    },
    {
      "parameters": {
        "conditions": {
          "options": {
            "caseSensitive": true,
            "leftValue": "",
            "typeValidation": "strict",
            "version": 3
          },
          "conditions": [
            {
              "id": "8ddd436c-51cb-443e-a5b6-6f6d07faa30e",
              "leftValue": "={{ $json.mensagem_valida }}",
              "rightValue": true,
              "operator": {
                "type": "boolean",
                "operation": "true",
                "singleValue": true
              }
            }
          ],
          "combinator": "and"
        },
        "options": {}
      },
      "type": "n8n-nodes-base.if",
      "typeVersion": 2.3,
      "position": [
        400,
        -64
      ],
      "id": "3dd1c2de-1918-4cbf-a0c6-2863ad592118",
      "name": "If"
    },
    {
      "parameters": {
        "assignments": {
          "assignments": [
            {
              "id": "b2538719-7567-419e-82ed-bb4d405dbe9b",
              "name": "status_processamento",
              "value": "Erro na chamada da API - reprocessar",
              "type": "string"
            }
          ]
        },
        "options": {}
      },
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.5,
      "position": [
        848,
        -352
      ],
      "id": "5478b56b-e6df-43a5-bab1-15c0c2d8ce47",
      "name": "Erro API"
    },
    {
      "parameters": {
        "assignments": {
          "assignments": [
            {
              "id": "3b8a92db-299d-41b6-a1c5-2b3bddf8a0b2",
              "name": "status_processamento",
              "value": "Rejeitado - falha na validação",
              "type": "string"
            }
          ]
        },
        "options": {}
      },
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.5,
      "position": [
        624,
        128
      ],
      "id": "b5822ceb-af85-4313-85c8-ce57e9ad4b0d",
      "name": "Rejeitado Validação"
    },
    {
      "parameters": {
        "operation": "append",
        "documentId": {
          "__rl": true,
          "value": "SEU_SPREADSHEET_ID_AQUI",
          "mode": "list",
          "cachedResultName": "Leads - Triagem IA",
          "cachedResultUrl": "https://docs.google.com/spreadsheets/d/SEU_SPREADSHEET_ID_AQUI/edit?usp=drivesdk"
        },
        "sheetName": {
          "__rl": true,
          "value": "gid=0",
          "mode": "list",
          "cachedResultName": "Página1",
          "cachedResultUrl": "https://docs.google.com/spreadsheets/d/SEU_SPREADSHEET_ID_AQUI/edit#gid=0"
        },
        "columns": {
          "mappingMode": "defineBelow",
          "value": {
            "Data": "={{ $now.format('yyyy-MM-dd HH:mm') }}",
            "Nome ": "={{ $json.Nome }}",
            "Email ": "={{ $json[\"E-mail\"] }}",
            "Empresa ": "={{ $json.Empresa }}",
            "Mensagem ": "={{ $json.Mensagem }}",
            "Prioridade ": "={{ $json.prioridade }}",
            "Categoria ": "={{ $json.categoria }}",
            "Resumo ": "={{ $json.resumo }}",
            "Status": "Processado"
          },
          "matchingColumns": [],
          "schema": [
            {
              "id": "Data",
              "displayName": "Data",
              "required": false,
              "defaultMatch": false,
              "display": true,
              "type": "string",
              "canBeUsedToMatch": true
            },
            {
              "id": "Nome ",
              "displayName": "Nome ",
              "required": false,
              "defaultMatch": false,
              "display": true,
              "type": "string",
              "canBeUsedToMatch": true
            },
            {
              "id": "Email ",
              "displayName": "Email ",
              "required": false,
              "defaultMatch": false,
              "display": true,
              "type": "string",
              "canBeUsedToMatch": true
            },
            {
              "id": "Empresa ",
              "displayName": "Empresa ",
              "required": false,
              "defaultMatch": false,
              "display": true,
              "type": "string",
              "canBeUsedToMatch": true
            },
            {
              "id": "Mensagem ",
              "displayName": "Mensagem ",
              "required": false,
              "defaultMatch": false,
              "display": true,
              "type": "string",
              "canBeUsedToMatch": true
            },
            {
              "id": "Prioridade ",
              "displayName": "Prioridade ",
              "required": false,
              "defaultMatch": false,
              "display": true,
              "type": "string",
              "canBeUsedToMatch": true
            },
            {
              "id": "Categoria ",
              "displayName": "Categoria ",
              "required": false,
              "defaultMatch": false,
              "display": true,
              "type": "string",
              "canBeUsedToMatch": true
            },
            {
              "id": "Resumo ",
              "displayName": "Resumo ",
              "required": false,
              "defaultMatch": false,
              "display": true,
              "type": "string",
              "canBeUsedToMatch": true
            },
            {
              "id": "Status",
              "displayName": "Status",
              "required": false,
              "defaultMatch": false,
              "display": true,
              "type": "string",
              "canBeUsedToMatch": true
            }
          ],
          "attemptToConvertTypes": false,
          "convertFieldsToString": false
        },
        "options": {}
      },
      "type": "n8n-nodes-base.googleSheets",
      "typeVersion": 4.7,
      "position": [
        1520,
        -160
      ],
      "id": "98a6b8ab-42f8-44d7-a918-4add99e77189",
      "name": "Append row in sheet",
      "credentials": {
        "googleSheetsOAuth2Api": {
          "id": "SEU_CREDENTIAL_ID",
          "name": "Google Sheets account"
        }
      }
    },
    {
      "parameters": {
        "sendTo": "={{ $json['E-mail'] }}",
        "subject": "=Recebemos sua solicitação, {{ $json.Nome }}!",
        "message": "=<p>Olá, {{ $json.Nome }},</p>  <p>Recebemos sua solicitação e agradecemos o contato com a <strong>{{ $json.Empresa }}</strong>.</p>  <p>Um de nossos consultores entrará em contato em breve para dar continuidade ao seu atendimento.</p>  <p>Mensagem recebida:</p> <blockquote>{{ $json.Mensagem }}</blockquote>  <p>Atenciosamente,<br>Equipe Comercial</p>",
        "options": {}
      },
      "type": "n8n-nodes-base.gmail",
      "typeVersion": 2.2,
      "position": [
        624,
        -64
      ],
      "id": "8d75357b-38c3-4aa7-9938-cc93d9d0a880",
      "name": "Send a message",
      "webhookId": "525cce38-d510-4cde-92d8-a71ab53ce39f",
      "credentials": {
        "gmailOAuth2": {
          "id": "SEU_CREDENTIAL_ID",
          "name": "Gmail account"
        }
      }
    },
    {
      "parameters": {
        "sendTo": "vendedor@suaempresa.com",
        "subject": "=🔥 Lead de alta prioridade: {{ $json.Empresa }}",
        "message": "=<p><strong>Novo lead classificado como ALTA prioridade.</strong></p>  <p><strong>Nome:</strong> {{ $json.Nome }}<br> <strong>Empresa:</strong> {{ $json.Empresa }}<br> <strong>E-mail:</strong> {{ $json['E-mail'] }}</p>  <p><strong>Mensagem:</strong><br>{{ $json.Mensagem }}</p>  <p><strong>Categoria:</strong> {{ $json.categoria }}<br> <strong>Justificativa da IA:</strong> {{ $json.justificativa }}</p>  <p>Ação recomendada: contato imediato.</p>",
        "options": {}
      },
      "type": "n8n-nodes-base.gmail",
      "typeVersion": 2.2,
      "position": [
        1312,
        -304
      ],
      "id": "7653b412-534e-4a34-9130-1d583028b0cd",
      "name": "Send a message1",
      "webhookId": "807aac00-b843-4685-942f-ebd99e41e74f",
      "credentials": {
        "gmailOAuth2": {
          "id": "SEU_CREDENTIAL_ID",
          "name": "Gmail account"
        }
      }
    },
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "novo-lead",
        "options": {}
      },
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 2.1,
      "position": [
        -48,
        -160
      ],
      "id": "23a18a51-7f7c-4797-9620-20d846c99e46",
      "name": "Webhook",
      "webhookId": "7849145d-dadb-4f12-8733-42c5b49f6c5d"
    }
  ],
  "pinData": {},
  "connections": {
    "On form submission": {
      "main": [
        [
          {
            "node": "Validar Mensagem",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "HTTP Request": {
      "main": [
        [
          {
            "node": "Code in JavaScript",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Erro API",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Code in JavaScript": {
      "main": [
        [
          {
            "node": "Switch",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Validar Mensagem": {
      "main": [
        [
          {
            "node": "If",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "If": {
      "main": [
        [
          {
            "node": "Send a message",
            "type": "main",
            "index": 0
          },
          {
            "node": "HTTP Request",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Rejeitado Validação",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Switch": {
      "main": [
        [
          {
            "node": "Send a message1",
            "type": "main",
            "index": 0
          },
          {
            "node": "Append row in sheet",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Append row in sheet",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Append row in sheet",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "Append row in sheet",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Send a message": {
      "main": [
        []
      ]
    },
    "Send a message1": {
      "main": [
        [
          {
            "node": "Append row in sheet",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Webhook": {
      "main": [
        [
          {
            "node": "Validar Mensagem",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "active": false,
  "settings": {
    "executionOrder": "v1",
    "binaryMode": "separate"
  },
  "versionId": "4addc33e-d985-465a-8c9e-29a8cdb3f157",
  "meta": {
    "templateCredsSetupCompleted": true,
    "instanceId": "PLACEHOLDER_INSTANCE_ID"
  },
  "nodeGroups": [],
  "id": "2bzeb3E7Lin24nKk",
  "tags": []
}

