import express from 'express';
import cors from 'cors';
import { RobloxStudioTools } from './tools/index.js';
import { BridgeService } from './bridge-service.js';

export function createHttpServer(tools: RobloxStudioTools, bridge: BridgeService) {
  const app = express();
  let pluginConnected = false;
  let mcpServerActive = false;
  let lastMCPActivity = 0;
  let mcpServerStartTime = 0;
  let lastPluginActivity = 0;

  // Track MCP server lifecycle
  const setMCPServerActive = (active: boolean) => {
    mcpServerActive = active;
    if (active) {
      mcpServerStartTime = Date.now();
      lastMCPActivity = Date.now();
    } else {
      mcpServerStartTime = 0;
      lastMCPActivity = 0;
    }
  };

  const trackMCPActivity = () => {
    if (mcpServerActive) {
      lastMCPActivity = Date.now();
    }
  };

  const isMCPServerActive = () => {
    // Removed timeout - once MCP connects, stay connected
    // Original had 15 second timeout which caused disconnects
    return mcpServerActive;
  };

  const isPluginConnected = () => {
    // Removed timeout - once plugin connects, stay connected
    return pluginConnected;
  };

  app.use(cors());
  app.use(express.json({ limit: '50mb' }));
  app.use(express.urlencoded({ limit: '50mb', extended: true }));

  // Health check endpoint
  app.get('/health', (req, res) => {
    res.json({ 
      status: 'ok', 
      service: 'robloxstudio-mcp',
      pluginConnected,
      mcpServerActive: isMCPServerActive(),
      uptime: mcpServerActive ? Date.now() - mcpServerStartTime : 0
    });
  });

  // Plugin readiness endpoint
  app.post('/ready', (req, res) => {
    pluginConnected = true;
    lastPluginActivity = Date.now();
    res.json({ success: true });
  });

  // Plugin disconnect endpoint
  app.post('/disconnect', (req, res) => {
    pluginConnected = false;
    // Clear any pending requests when plugin disconnects
    bridge.clearAllPendingRequests();
    res.json({ success: true });
  });

  // Enhanced status endpoint
  app.get('/status', (req, res) => {
    res.json({ 
      pluginConnected,
      mcpServerActive: isMCPServerActive(),
      lastMCPActivity,
      uptime: mcpServerActive ? Date.now() - mcpServerStartTime : 0
    });
  });

  // Enhanced polling endpoint for Studio plugin
  app.get('/poll', (req, res) => {
    // Always track that plugin is polling (shows it's trying to connect)
    if (!pluginConnected) {
      pluginConnected = true;
    }
    lastPluginActivity = Date.now();
    
    if (!isMCPServerActive()) {
      res.status(503).json({ 
        error: 'MCP server not connected',
        pluginConnected: true,
        mcpConnected: false,
        request: null
      });
      return;
    }
    
    trackMCPActivity();
    
    const pendingRequest = bridge.getPendingRequest();
    if (pendingRequest) {
      res.json({ 
        request: pendingRequest.request, 
        requestId: pendingRequest.requestId,
        mcpConnected: true,
        pluginConnected: true
      });
    } else {
      res.json({ 
        request: null,
        mcpConnected: true,
        pluginConnected: true
      });
    }
  });

  // Response endpoint for Studio plugin
  app.post('/response', (req, res) => {
    const { requestId, response, error } = req.body;
    
    if (error) {
      bridge.rejectRequest(requestId, error);
    } else {
      bridge.resolveRequest(requestId, response);
    }
    
    res.json({ success: true });
  });

  // Middleware to track MCP activity for all MCP endpoints
  app.use('/mcp/*', (req, res, next) => {
    trackMCPActivity();
    next();
  });

  // MCP tool proxy endpoints - these will be called by AI tools
  app.post('/mcp/get_file_tree', async (req, res) => {
    try {
      const result = await tools.getFileTree(req.body.path);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });


  app.post('/mcp/search_files', async (req, res) => {
    try {
      const result = await tools.searchFiles(req.body.query, req.body.searchType);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });


  app.post('/mcp/get_place_info', async (req, res) => {
    try {
      const result = await tools.getPlaceInfo();
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/get_services', async (req, res) => {
    try {
      const result = await tools.getServices(req.body.serviceName);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });


  app.post('/mcp/search_objects', async (req, res) => {
    try {
      const result = await tools.searchObjects(req.body.query, req.body.searchType, req.body.propertyName);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/get_instance_properties', async (req, res) => {
    try {
      const result = await tools.getInstanceProperties(req.body.instancePath);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/get_instance_children', async (req, res) => {
    try {
      const result = await tools.getInstanceChildren(req.body.instancePath);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/search_by_property', async (req, res) => {
    try {
      const result = await tools.searchByProperty(req.body.propertyName, req.body.propertyValue);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/get_class_info', async (req, res) => {
    try {
      const result = await tools.getClassInfo(req.body.className);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/mass_set_property', async (req, res) => {
    try {
      const result = await tools.massSetProperty(req.body.paths, req.body.propertyName, req.body.propertyValue);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/mass_get_property', async (req, res) => {
    try {
      const result = await tools.massGetProperty(req.body.paths, req.body.propertyName);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/create_object_with_properties', async (req, res) => {
    try {
      const result = await tools.createObjectWithProperties(req.body.className, req.body.parent, req.body.name, req.body.properties);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/mass_create_objects', async (req, res) => {
    try {
      const result = await tools.massCreateObjects(req.body.objects);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/mass_create_objects_with_properties', async (req, res) => {
    try {
      const result = await tools.massCreateObjectsWithProperties(req.body.objects);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/get_project_structure', async (req, res) => {
    try {
      const result = await tools.getProjectStructure(req.body.path, req.body.maxDepth, req.body.scriptsOnly);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  // Script management endpoints (parity with tools)
  app.post('/mcp/get_script_source', async (req, res) => {
    try {
      const result = await tools.getScriptSource(req.body.instancePath);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/set_script_source', async (req, res) => {
    try {
      const result = await tools.setScriptSource(req.body.instancePath, req.body.source);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/get_selection', async (req, res) => {
    try {
      const result = await tools.getSelection();
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  // Property modification endpoint
  app.post('/mcp/set_property', async (req, res) => {
    try {
      const result = await tools.setProperty(req.body.instancePath, req.body.propertyName, req.body.propertyValue);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  // Object creation/deletion endpoints
  app.post('/mcp/create_object', async (req, res) => {
    try {
      const result = await tools.createObject(req.body.className, req.body.parent, req.body.name);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/delete_object', async (req, res) => {
    try {
      const result = await tools.deleteObject(req.body.instancePath);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  // Smart duplication endpoints
  app.post('/mcp/smart_duplicate', async (req, res) => {
    try {
      const result = await tools.smartDuplicate(req.body.instancePath, req.body.count, req.body.options);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/mass_duplicate', async (req, res) => {
    try {
      const result = await tools.massDuplicate(req.body.duplications);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  // Calculated/relative property endpoints
  app.post('/mcp/set_calculated_property', async (req, res) => {
    try {
      const result = await tools.setCalculatedProperty(req.body.paths, req.body.propertyName, req.body.formula, req.body.variables);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/set_relative_property', async (req, res) => {
    try {
      const result = await tools.setRelativeProperty(req.body.paths, req.body.propertyName, req.body.operation, req.body.value, req.body.component);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  // Partial script editing endpoints
  app.post('/mcp/edit_script_lines', async (req, res) => {
    try {
      const result = await tools.editScriptLines(req.body.instancePath, req.body.startLine, req.body.endLine, req.body.newContent);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/insert_script_lines', async (req, res) => {
    try {
      const result = await tools.insertScriptLines(req.body.instancePath, req.body.afterLine, req.body.newContent);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/delete_script_lines', async (req, res) => {
    try {
      const result = await tools.deleteScriptLines(req.body.instancePath, req.body.startLine, req.body.endLine);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  // Attribute endpoints
  app.post('/mcp/get_attribute', async (req, res) => {
    try {
      const result = await tools.getAttribute(req.body.instancePath, req.body.attributeName);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/set_attribute', async (req, res) => {
    try {
      const result = await tools.setAttribute(req.body.instancePath, req.body.attributeName, req.body.attributeValue, req.body.valueType);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/get_attributes', async (req, res) => {
    try {
      const result = await tools.getAttributes(req.body.instancePath);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/delete_attribute', async (req, res) => {
    try {
      const result = await tools.deleteAttribute(req.body.instancePath, req.body.attributeName);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  // Tag (CollectionService) endpoints
  app.post('/mcp/get_tags', async (req, res) => {
    try {
      const result = await tools.getTags(req.body.instancePath);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/add_tag', async (req, res) => {
    try {
      const result = await tools.addTag(req.body.instancePath, req.body.tagName);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/remove_tag', async (req, res) => {
    try {
      const result = await tools.removeTag(req.body.instancePath, req.body.tagName);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  app.post('/mcp/get_tagged', async (req, res) => {
    try {
      const result = await tools.getTagged(req.body.tagName);
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  // Add methods to control and check server status
  (app as any).isPluginConnected = isPluginConnected;
  (app as any).setMCPServerActive = setMCPServerActive;
  (app as any).isMCPServerActive = isMCPServerActive;
  (app as any).trackMCPActivity = trackMCPActivity;

  return app;
}