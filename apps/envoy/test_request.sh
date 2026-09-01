curl -H "Content-Type: application/json" \
  -d '{
        "model": "some-cool-self-hosted-model",
        "messages": [
            {
                "role": "system",
                "content": "Hi."
            }
        ]
    }' \
  $GATEWAY_URL/v1/chat/completions

  