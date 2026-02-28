# n8n Webhook Advanced Skill

Production-hardened webhook security and reliability guide.

## What This Skill Teaches

- 🔐 Webhook authentication and signature verification
- ✅ Request validation and sanitization
- 🛡️ Security hardening and attack prevention
- 📊 Rate limiting and quotas
- 🔄 Reliability patterns and retry handling
- 🐛 Webhook debugging and testing

## When This Skill Activates

- "How to secure webhooks?"
- "Webhook signature verification"
- "Rate limiting webhooks"
- "Idempotency in webhooks"
- "Webhook validation"
- "Debug webhook issues"
- "Webhook security best practices"

## Key Security Patterns

- **HMAC Signature Verification** - Authenticate webhook source
- **Bearer Token / API Key** - Additional authentication
- **Payload Validation** - Check format and types
- **Rate Limiting** - Token bucket algorithm
- **Size Limits** - Prevent abuse

## Reliability Patterns

- **Idempotency Keys** - Handle duplicate deliveries
- **Async Processing** - Return 200 immediately
- **Deduplication** - Prevent duplicate work
- **Dead Letter Queue** - Handle failures
- **Replay Capability** - Debug and resend

## Security Checklist

✅ Verify signatures
✅ Validate input schema
✅ Rate limit requests
✅ Size limit payloads
✅ Log everything (sanitized)
✅ Handle errors safely
✅ Use HTTPS only
✅ Implement idempotency
✅ Monitor health

## Integration

- **n8n Advanced Patterns** - Error handling, retries
- **n8n Workflow Debugging** - Debug webhook issues
- **n8n Code JavaScript** - Validation logic

---

**Start with [SKILL.md](SKILL.md) for production-ready webhooks!**
