import request from 'supertest';
import { createHttpServer } from '../http-server';
import { RobloxStudioTools } from '../tools/index';
import { BridgeService } from '../bridge-service';
import { Application } from 'express';

describe('HTTP Server', () => {
  let app: Application & any;
  let bridge: BridgeService;
  let tools: RobloxStudioTools;

  beforeEach(() => {
    bridge = new BridgeService();
    tools = new RobloxStudioTools(bridge);
    app = createHttpServer(tools, bridge);
  });

  afterEach(() => {
    // Clean up any pending requests to prevent open handles
    bridge.clearAllPendingRequests();
  });

  describe('Health Check', () => {
    test('should return health status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toMatchObject({
        status: 'ok',
        service: 'robloxstudio-mcp',
        pluginConnected: false,
        mcpServerActive: false
      });
    });
  });

  describe('Plugin Connection Management', () => {
    test('should handle plugin ready notification', async () => {
      const response = await request(app)
        .post('/ready')
        .expect(200);

      expect(response.body).toEqual({ success: true });
      expect(app.isPluginConnected()).toBe(true);
    });

    test('should handle plugin disconnect', async () => {
      // First connect
      await request(app).post('/ready').expect(200);
      expect(app.isPluginConnected()).toBe(true);

      // Then disconnect
      const response = await request(app)
        .post('/disconnect')
        .expect(200);

      expect(response.body).toEqual({ success: true });
      expect(app.isPluginConnected()).toBe(false);
    });

    test('should clear pending requests on disconnect', async () => {
      // Add some pending requests
      // Attach catch handlers to prevent unhandled rejection warnings
      const p1 = bridge.sendRequest('/api/test1', {});
      const p2 = bridge.sendRequest('/api/test2', {});
      p1.catch(() => {});
      p2.catch(() => {});

      expect(bridge.getPendingRequest()).toBeTruthy();

      // Disconnect
      await request(app).post('/disconnect').expect(200);

      // All requests should be cleared
      expect(bridge.getPendingRequest()).toBeNull();
    });

    test('should timeout plugin connection after inactivity', async () => {
      // Connect plugin
      await request(app).post('/ready').expect(200);
      expect(app.isPluginConnected()).toBe(true);

      // Simulate time passing (11 seconds of inactivity)
      const originalDateNow = Date.now;
      Date.now = jest.fn(() => originalDateNow() + 11000);

      // Plugin should be considered disconnected
      expect(app.isPluginConnected()).toBe(false);

      // Restore Date.now
      Date.now = originalDateNow;
    });
  });

  describe('Polling Endpoint', () => {
    test('should return 503 when MCP server is not active', async () => {
      const response = await request(app)
        .get('/poll')
        .expect(503);

      expect(response.body).toMatchObject({
        error: 'MCP server not connected',
        pluginConnected: true,
        mcpConnected: false,
        request: null
      });
    });

    test('should return pending request when MCP is active', async () => {
      // Activate MCP server
      app.setMCPServerActive(true);

      // Add a pending request
      // Attach catch handler to prevent unhandled rejection during cleanup
      const pendingRequest = bridge.sendRequest('/api/test', { data: 'test' });
      pendingRequest.catch(() => {});

      const response = await request(app)
        .get('/poll')
        .expect(200);

      expect(response.body).toMatchObject({
        request: {
          endpoint: '/api/test',
          data: { data: 'test' }
        },
        mcpConnected: true,
        pluginConnected: true
      });
      expect(response.body.requestId).toBeTruthy();
    });

    test('should return null request when no pending requests', async () => {
      // Activate MCP server
      app.setMCPServerActive(true);

      const response = await request(app)
        .get('/poll')
        .expect(200);

      expect(response.body).toMatchObject({
        request: null,
        mcpConnected: true,
        pluginConnected: true
      });
    });

    test('should mark plugin as connected when polling', async () => {
      expect(app.isPluginConnected()).toBe(false);

      await request(app).get('/poll').expect(503);

      expect(app.isPluginConnected()).toBe(true);
    });
  });

  describe('Response Handling', () => {
    test('should handle successful response', async () => {
      const requestId = 'test-request-id';
      const responseData = { result: 'success' };

      // Create a pending request
      const requestPromise = bridge.sendRequest('/api/test', {});
      const pendingRequest = bridge.getPendingRequest();

      // Send response
      const response = await request(app)
        .post('/response')
        .send({
          requestId: pendingRequest!.requestId,
          response: responseData
        })
        .expect(200);

      expect(response.body).toEqual({ success: true });

      // Check that the request was resolved
      const result = await requestPromise;
      expect(result).toEqual(responseData);
    });

    test('should handle error response', async () => {
      const error = 'Test error message';

      // Create a pending request
      // Attach catch handler to prevent unhandled rejection warning
      const requestPromise = bridge.sendRequest('/api/test', {});
      requestPromise.catch(() => {});
      const pendingRequest = bridge.getPendingRequest();

      // Send error response
      const response = await request(app)
        .post('/response')
        .send({
          requestId: pendingRequest!.requestId,
          error: error
        })
        .expect(200);

      expect(response.body).toEqual({ success: true });

      // Check that the request was rejected
      await expect(requestPromise).rejects.toEqual(error);
    });
  });

  describe('MCP Server State Management', () => {
    test('should track MCP server activity', async () => {
      app.setMCPServerActive(true);
      expect(app.isMCPServerActive()).toBe(true);

      // Simulate activity
      app.trackMCPActivity();

      // Should still be active
      expect(app.isMCPServerActive()).toBe(true);
    });

    test('should timeout MCP server after inactivity', async () => {
      app.setMCPServerActive(true);
      expect(app.isMCPServerActive()).toBe(true);

      // Simulate time passing (16 seconds of inactivity)
      const originalDateNow = Date.now;
      Date.now = jest.fn(() => originalDateNow() + 16000);

      // MCP server should be considered inactive
      expect(app.isMCPServerActive()).toBe(false);

      // Restore Date.now
      Date.now = originalDateNow;
    });
  });

  describe('Status Endpoint', () => {
    test('should return current status', async () => {
      // Set up some state
      await request(app).post('/ready').expect(200);
      app.setMCPServerActive(true);

      const response = await request(app)
        .get('/status')
        .expect(200);

      expect(response.body).toMatchObject({
        pluginConnected: true,
        mcpServerActive: true
      });
      expect(response.body.lastMCPActivity).toBeGreaterThan(0);
      expect(response.body.uptime).toBeGreaterThan(0);
    });
  });
});