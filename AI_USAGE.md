# AI Usage

| task | tool | what you accepted as-is | what you changed and why |
|------|------|-------------------------|--------------------------|
| Generating initial Kubernetes manifest templates | ChatGPT | General structure of Deployment and Service YAML | Changed labels, namespace, and probe paths to match the exact requirements of Part D |
| Understanding StatefulSet for PostgreSQL | ChatGPT | Explanation of how PVCs work with StatefulSets | N/A |
| Troubleshooting Docker Compose network | ChatGPT | Concept of reaching services by name | Fixed the actual `docker-compose.yml` to use `depends_on` with `service_healthy` correctly |
| Writing project documentation (README) | ChatGPT | Overall structure and markdown formatting | Replaced generic placeholders with actual project tool versions and design decisions |

### AI limitations noticed

The AI was initially misleading when it suggested using a standard `Deployment` for PostgreSQL instead of a `StatefulSet`. It generated a `Deployment` manifest which I realized lacked stable network identity and ordered storage provisioning, which are crucial for a database. I noticed this when cross-referencing Kubernetes documentation for deploying stateful applications, prompting me to rewrite it as a `StatefulSet` with a `volumeClaimTemplate`.
