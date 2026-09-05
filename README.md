# MacGlue

Um histórico de área de transferência nativo para macOS, feito com Swift e SwiftUI. O MacGlue guarda textos e imagens localmente e permite reutilizar qualquer item com rapidez, sem enviar seus dados para a nuvem.

## Recursos

- Histórico local de textos e imagens.
- Miniaturas para identificar imagens rapidamente.
- Busca no histórico.
- Clique em um item para copiá-lo e colá-lo automaticamente no app que estava ativo.
- Fixação e exclusão individual de itens.
- Atalho global `⌘⇧V` para mostrar ou ocultar o histórico.
- Control-clique no cabeçalho do histórico para desativar ou reativar a captura.
- Janela nativa, menu da barra e animação de abertura.
- Solicitação de permissão de Acessibilidade na primeira abertura.
- Compatível com macOS 13 ou superior.

## Download

Baixe o arquivo **MacGlue.dmg** na página de [Releases](../../releases), abra-o e arraste o MacGlue para a pasta Applications.

Como o aplicativo é open source e ainda não é notarizado pela Apple, o macOS pode mostrar um aviso na primeira abertura. Nesse caso, clique com o botão direito no app, selecione **Abrir** e confirme.

## Primeira execução

Ao abrir o MacGlue pela primeira vez, o macOS solicitará acesso de Acessibilidade. Essa permissão é necessária para que o app possa devolver o `⌘V` ao aplicativo que estava ativo antes do histórico.

Se o pedido não aparecer, abra:

**Ajustes do Sistema > Privacidade e Segurança > Acessibilidade**

Ative o MacGlue e reinicie o app. O funcionamento do histórico local não depende dessa permissão; apenas a colagem automática precisa dela.

## Como usar

1. Abra o MacGlue. A janela do histórico aparece na tela.
2. Copie textos ou imagens normalmente; eles serão adicionados automaticamente.
3. Pressione `⌘⇧V` para mostrar ou ocultar o histórico.
4. Clique em um item para colá-lo no aplicativo que estava ativo anteriormente.
5. Use a lixeira para excluir um item ou o menu de contexto para fixá-lo.
6. Faça `⌃`-clique no cabeçalho “MacGlue” para pausar ou reativar o app. Enquanto desativado, novas cópias não são registradas e o atalho global fica pausado.

## Desenvolvimento

### Requisitos

- macOS 13 ou superior.
- Xcode 15 ou superior.
- Swift 6.

### Executar no Xcode

Abra `MacGlue.xcodeproj`, selecione o scheme **MacGlue**, escolha **My Mac** e pressione `⌘R`.

### Executar pelo terminal

```bash
swift run MacGlue
```

### Gerar um build

```bash
xcodebuild -project MacGlue.xcodeproj \
  -scheme MacGlue \
  -configuration Release \
  -sdk macosx \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Privacidade

O histórico é armazenado localmente em:

```text
~/Library/Application Support/MacGlue/clipboard-history.json
```

O projeto não possui servidor nem sincronização em nuvem. Evite copiar senhas, tokens ou outras informações sensíveis, ou remova esses itens do histórico após utilizá-los.

## Contribuindo

Issues e pull requests são bem-vindos. Antes de enviar uma alteração, compile o projeto e descreva o comportamento testado.

## Licença

Este projeto é distribuído sob a licença MIT. Consulte [LICENSE](LICENSE).
