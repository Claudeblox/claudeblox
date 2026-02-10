import { BridgeService } from '../bridge-service.js';
export declare class RobloxStudioTools {
    private client;
    constructor(bridge: BridgeService);
    getFileTree(path?: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    searchFiles(query: string, searchType?: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    getPlaceInfo(): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    getServices(serviceName?: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    searchObjects(query: string, searchType?: string, propertyName?: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    getInstanceProperties(instancePath: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    getInstanceChildren(instancePath: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    searchByProperty(propertyName: string, propertyValue: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    getClassInfo(className: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    getProjectStructure(path?: string, maxDepth?: number, scriptsOnly?: boolean): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    setProperty(instancePath: string, propertyName: string, propertyValue: any): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    massSetProperty(paths: string[], propertyName: string, propertyValue: any): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    massGetProperty(paths: string[], propertyName: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    createObject(className: string, parent: string, name?: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    createObjectWithProperties(className: string, parent: string, name?: string, properties?: Record<string, any>): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    massCreateObjects(objects: Array<{
        className: string;
        parent: string;
        name?: string;
    }>): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    massCreateObjectsWithProperties(objects: Array<{
        className: string;
        parent: string;
        name?: string;
        properties?: Record<string, any>;
    }>): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    deleteObject(instancePath: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    smartDuplicate(instancePath: string, count: number, options?: {
        namePattern?: string;
        positionOffset?: [number, number, number];
        rotationOffset?: [number, number, number];
        scaleOffset?: [number, number, number];
        propertyVariations?: Record<string, any[]>;
        targetParents?: string[];
    }): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    massDuplicate(duplications: Array<{
        instancePath: string;
        count: number;
        options?: {
            namePattern?: string;
            positionOffset?: [number, number, number];
            rotationOffset?: [number, number, number];
            scaleOffset?: [number, number, number];
            propertyVariations?: Record<string, any[]>;
            targetParents?: string[];
        };
    }>): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    setCalculatedProperty(paths: string[], propertyName: string, formula: string, variables?: Record<string, any>): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    setRelativeProperty(paths: string[], propertyName: string, operation: 'add' | 'multiply' | 'divide' | 'subtract' | 'power', value: any, component?: 'X' | 'Y' | 'Z' | 'XScale' | 'XOffset' | 'YScale' | 'YOffset'): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    getScriptSource(instancePath: string, startLine?: number, endLine?: number): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    setScriptSource(instancePath: string, source: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    editScriptLines(instancePath: string, startLine: number, endLine: number, newContent: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    insertScriptLines(instancePath: string, afterLine: number, newContent: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    deleteScriptLines(instancePath: string, startLine: number, endLine: number): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    getAttribute(instancePath: string, attributeName: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    setAttribute(instancePath: string, attributeName: string, attributeValue: any, valueType?: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    getAttributes(instancePath: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    deleteAttribute(instancePath: string, attributeName: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    getTags(instancePath: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    addTag(instancePath: string, tagName: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    removeTag(instancePath: string, tagName: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    getTagged(tagName: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    getSelection(): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
    executeLuau(code: string): Promise<{
        content: {
            type: string;
            text: string;
        }[];
    }>;
}
//# sourceMappingURL=index.d.ts.map