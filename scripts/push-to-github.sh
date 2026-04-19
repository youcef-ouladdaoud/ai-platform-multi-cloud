#!/bin/bash
# Push AI Platform Multi-Cloud to GitHub

set -e

echo "🚀 AI Platform Multi-Cloud - GitHub Setup"
echo "=========================================="

# Check if already has remote
if git remote -v > /dev/null 2>&1 && [ -n "$(git remote -v)" ]; then
    echo "⚠️  Remote already configured:"
    git remote -v
    echo ""
    read -p "Do you want to push to existing remote? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📤 Pushing to existing remote..."
        git push -u origin master
        echo "✅ Code pushed successfully!"
        exit 0
    fi
fi

echo ""
echo "Please enter your GitHub repository URL:"
echo "(e.g., https://github.com/username/ai-platform-multi-cloud.git)"
read -p "GitHub URL: " GITHUB_URL

if [ -z "$GITHUB_URL" ]; then
    echo "❌ No URL provided. Exiting."
    exit 1
fi

# Add remote
echo "🔗 Adding remote origin..."
git remote add origin "$GITHUB_URL"

# Push to GitHub
echo "📤 Pushing code to GitHub..."
git push -u origin master

echo ""
echo "✅ Success! Code pushed to: $GITHUB_URL"
echo ""
echo "Next steps:"
echo "1. Visit your repository: $GITHUB_URL"
echo "2. Add GitHub Secrets for CI/CD:"
echo "   - Settings → Secrets and variables → Actions"
echo "3. Required secrets:"
echo "   - OLLAMA_API_KEY"
echo "   - OPENCLAW_API_KEY"
echo "   - Cloud provider credentials (AWS, GCP, Azure, or Oracle)"
echo ""
echo "🎉 Happy deploying!"
