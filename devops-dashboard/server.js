const express = require('express');
const path = require('path');
const k8s = require('@kubernetes/client-node');

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Kubernetes configuration
const kc = new k8s.KubeConfig();
try {
  kc.loadFromCluster();
} catch (e) {
  try {
    kc.loadFromDefault();
  } catch (err) {
    console.warn('Kubernetes config load warning: No in-cluster or default kubeconfig found.', err.message);
  }
}

const k8sCoreApi = kc.makeApiClient(k8s.CoreV1Api);
const k8sAppsApi = kc.makeApiClient(k8s.AppsV1Api);

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Define services to track
const SERVICES_METADATA = [
  {
    id: 'jenkins',
    name: 'Jenkins',
    namespace: 'jenkins',
    serviceName: 'jenkins',
    kind: 'StatefulSet',
    workloadName: 'jenkins',
    url: 'http://jenkins.tpinf.xyz',
    description: 'CI/CD Jenkins automation server for orchestration.'
  },
  {
    id: 'argocd',
    name: 'Argo CD',
    namespace: 'argocd',
    serviceName: 'argocd-server',
    kind: 'Deployment',
    workloadName: 'argocd-server',
    url: 'http://argocd.tpinf.xyz',
    description: 'Declarative GitOps continuous delivery tool for Kubernetes.'
  },
  {
    id: 'harbor',
    name: 'Harbor Registry',
    namespace: 'harbor',
    serviceName: 'my-harbor-portal',
    kind: 'Deployment',
    workloadName: 'my-harbor-portal',
    url: 'http://harbor.tpinf.xyz',
    description: 'Secure open source container registry and vulnerability scanner.'
  },
  {
    id: 'defectdojo',
    name: 'DefectDojo',
    namespace: 'defectdojo',
    serviceName: 'defectdojo-django',
    kind: 'Deployment',
    workloadName: 'defectdojo-django',
    url: 'http://defectdojo.tpinf.xyz',
    description: 'Vulnerability management tool to coordinate security findings.'
  },
  {
    id: 'uptime-kuma',
    name: 'Uptime Kuma',
    namespace: 'monitoring',
    serviceName: 'uptime-kuma',
    kind: 'Deployment',
    workloadName: 'uptime-kuma',
    url: 'http://uptime-kuma.tpinf.xyz',
    description: 'Self-hosted monitoring tool for service uptime checking.'
  },
  {
    id: 'kong-gateway',
    name: 'Kong API Gateway',
    namespace: 'kong',
    serviceName: 'kong-kong-proxy',
    kind: 'Deployment',
    workloadName: 'kong-kong',
    url: 'http://api.tpinf.xyz',
    description: 'Cloud-native API gateway and Kubernetes ingress controller.'
  },
  {
    id: 'litellm',
    name: 'LiteLLM Proxy',
    namespace: 'litellm',
    serviceName: 'litellm',
    kind: 'Deployment',
    workloadName: 'litellm',
    url: 'http://litellm.tpinf.xyz',
    description: 'Proxy and router for OpenAI, Anthropic, and local LLMs.'
  },
  {
    id: 'kubernetes-mcp',
    name: 'Kube MCP Server',
    namespace: 'kubernetes-mcp-server',
    serviceName: 'kubernetes-mcp-server',
    kind: 'Deployment',
    workloadName: 'kubernetes-mcp-server',
    url: 'http://mcp-kube.tpinf.xyz',
    description: 'Model Context Protocol server for secure cluster integrations.'
  },
  {
    id: 'nginx-sit',
    name: 'Nginx (SIT)',
    namespace: 'nginx-sit',
    serviceName: 'nginx-sit',
    kind: 'Deployment',
    workloadName: 'nginx-sit',
    url: 'http://nginx-sit.nginx-sit.svc.cluster.local',
    description: 'System Integration Testing environment server.'
  },
  {
    id: 'nginx-uat',
    name: 'Nginx (UAT)',
    namespace: 'nginx-uat',
    serviceName: 'nginx-uat',
    kind: 'Deployment',
    workloadName: 'nginx-uat',
    url: 'http://nginx-uat.nginx-uat.svc.cluster.local',
    description: 'User Acceptance Testing environment server.'
  },
  {
    id: 'postgres',
    name: 'PostgreSQL',
    namespace: 'postgres',
    serviceName: 'postgres-postgresql',
    kind: 'StatefulSet',
    workloadName: 'postgres-postgresql',
    url: 'http://postgres-postgresql.postgres.svc.cluster.local:5432',
    description: 'Relational database service powering platform components.'
  },
  {
    id: 'echo-service',
    name: 'Echo App',
    namespace: 'demo',
    serviceName: 'echo',
    kind: 'Deployment',
    workloadName: 'echo',
    url: 'http://echo.demo.svc.cluster.local',
    description: 'Simple microservice that echoes HTTP requests back as JSON.'
  },
  {
    id: 'httpbin-service',
    name: 'Httpbin App',
    namespace: 'demo',
    serviceName: 'httpbin',
    kind: 'Deployment',
    workloadName: 'httpbin',
    url: 'http://httpbin.demo.svc.cluster.local',
    description: 'HTTP request & response service for testing REST calls.'
  }
];

