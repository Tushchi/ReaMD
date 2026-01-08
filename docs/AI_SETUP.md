# AI Parse Setup Guide

This guide explains how to set up and use the AI Parse feature in ReaMD.

## Overview

AI Parse uses Claude (by Anthropic) to convert unformatted text into clean, well-structured markdown. This is perfect for:

- Raw meeting notes → Organized bullet points
- Brain dumps → Proper headings and sections
- Copy-pasted scripts → Formatted production documents
- Email threads → Clean summaries

---

## Getting an API Key

### Step 1: Create Anthropic Account

1. Go to [console.anthropic.com](https://console.anthropic.com/)
2. Click **Sign Up** (or Sign In if you have an account)
3. Complete the registration process

### Step 2: Add Credits

1. Go to **Settings → Billing**
2. Add a payment method
3. Add credits (minimum $5 recommended to start)

> **Cost estimate:** AI Parse uses Claude Haiku, which costs approximately $0.25 per million input tokens. A typical parse operation costs less than $0.001 (fraction of a cent).

### Step 3: Generate API Key

1. Go to **Settings → API Keys**
2. Click **Create Key**
3. Name it something like "ReaMD"
4. Copy the key (starts with `sk-ant-...`)

> **Important:** Save this key securely. You won't be able to see it again!

---

## Configuring ReaMD

### Step 1: Open Settings

1. Launch ReaMD in REAPER
2. Click the **gear icon** (⚙) in the toolbar
3. Scroll down to **AI Parser Settings**

### Step 2: Enter API Key

1. Click in the **API Key** field
2. Paste your key (Ctrl/Cmd+V)
3. The key will be masked (shown as `********`)

> **Security note:** Your API key is stored locally in REAPER's ExtState, not in any files. It never leaves your computer except when making API calls.

### Step 3: Verify (Optional)

Click **Show** to verify the key was entered correctly, then **Hide** again.

---

## Using AI Parse

### Basic Usage

1. Click **New → AI Parse...** in the toolbar
2. Paste your unformatted text in the text area
3. Click **Parse with AI**
4. Wait for processing (typically 2-5 seconds)
5. Review the result
6. Click **Save As...** to save the formatted markdown

### Example

**Input (unformatted):**
```
meeting notes jan 8
discussed the new intro sequence john wants more dramatic music sarah will do vo next week need to finalize by friday
action items get music stems from composer review vo script with client schedule mix session
budget update were at 80% with 3 weeks left should be fine
```

**Output (AI formatted):**
```markdown
# Meeting Notes - January 8

## Discussion Points

- **Intro Sequence**: John wants more dramatic music
- **Voiceover**: Sarah will record VO next week
- **Deadline**: Need to finalize by Friday

## Action Items

1. Get music stems from composer
2. Review VO script with client
3. Schedule mix session

## Budget Update

Currently at 80% with 3 weeks remaining. On track.
```

---

## Customizing the Prompt

The AI behavior is controlled by a prompt template that you can customize.

### Editing the Prompt

1. In Settings, click **Edit Prompt**
2. Your system editor will open `prompts/ai_format_prompt.txt`
3. Modify the instructions
4. Save and close

### Prompt Template Structure

```
[Role/Context]
You are a markdown formatting assistant...

[Task Description]
Convert the following unformatted text...

[Guidelines]
- Use heading levels appropriately
- Use bullet lists for items
- etc.

[Output Format]
Output ONLY the formatted markdown. Do not include explanations.
```

### Example Customizations

**For Voiceover Scripts:**
```
You are formatting voiceover scripts for audio production.

Guidelines:
- Use ## for scene headers
- Use > blockquotes for VO lines
- Use [brackets] for sound effects cues
- Preserve all timecodes exactly
- Mark talent directions in *italics*
```

**For Technical Documentation:**
```
You are formatting technical documentation.

Guidelines:
- Use proper code blocks with language tags
- Create tables for specifications
- Use numbered lists for procedures
- Add appropriate header hierarchy
```

---

## Troubleshooting

### "API key not set"

- Open Settings and verify your API key is entered
- Make sure there are no extra spaces

### "Request failed" or timeout

- Check your internet connection
- Verify your API key is valid at [console.anthropic.com](https://console.anthropic.com/)
- Check if you have credits remaining

### Empty or unexpected results

- Try a different/simpler input text
- Check your custom prompt for errors
- Reset to default prompt by deleting `prompts/ai_format_prompt.txt` (will regenerate on next use)

### Windows-specific issues

- Ensure `curl.exe` is available (Windows 10 build 17063+)
- Try running `curl --version` in Command Prompt
- For older Windows, install curl from [curl.se](https://curl.se/windows/)

---

## API Usage & Costs

### Model

ReaMD uses **Claude Haiku** (`claude-haiku-4-5-20251001`), optimized for:
- Fast response times (2-5 seconds)
- Low cost
- Good quality for formatting tasks

### Pricing (as of 2026)

| Model | Input | Output |
|-------|-------|--------|
| Claude Haiku | $0.25/M tokens | $1.25/M tokens |

**Typical usage:**
- Small text (< 500 words): ~$0.0002
- Medium text (500-2000 words): ~$0.001
- Large text (2000+ words): ~$0.003

### Monitoring Usage

Check your usage at [console.anthropic.com/settings/usage](https://console.anthropic.com/settings/usage)

---

## Privacy & Security

### Data Handling

- Your text is sent to Anthropic's API for processing
- Anthropic's [privacy policy](https://www.anthropic.com/privacy) applies
- No data is stored locally except the formatted result

### API Key Storage

- Stored in REAPER's ExtState (local registry/plist)
- Not written to any files
- Not included in git/version control

### Best Practices

1. Don't process confidential/sensitive information
2. Regenerate your API key if compromised
3. Monitor your usage for unexpected activity
