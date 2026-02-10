export class StudioHttpClient {
    bridge;
    constructor(bridge) {
        this.bridge = bridge;
    }
    async request(endpoint, data) {
        try {
            const response = await this.bridge.sendRequest(endpoint, data);
            return response;
        }
        catch (error) {
            if (error instanceof Error && error.message === 'Request timeout') {
                throw new Error('Studio plugin connection timeout. Make sure the Roblox Studio plugin is running and activated.');
            }
            throw error;
        }
    }
}
//# sourceMappingURL=studio-client.js.map