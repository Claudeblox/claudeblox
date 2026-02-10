import { BridgeService } from '../bridge-service.js';
export declare class StudioHttpClient {
    private bridge;
    constructor(bridge: BridgeService);
    request(endpoint: string, data: any): Promise<any>;
}
//# sourceMappingURL=studio-client.d.ts.map