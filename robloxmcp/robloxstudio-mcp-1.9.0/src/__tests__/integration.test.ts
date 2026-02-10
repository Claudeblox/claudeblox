import request from 'supertest';
import { createHttpServer } from '../http-server';
import { RobloxStudioTools } from '../tools/index';
import { BridgeService } from '../bridge-service';
import { Application } from 'express';

describe('Integration Tests', () => {
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

  describe('Full Connection Flow', () => {
    test('should handle complete connection lifecycle', async () => {
      // 1. Initial state - nothing connected
      let status = await request(app).get('/status').expect(200);
      expect(status.body.pluginConnected).toBe(false);
      expect(status.body.mcpServerActive).toBe(false);

      // 2. Plugin connects
      await request(app).post('/ready').expect(200);
      
      status = await request(app).get('/status').expect(200);
      expect(status.body.pluginConnected).toBe(true);
      expect(status.body.mcpServerActive).toBe(false);

      // 3. Plugin polls - should show MCP not connected
      let pollResponse = await request(app).get('/poll').expect(503);
      expect(pollResponse.body).toMatchObject({
        error: 'MCP server not connected',
        pluginConnected: true,
        mcpConnected: false
      });

      // 4. MCP server activates
      app.setMCPServerActive(true);
      
      status = await request(app).get('/status').expect(200);
      expect(status.body.pluginConnected).toBe(true);
      expect(status.body.mcpServerActive).toBe(true);

      // 5. Plugin polls - should show both connected
      pollResponse = await request(app).get('/poll').expect(200);
      expect(pollResponse.body).toMatchObject({
        request: null,
        mcpConnected: true,
        pluginConnected: true
      });

      // 6. Plugin disconnects
      await request(app).post('/disconnect').expect(200);
      
      status = await request(app).get('/status').expect(200);
      expect(status.body.pluginConnected).toBe(false);
      expect(status.body.mcpServerActive).toBe(true); // MCP still active
    });
  });

  describe('Request/Response Flow', () => {
    test('should handle complete request/response cycle', async () => {
      // Setup: Connect everything
      await request(app).post('/ready').expect(200);
      app.setMCPServerActive(true);

      // 1. MCP sends a request through bridge
      const mcpRequestPromise = bridge.sendRequest('/api/test-endpoint', {
        testData: 'hello',
        value: 123
      });

      // 2. Plugin polls and gets the request
      const pollResponse = await request(app).get('/poll').expect(200);
      expect(pollResponse.body.request).toMatchObject({
        endpoint: '/api/test-endpoint',
        data: {
          testData: 'hello',
          value: 123
        }
      });
      const requestId = pollResponse.body.requestId;

      // 3. Plugin processes and sends response
      await request(app)
        .post('/response')
        .send({
          requestId: requestId,
          response: {
            success: true,
            result: 'processed',
            echo: 'hello'
          }
        })
        .expect(200);

      // 4. MCP receives the response
      const mcpResponse = await mcpRequestPromise;
      expect(mcpResponse).toEqual({
        success: true,
        result: 'processed',
        echo: 'hello'
      });
    });

    test('should handle error responses', async () => {
      // Setup
      await request(app).post('/ready').expect(200);
      app.setMCPServerActive(true);

      // Send request
      // Attach catch handler to prevent unhandled rejection warning
      const mcpRequestPromise = bridge.sendRequest('/api/failing-endpoint', {});
      mcpRequestPromise.catch(() => {});

      // Poll for request
      const pollResponse = await request(app).get('/poll').expect(200);
      const requestId = pollResponse.body.requestId;

      // Send error response
      await request(app)
        .post('/response')
        .send({
          requestId: requestId,
          error: 'Operation failed: Invalid input'
        })
        .expect(200);

      // Should reject with the error
      await expect(mcpRequestPromise).rejects.toEqual('Operation failed: Invalid input');
    });
  });

  describe('Disconnect Recovery', () => {
    test('should handle disconnect and reconnect gracefully', async () => {
      // Initial connection
      await request(app).post('/ready').expect(200);
      app.setMCPServerActive(true);

      // Create some pending requests
      // Attach catch handlers to prevent unhandled rejection warnings
      const request1 = bridge.sendRequest('/api/test1', {});
      const request2 = bridge.sendRequest('/api/test2', {});
      request1.catch(() => {});
      request2.catch(() => {});

      // Verify requests are pending
      let poll = await request(app).get('/poll').expect(200);
      expect(poll.body.request).toBeTruthy();

      // Disconnect
      await request(app).post('/disconnect').expect(200);

      // Requests should be rejected
      await expect(request1).rejects.toThrow('Connection closed');
      await expect(request2).rejects.toThrow('Connection closed');

      // Reconnect
      await request(app).post('/ready').expect(200);

      // Should be able to handle new requests
      const newRequestPromise = bridge.sendRequest('/api/test3', {});
      
      poll = await request(app).get('/poll').expect(200);
      expect(poll.body.request?.endpoint).toBe('/api/test3');

      // Complete the new request
      await request(app)
        .post('/response')
        .send({
          requestId: poll.body.requestId,
          response: { success: true }
        })
        .expect(200);

      const result = await newRequestPromise;
      expect(result).toEqual({ success: true });
    });
  });

  describe('Connection State Display', () => {
    test('should show correct pending states during connection', async () => {
      // Initially disconnected: "HTTP: X  MCP: X"
      let health = await request(app).get('/health').expect(200);
      expect(health.body.pluginConnected).toBe(false);
      expect(health.body.mcpServerActive).toBe(false);

      // Plugin starts polling: "HTTP: ...  MCP: ..."
      await request(app).get('/poll').expect(503);
      
      health = await request(app).get('/health').expect(200);
      expect(health.body.pluginConnected).toBe(true);
      expect(health.body.mcpServerActive).toBe(false);

      // MCP connects: "HTTP: OK  MCP: OK"
      app.setMCPServerActive(true);
      
      const poll = await request(app).get('/poll').expect(200);
      expect(poll.body.mcpConnected).toBe(true);
      expect(poll.body.pluginConnected).toBe(true);
    });
  });

  describe('Timeout Handling', () => {
    test('should handle request timeouts', async () => {
      jest.useFakeTimers();
      
      // Setup
      await request(app).post('/ready').expect(200);
      app.setMCPServerActive(true);

      // Send request but don't respond
      const timeoutPromise = bridge.sendRequest('/api/slow-endpoint', {});

      // Plugin polls for it
      await request(app).get('/poll').expect(200);

      // Fast forward time past timeout
      jest.advanceTimersByTime(31000);

      // Request should timeout
      await expect(timeoutPromise).rejects.toThrow('Request timeout');

      jest.useRealTimers();
    });
  });
});