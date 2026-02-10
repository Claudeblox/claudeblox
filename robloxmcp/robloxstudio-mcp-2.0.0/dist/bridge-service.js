import { v4 as uuidv4 } from 'uuid';
export class BridgeService {
    pendingRequests = new Map();
    requestTimeout = 300000; // PATCHED: 5 minutes timeout (was 30 seconds)
    async sendRequest(endpoint, data) {
        const requestId = uuidv4();
        return new Promise((resolve, reject) => {
            // Set timeout and store the ID so we can clear it later
            const timeoutId = setTimeout(() => {
                if (this.pendingRequests.has(requestId)) {
                    this.pendingRequests.delete(requestId);
                    reject(new Error('Request timeout'));
                }
            }, this.requestTimeout);
            const request = {
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
    getPendingRequest() {
        // Get oldest pending request
        let oldestRequest = null;
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
    resolveRequest(requestId, response) {
        const request = this.pendingRequests.get(requestId);
        if (request) {
            clearTimeout(request.timeoutId);
            this.pendingRequests.delete(requestId);
            request.resolve(response);
        }
    }
    rejectRequest(requestId, error) {
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
//# sourceMappingURL=bridge-service.js.map