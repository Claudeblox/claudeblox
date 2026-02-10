export declare class BridgeService {
    private pendingRequests;
    private requestTimeout;
    sendRequest(endpoint: string, data: any): Promise<any>;
    getPendingRequest(): {
        requestId: string;
        request: {
            endpoint: string;
            data: any;
        };
    } | null;
    resolveRequest(requestId: string, response: any): void;
    rejectRequest(requestId: string, error: any): void;
    cleanupOldRequests(): void;
    clearAllPendingRequests(): void;
}
//# sourceMappingURL=bridge-service.d.ts.map