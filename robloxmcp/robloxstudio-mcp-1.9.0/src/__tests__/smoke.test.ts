import { BridgeService } from '../bridge-service.js';
import { createHttpServer } from '../http-server.js';
import { RobloxStudioTools } from '../tools/index.js';
import request from 'supertest';

describe('Smoke Tests - Connection Fixes', () => {
  test('BridgeService should be instantiable', () => {
    const bridge = new BridgeService();
    expect(bridge).toBeDefined();
    expect(bridge.getPendingRequest()).toBeNull();
  });

  test('HTTP server should start and respond to health check', async () => {
    const bridge = new BridgeService();
    const tools = new RobloxStudioTools(bridge);
    const app = createHttpServer(tools, bridge);

    const response = await request(app)
      .get('/health')
      .expect(200);

    expect(response.body.status).toBe('ok');
    expect(response.body.service).toBe('robloxstudio-mcp');
  });

  test('clearAllPendingRequests should clear all requests', async () => {
    const bridge = new BridgeService();
    
    // Don't wait for these promises - they'll be rejected
    const promise1 = bridge.sendRequest('/test1', {});
    const promise2 = bridge.sendRequest('/test2', {});
    
    // Should have pending requests
    expect(bridge.getPendingRequest()).toBeTruthy();
    
    // Clear all requests
    bridge.clearAllPendingRequests();
    
    // Should have no pending requests
    expect(bridge.getPendingRequest()).toBeNull();
    
    // Promises should reject
    await expect(promise1).rejects.toThrow('Connection closed');
    await expect(promise2).rejects.toThrow('Connection closed');
  });

  test('Disconnect endpoint should clear pending requests', async () => {
    const bridge = new BridgeService();
    const tools = new RobloxStudioTools(bridge);
    const app = createHttpServer(tools, bridge);

    // Add a pending request (don't await it)
    // Attach a no-op catch to prevent unhandled rejection warning
    const pendingPromise = bridge.sendRequest('/test', { data: 'test' });
    pendingPromise.catch(() => {}); // Prevent unhandled rejection

    // Disconnect should clear it
    await request(app)
      .post('/disconnect')
      .expect(200);

    // Request should be rejected
    await expect(pendingPromise).rejects.toThrow('Connection closed');
  });

  test('Connection states should update correctly', async () => {
    const bridge = new BridgeService();
    const tools = new RobloxStudioTools(bridge);
    const app = createHttpServer(tools, bridge) as any;

    // Initially not connected
    expect(app.isPluginConnected()).toBe(false);
    
    // After ready
    await request(app).post('/ready').expect(200);
    expect(app.isPluginConnected()).toBe(true);
    
    // After disconnect
    await request(app).post('/disconnect').expect(200);
    expect(app.isPluginConnected()).toBe(false);
  });
});