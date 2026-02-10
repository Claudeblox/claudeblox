import { v4 as uuidv4 } from 'uuid';

interface PendingRequest {
  id: string;
  endpoint: string;
  data: any;
  timestamp: number;
  resolve: (value: any) => void;
  reject: (error: any) => void;
  timeoutId: ReturnType<typeof setTimeout>;
}

export class BridgeService {
  private pendingRequests: Map<string, PendingRequest> = new Map();
  private requestTimeout = 120000; // 2 minutes timeout (was 30 seconds)

  async sendRequest(endpoint: string, data: any): Promise<any> {
    const requestId = uuidv4();

    return new Promise((resolve, reject) => {
      // Set timeout and store the ID so we can clear it later
      const timeoutId = setTimeout(() => {
        if (this.pendingRequests.has(requestId)) {
          this.pendingRequests.delete(requestId);
          reject(new Error('Request timeout'));
        }
      }, this.requestTimeout);

      const request: PendingRequest = {
        id: requestId,
        endpoint,
        data,
        timestamp: Date.now(),
        resolve,
        reject,
        timeoutId
      };

      this.pendingRequests.set(requestId, request);
    });
  }

  getPendingRequest(): { requestId: string; request: { endpoint: string; data: any } } | null {
    // Get oldest pending request
    let oldestRequest: PendingRequest | null = null;
    
    for (const request of this.pendingRequests.values()) {
      if (!oldestRequest || request.timestamp < oldestRequest.timestamp) {
        oldestRequest = request;
      }
    }

    if (oldestRequest) {
      return {
        requestId: oldestRequest.id,
        request: {
          endpoint: oldestRequest.endpoint,
          data: oldestRequest.data
        }
      };
    }

    return null;
  }

  resolveRequest(requestId: string, response: any) {
    const request = this.pendingRequests.get(requestId);
    if (request) {
      clearTimeout(request.timeoutId);
      this.pendingRequests.delete(requestId);
      request.resolve(response);
    }
  }

  rejectRequest(requestId: string, error: any) {
    const request = this.pendingRequests.get(requestId);
    if (request) {
      clearTimeout(request.timeoutId);
      this.pendingRequests.delete(requestId);
      request.reject(error);
    }
  }

  // Clean up old requests
  cleanupOldRequests() {
    const now = Date.now();
    for (const [id, request] of this.pendingRequests.entries()) {
      if (now - request.timestamp > this.requestTimeout) {
        clearTimeout(request.timeoutId);
        this.pendingRequests.delete(id);
        request.reject(new Error('Request timeout'));
      }
    }
  }

  // Force cleanup all pending requests (used on disconnect)
  clearAllPendingRequests() {
    for (const [, request] of this.pendingRequests.entries()) {
      clearTimeout(request.timeoutId);
      request.reject(new Error('Connection closed'));
    }
    this.pendingRequests.clear();
  }
}