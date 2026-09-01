export GATEWAY_URL=$(kubectl get gateway/envoy-ai-gateway-basic -o jsonpath='{.status.addresses[0].value}')

curl -H "Content-Type: application/json" \
  -d '{
        "model": "qwen/qwen3.8-27b",
        "messages": [
            {
                "role": "user",
                "content": "Hello!"
            }
        ]
    }' \
  $GATEWAY_URL/v1/chat/completions
