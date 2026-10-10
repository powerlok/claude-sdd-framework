# Roteiro fixo das referências de nuvem (aws.md, azure.md, gcp.md)

Cabeçalho: `# Referência: <Nuvem>` + 2 linhas: complementa `../SKILL.md`; ler só quando a nuvem do projeto for esta.

1. Framework oficial (nome atual, pilares, ferramenta de avaliação)
2. Organização e landing zone (hierarquia, contas/subscriptions/projetos por ambiente, políticas, tags/labels)
3. Identidade e acesso (menor privilégio, identidades sem segredo, acesso privilegiado)
4. Rede (topologia, segmentação, acesso privado a serviços, saída controlada)
5. Computação — critérios de escolha (VM, containers gerenciados, Kubernetes, serverless) em tabela
6. Dados e armazenamento (bancos gerenciados, objetos: bloqueio público, criptografia, versionamento, ciclo de vida)
7. Segredos e chaves
8. Observabilidade e auditoria
9. Custo
10. Resiliência e DR (zonas/regiões, estratégias, RTO/RPO, backup)
11. Segurança e compliance (serviços nativos de postura/ameaças/WAF)
12. IaC: ferramenta nativa + Terraform/OpenTofu — tabela "só mostra prévia" vs "APLICA MUDANÇA"
13. Comandos de exemplo — SOMENTE leitura e prévia (marcados "exemplos; usar os do CLAUDE.md do projeto";
    qualquer comando que aplique/exclua NÃO aparece como exemplo executável)
14. Armadilhas comuns

Rodapé "Fontes e atribuição": URLs oficiais, licença, "consultado em 2026-10-10", "texto próprio; nenhum trecho copiado".
Limite: ≤ ~240 linhas. Usar só fatos [C] da pesquisa; [NC] omitir ou marcar "confirme na documentação atual".