// Helper to check workload status
async function getWorkloadStatus(namespace, kind, name) {
  try {
    if (kind === 'Deployment') {
      const res = await k8sAppsApi.readNamespacedDeployment(name, namespace);
      const status = res.body.status || {};
      const replicas = status.replicas || 0;
      const readyReplicas = status.readyReplicas || 0;
      const health = replicas > 0 && readyReplicas === replicas ? 'Healthy' : (readyReplicas > 0 ? 'Degraded' : 'Offline');
      return { status: health, replicas, readyReplicas };
    } else if (kind === 'StatefulSet') {
      const res = await k8sAppsApi.readNamespacedStatefulSet(name, namespace);
      const status = res.body.status || {};
      const replicas = status.replicas || 0;
      const readyReplicas = status.readyReplicas || 0;
      const health = replicas > 0 && readyReplicas === replicas ? 'Healthy' : (readyReplicas > 0 ? 'Degraded' : 'Offline');
      return { status: health, replicas, readyReplicas };
    }
  } catch (err) {
    // If the namespace/workload doesn't exist or permissions fail, mark offline
    return { status: 'Offline', replicas: 0, readyReplicas: 0, error: err.message };
  }
  return { status: 'Offline', replicas: 0, readyReplicas: 0 };
}

// 1. Get cluster health overview
app.get('/api/cluster/status', async (req, res) => {
  try {
    const nodes = await k8sCoreApi.listNode();
    const pods = await k8sCoreApi.listPodForAllNamespaces();
    const namespaces = await k8sCoreApi.listNamespace();

    const healthyNodes = nodes.body.items.filter(node => 
      node.status.conditions.some(c => c.type === 'Ready' && c.status === 'True')
    ).length;

    const podStates = pods.body.items.reduce((acc, pod) => {
      const phase = pod.status.phase;
      acc[phase] = (acc[phase] || 0) + 1;
      return acc;
    }, {});

    res.json({
      success: true,
      nodes: {
        total: nodes.body.items.length,
        healthy: healthyNodes
      },
      pods: {
        total: pods.body.items.length,
        running: podStates['Running'] || 0,
        pending: podStates['Pending'] || 0,
        failed: podStates['Failed'] || 0,
        succeeded: podStates['Succeeded'] || 0,
      },
      namespaces: namespaces.body.items.length
    });
  } catch (err) {
    console.error('Cluster status fetch error:', err.message);
    // Provide fallback mock/empty response if API server not accessible (e.g. running locally without kube context)
    res.json({
      success: false,
      error: err.message,
      nodes: { total: 1, healthy: 1 },
      pods: { total: 0, running: 0, pending: 0, failed: 0, succeeded: 0 },
      namespaces: 0
    });
  }
});

// 2. Get list of all services with statuses
app.get('/api/services', async (req, res) => {
  const results = [];
  for (const service of SERVICES_METADATA) {
    const statusInfo = await getWorkloadStatus(service.namespace, service.kind, service.workloadName);
    results.push({
      ...service,
      status: statusInfo.status,
      replicas: statusInfo.replicas,
      readyReplicas: statusInfo.readyReplicas
    });
  }
  res.json({ success: true, services: results });
});

// 3. Get pods for a specific service
app.get('/api/services/:namespace/:serviceName/pods', async (req, res) => {
  const { namespace, serviceName } = req.params;
  try {
    const svcRes = await k8sCoreApi.readNamespacedService(serviceName, namespace);
    const selector = svcRes.body.spec.selector;
    if (!selector) {
      return res.status(404).json({ success: false, message: 'Service selector not found' });
    }

    const labelSelector = Object.entries(selector).map(([k, v]) => `${k}=${v}`).join(',');
    const podList = await k8sCoreApi.listNamespacedPod(namespace, undefined, undefined, undefined, undefined, labelSelector);
    
    const pods = podList.body.items.map(pod => {
      const restartCount = pod.status.containerStatuses 
        ? pod.status.containerStatuses.reduce((sum, c) => sum + c.restartCount, 0)
        : 0;

      const containerStates = pod.status.containerStatuses
        ? pod.status.containerStatuses.map(c => ({
            name: c.name,
            ready: c.ready,
            state: Object.keys(c.state)[0] || 'Unknown'
          }))
        : [];

      return {
        name: pod.metadata.name,
        phase: pod.status.phase,
        ip: pod.status.podIP || 'N/A',
        node: pod.spec.nodeName || 'N/A',
        restarts: restartCount,
        age: pod.metadata.creationTimestamp,
        containers: containerStates
      };
    });

    res.json({ success: true, pods });
  } catch (err) {
    console.error(`Failed to list pods for service ${serviceName} in ${namespace}:`, err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// 4. Fetch pod logs
app.get('/api/pods/:namespace/:podName/logs', async (req, res) => {
  const { namespace, podName } = req.params;
  try {
    const logRes = await k8sCoreApi.readNamespacedPodLog(
      podName,
      namespace,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      100 // return last 100 lines
    );
    res.json({ success: true, logs: logRes.body });
  } catch (err) {
    console.error(`Failed to fetch logs for pod ${podName} in ${namespace}:`, err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// 5. Restart pod (by deleting it)
app.delete('/api/pods/:namespace/:podName/restart', async (req, res) => {
  const { namespace, podName } = req.params;
  try {
    await k8sCoreApi.deleteNamespacedPod(podName, namespace);
    res.json({ success: true, message: `Pod ${podName} in namespace ${namespace} has been deleted to trigger a restart.` });
  } catch (err) {
    console.error(`Failed to delete/restart pod ${podName} in ${namespace}:`, err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`DevOps Dashboard backend listening on port ${PORT}`);
});
