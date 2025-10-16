# GFWL Quantum Fixer  Proof of Concept

Projeto proof of concept: NO-CD SecuRom hook + stubs otimizados de `Xlive.dll`.

## Resumo

Este repositório contém um proof of concept (PoC) que implementa um hook para bypass/imitação de verificações NO-CD feitas pelo SecuRom, juntamente com implementações (stubs) otimizadas da biblioteca `Xlive.dll` usadas por jogos que dependem do Games for Windows Live (GFWL).

A ideia original deste projeto é sua utilização em jogos protegidos por SecuROM, como 007 Quantum (007: Quantum of Solace) e BioShock 2; os exemplos e testes foram pensados tendo esses títulos em mente.

O objetivo é pesquisa e compatibilidade para fins legítimos de desenvolvimento, manutenção de software legado e testes. Não é um produto final  trata-se de código experimental destinado a estudos técnicos.

## Funcionalidades

- Hook PoC para verificações NO-CD (SecuRom)  demonstração técnica.
- Stubs otimizados de `Xlive.dll` para fornecer chamadas mínimas necessárias por alguns jogos.


## Como usar (exemplo básico)

- Copie o DLL gerado (proxy/xlive stub) para a pasta do jogo que requer `Xlive.dll`.
- Renomeie/substitua o DLL do xlivelessness para `Xlive_real.dll` (ou a `xlive.dll` original) conforme necessário. Faça backup do original antes de substituir.

## Aviso legal e propósito

Este projeto é estritamente um proof of concept para pesquisa técnica e manutenção de software legado. Ele não deve ser usado para contornar licenças, protecoes anti-cópia com fins ilícitos ou para distribuir software protegido por direitos autorais sem autorização.

O autor e os colaboradores não se responsabilizam por usos indevidos. Use por sua conta e risco.

## Contribuições

Contribuições são bem-vindas dentro do escopo de pesquisa e correções técnicas. Abra issues ou pull requests no repositório.
