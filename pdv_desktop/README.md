# PDV Desktop - I9 Smart

Aplicação desktop para PDV de Postos de Combustíveis usando Tauri. Funciona como um wrapper nativo que carrega a aplicação web em um WebView, sem barra de navegação ou menus.

## Requisitos

### Desenvolvimento

- **Node.js** 18+
- **Rust** 1.70+ (https://rustup.rs)
- **Tauri CLI** (instalado automaticamente via npm)

### Por Sistema Operacional

#### Windows
- Microsoft Visual Studio C++ Build Tools
- WebView2 (geralmente já instalado no Windows 10/11)

#### macOS
- Xcode Command Line Tools
```bash
xcode-select --install
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install libwebkit2gtk-4.0-dev build-essential curl wget file libssl-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev
```

## Instalação

```bash
# Entrar na pasta do projeto
cd pdv_desktop

# Instalar dependências Node
npm install

# Verificar se Rust está instalado
rustc --version

# Se não estiver, instalar Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Configuração

### URL do Sistema

Edite o arquivo `config.json` na raiz da pasta `pdv_desktop`:

```json
{
  "url": "https://seu-dominio.com"
}
```

**IMPORTANTE**: Após alterar o `config.json`, copie-o também para `dist/config.json`:

```bash
cp config.json dist/config.json
```

### Modo Kiosk

Para ativar o modo kiosk (tela travada, ideal para PDV fixo), edite `src-tauri/tauri.conf.json`:

```json
{
  "tauri": {
    "kiosk": true
  }
}
```

Quando `kiosk: true`:
- A janela fica em tela cheia permanente
- Não é possível minimizar ou fechar via atalhos
- Ideal para terminais dedicados de PDV

## Desenvolvimento

```bash
# Iniciar em modo desenvolvimento (hot reload)
npm run dev
```

O app será aberto automaticamente. Alterações no HTML/JS serão refletidas imediatamente.

## Build de Produção

### Build para o Sistema Atual

```bash
npm run build
```

### Build para Plataformas Específicas

```bash
# Windows (.exe + .msi)
npm run build:windows

# macOS (.dmg + .app)
npm run build:macos

# macOS ARM (M1/M2)
npm run build:macos-arm

# Linux (.AppImage + .deb)
npm run build:linux
```

### Localização dos Instaladores

Após o build, os instaladores estarão em:

```
src-tauri/target/release/bundle/
├── dmg/                    # macOS
│   └── PDV Desktop_1.0.0_x64.dmg
├── macos/                  # macOS .app
│   └── PDV Desktop.app
├── msi/                    # Windows MSI
│   └── PDV Desktop_1.0.0_x64_en-US.msi
├── nsis/                   # Windows NSIS
│   └── PDV Desktop_1.0.0_x64-setup.exe
├── deb/                    # Debian/Ubuntu
│   └── pdv-desktop_1.0.0_amd64.deb
└── appimage/               # Linux AppImage
    └── pdv-desktop_1.0.0_amd64.AppImage
```

## Cross-Compilation (Build Cruzado)

Para gerar builds de outros sistemas operacionais, você precisa de:

### Windows para Linux
Não recomendado. Use uma VM Linux ou GitHub Actions.

### macOS para Windows
Não é possível nativamente. Use uma VM Windows ou GitHub Actions.

### GitHub Actions (Recomendado)

Crie `.github/workflows/build.yml` para builds automáticos em todas as plataformas.

## Assinatura de Código

### Windows

1. Obtenha um certificado de assinatura de código (ex: DigiCert, Sectigo)
2. Edite `src-tauri/tauri.conf.json`:

```json
{
  "tauri": {
    "bundle": {
      "windows": {
        "certificateThumbprint": "SEU_THUMBPRINT_AQUI",
        "timestampUrl": "http://timestamp.digicert.com"
      }
    }
  }
}
```

3. Execute o build normalmente

### macOS

1. Tenha uma conta Apple Developer ($99/ano)
2. Crie certificados no Apple Developer Portal
3. Edite `src-tauri/tauri.conf.json`:

```json
{
  "tauri": {
    "bundle": {
      "macOS": {
        "signingIdentity": "Developer ID Application: Sua Empresa (XXXXXXXXXX)"
      }
    }
  }
}
```

4. Para notarização (obrigatório para distribuição):

```bash
xcrun notarytool submit "PDV Desktop.dmg" --apple-id "seu@email.com" --team-id "XXXXXXXXXX" --password "app-specific-password"
```

## Ícones

Para gerar ícones em todos os formatos necessários:

1. Crie um ícone PNG de 1024x1024 pixels
2. Salve como `pdv_desktop/icons/app-icon.png`
3. Execute:

```bash
npm run icons
```

Os ícones serão gerados automaticamente em `src-tauri/icons/`.

## Estrutura do Projeto

```
pdv_desktop/
├── config.json              # URL do sistema (editável)
├── package.json             # Dependências Node
├── README.md                # Esta documentação
├── dist/                    # Frontend (arquivos estáticos)
│   ├── index.html           # Página de loading/redirect
│   └── config.json          # Cópia do config.json
├── icons/                   # Ícone fonte
│   └── app-icon.png         # Ícone 1024x1024 (criar)
└── src-tauri/               # Código Rust/Tauri
    ├── tauri.conf.json      # Configuração do Tauri
    ├── Cargo.toml           # Dependências Rust
    ├── build.rs             # Script de build
    ├── src/
    │   └── main.rs          # Entry point Rust
    └── icons/               # Ícones gerados
        ├── 32x32.png
        ├── 128x128.png
        ├── 128x128@2x.png
        ├── icon.icns        # macOS
        └── icon.ico         # Windows
```

## Troubleshooting

### Erro: "Failed to load WebView2"
Instale o WebView2 Runtime: https://developer.microsoft.com/microsoft-edge/webview2/

### Erro: "webkit2gtk not found"
```bash
sudo apt install libwebkit2gtk-4.0-dev
```

### Erro: "SSL certificate problem"
Verifique se a URL no config.json usa HTTPS válido em produção.

### App não carrega a URL
1. Verifique se `dist/config.json` existe e tem a URL correta
2. Verifique se o servidor web está rodando
3. Abra o DevTools (F12 no modo dev) para ver erros

## Suporte

Para problemas ou sugestões:
- Documentação Tauri: https://tauri.app/v1/guides/
- Issues do projeto: [seu-repositorio]/issues

---

**Versão**: 1.0.0
**Última atualização**: Dezembro 2024
**Desenvolvido por**: I9 Smart
