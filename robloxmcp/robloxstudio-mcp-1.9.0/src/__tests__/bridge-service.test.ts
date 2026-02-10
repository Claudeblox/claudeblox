import { BridgeService } from '../bridge-service';

describe('BridgeService', () => {
  let bridgeService: BridgeService;

  beforeEach(() => {
    bridgeService = new BridgeService();
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  describe('Request Management', () => {
    test('should create and store a pending request', async () => {
      const endpoint = '/api/test';
      const data = { test: 'data' };
      
      const requestPromise = bridgeService.sendRequest(endpoint, data);
      
      // Check that request is pending
      const pendingRequest = bridgeService.getPendingRequest();
      expect(pendingRequest).toBeTruthy();
      expect(pendingRequest?.request.endpoint).toBe(endpoint);
      expect(pendingRequest?.request.data).toEqual(data);
    });

    test('should resolve request when response is received', async () => {
      const endpoint = '/api/test';
      const data = { test: 'data' };
      const response = { result: 'success' };
      
      const requestPromise = bridgeService.sendRequest(endpoint, data);
      const pendingRequest = bridgeService.getPendingRequest();
      
      // Resolve the request
      bridgeService.resolveRequest(pendingRequest!.requestId, response);
      
      const result = await requestPromise;
      expect(result).toEqual(response);
    });

    test('should reject request on error', async () => {
      const endpoint = '/api/test';
      const data = { test: 'data' };
      const error = 'Test error';
      
      const requestPromise = bridgeService.sendRequest(endpoint, data);
      const pendingRequest = bridgeService.getPendingRequest();
      
      // Reject the request
      bridgeService.rejectRequest(pendingRequest!.requestId, error);
      
      await expect(requestPromise).rejects.toEqual(error);
    });

    test('should timeout request after 30 seconds', async () => {
      const endpoint = '/api/test';
      const data = { test: 'data' };
      
      const requestPromise = bridgeService.sendRequest(endpoint, data);
      
      // Fast-forward time by 31 seconds
      jest.advanceTimersByTime(31000);
      
      await expect(requestPromise).rejects.toThrow('Request timeout');
    });
  });

  describe('Cleanup Operations', () => {
    test('should clean up old requests', async () => {
      // Create multiple requests
      const promises = [
        bridgeService.sendRequest('/api/test1', {}),
        bridgeService.sendRequest('/api/test2', {}),
        bridgeService.sendRequest('/api/test3', {})
      ];
      
      // Fast-forward time by 31 seconds
      jest.advanceTimersByTime(31000);
      
      // Clean up old requests
      bridgeService.cleanupOldRequests();
      
      // All requests should be rejected
      for (const promise of promises) {
        await expect(promise).rejects.toThrow('Request timeout');
      }
      
      // No pending requests should remain
      expect(bridgeService.getPendingRequest()).toBeNull();
    });

    test('should clear all pending requests on disconnect', async () => {
      // Create multiple requests
      const promises = [
        bridgeService.sendRequest('/api/test1', {}),
        bridgeService.sendRequest('/api/test2', {}),
        bridgeService.sendRequest('/api/test3', {})
      ];
      
      // Clear all requests
      bridgeService.clearAllPendingRequests();
      
      // All requests should be rejected with connection closed error
      for (const promise of promises) {
        await expect(promise).rejects.toThrow('Connection closed');
      }
      
      // No pending requests should remain
      expect(bridgeService.getPendingRequest()).toBeNull();
    });
  });

  describe('Request Priority', () => {
    test('should return oldest request first', async () => {
      // Create requests with different timestamps using fake timers
      bridgeService.sendRequest('/api/test1', { order: 1 });

      // Advance time to ensure different timestamps
      jest.advanceTimersByTime(10);

      bridgeService.sendRequest('/api/test2', { order: 2 });

      jest.advanceTimersByTime(10);

      bridgeService.sendRequest('/api/test3', { order: 3 });

      // getPendingRequest() peeks at the oldest request without removing it
      // So we need to resolve each request to get to the next one

      // Should get the first (oldest) request
      const firstRequest = bridgeService.getPendingRequest();
      expect(firstRequest?.request.data.order).toBe(1);

      // Resolve the first request to remove it from the queue
      bridgeService.resolveRequest(firstRequest!.requestId, {});

      // Should get the second request next
      const secondRequest = bridgeService.getPendingRequest();
      expect(secondRequest?.request.data.order).toBe(2);

      // Resolve the second request
      bridgeService.resolveRequest(secondRequest!.requestId, {});

      // Should get the third request last
      const thirdRequest = bridgeService.getPendingRequest();
      expect(thirdRequest?.request.data.order).toBe(3);

      // Resolve the third request
      bridgeService.resolveRequest(thirdRequest!.requestId, {});

      // No more pending requests
      expect(bridgeService.getPendingRequest()).toBeNull();
    });
  });
});