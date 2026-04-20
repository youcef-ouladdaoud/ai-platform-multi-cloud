# Documentation Index

Welcome to the AI Platform Multi-Cloud documentation!

## Quick Links

### Getting Started

| Document | Description |
|----------|-------------|
| [SECRETS_QUICK_REFERENCE.md](SECRETS_QUICK_REFERENCE.md) | Quick reference for all GitHub secrets |
| [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md) | Complete step-by-step guide for configuring secrets |
| [../README.md](../README.md) | Main project documentation and quick start |

### Cloud Provider Setup

All providers require:
1. **Ollama API Key** - Get from [ollama.com](https://ollama.com)
2. **Cloud credentials** - See [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)

| Provider | Free Tier | Difficulty | Recommendation |
|----------|-----------|------------|----------------|
| [Oracle Cloud](GITHUB_SECRETS_SETUP.md#oracle-cloud-setup) | ✅ Always Free | ⭐⭐ | **Best for beginners** |
| [GCP](GITHUB_SECRETS_SETUP.md#gcp-setup) | $300 credit | ⭐ | Easiest setup |
| [AWS](GITHUB_SECRETS_SETUP.md#aws-setup) | 750 hrs/month | ⭐⭐⭐ | Enterprise features |
| [Azure](GITHUB_SECRETS_SETUP.md#azure-setup) | $200 credit | ⭐⭐⭐ | Microsoft ecosystem |

### Scripts

| Script | Purpose |
|--------|---------|
| [setup-github-secrets.sh](../scripts/setup-github-secrets.sh) | Interactive script to add GitHub secrets |

---

## Getting Started in 5 Minutes

### Option 1: Oracle Cloud (Recommended - Truly Free)

1. Get Ollama API Key: https://ollama.com/settings/api
2. Get Oracle Cloud credentials (see [guide](GITHUB_SECRETS_SETUP.md#oracle-cloud-setup))
3. Add secrets to GitHub
4. Trigger deployment from Actions tab
5. Access Open WebUI at the load balancer URL

### Option 2: Any Cloud Provider

1. **Fork this repository** (it's public!)
2. **Get Ollama API Key**: https://ollama.com/settings/api
3. **Configure GitHub Secrets**: Follow [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)
4. **Deploy**: Go to Actions → Choose workflow → Run
5. **Access**: Get the URL from workflow output

---

## Documentation Structure

```
docs/
├── README.md                      # This file
├── GITHUB_SECRETS_SETUP.md        # Complete secrets setup guide
└── SECRETS_QUICK_REFERENCE.md     # Quick reference table
```

---

## Support

- 📖 Full documentation: See individual provider guides in [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)
- 🐛 Issues: Create an issue on GitHub
- 💬 Discussions: Use GitHub Discussions

---

**Ready to start?** Head to [SECRETS_QUICK_REFERENCE.md](SECRETS_QUICK_REFERENCE.md) to get your credentials ready!
