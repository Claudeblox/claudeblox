import { StudioHttpClient } from './studio-client.js';
export class RobloxStudioTools {
    client;
    constructor(bridge) {
        this.client = new StudioHttpClient(bridge);
    }
    // File System Tools
    async getFileTree(path = '') {
        const response = await this.client.request('/api/file-tree', { path });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async searchFiles(query, searchType = 'name') {
        const response = await this.client.request('/api/search-files', { query, searchType });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    // Studio Context Tools
    async getPlaceInfo() {
        const response = await this.client.request('/api/place-info', {});
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async getServices(serviceName) {
        const response = await this.client.request('/api/services', { serviceName });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async searchObjects(query, searchType = 'name', propertyName) {
        const response = await this.client.request('/api/search-objects', {
            query,
            searchType,
            propertyName
        });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    // Property & Instance Tools
    async getInstanceProperties(instancePath) {
        if (!instancePath) {
            throw new Error('Instance path is required for get_instance_properties');
        }
        const response = await this.client.request('/api/instance-properties', { instancePath });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async getInstanceChildren(instancePath) {
        if (!instancePath) {
            throw new Error('Instance path is required for get_instance_children');
        }
        const response = await this.client.request('/api/instance-children', { instancePath });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async searchByProperty(propertyName, propertyValue) {
        if (!propertyName || !propertyValue) {
            throw new Error('Property name and value are required for search_by_property');
        }
        const response = await this.client.request('/api/search-by-property', {
            propertyName,
            propertyValue
        });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async getClassInfo(className) {
        if (!className) {
            throw new Error('Class name is required for get_class_info');
        }
        const response = await this.client.request('/api/class-info', { className });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    // Project Tools
    async getProjectStructure(path, maxDepth, scriptsOnly) {
        const response = await this.client.request('/api/project-structure', {
            path,
            maxDepth,
            scriptsOnly
        });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    // Property Modification Tools
    async setProperty(instancePath, propertyName, propertyValue) {
        if (!instancePath || !propertyName) {
            throw new Error('Instance path and property name are required for set_property');
        }
        const response = await this.client.request('/api/set-property', {
            instancePath,
            propertyName,
            propertyValue
        });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async massSetProperty(paths, propertyName, propertyValue) {
        if (!paths || paths.length === 0 || !propertyName) {
            throw new Error('Paths array and property name are required for mass_set_property');
        }
        const response = await this.client.request('/api/mass-set-property', {
            paths,
            propertyName,
            propertyValue
        });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async massGetProperty(paths, propertyName) {
        if (!paths || paths.length === 0 || !propertyName) {
            throw new Error('Paths array and property name are required for mass_get_property');
        }
        const response = await this.client.request('/api/mass-get-property', {
            paths,
            propertyName
        });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    // Object Creation Tools
    async createObject(className, parent, name) {
        if (!className || !parent) {
            throw new Error('Class name and parent are required for create_object');
        }
        const response = await this.client.request('/api/create-object', {
            className,
            parent,
            name
        });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async createObjectWithProperties(className, parent, name, properties) {
        if (!className || !parent) {
            throw new Error('Class name and parent are required for create_object_with_properties');
        }
        const response = await this.client.request('/api/create-object', {
            className,
            parent,
            name,
            properties
        });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async massCreateObjects(objects) {
        if (!objects || objects.length === 0) {
            throw new Error('Objects array is required for mass_create_objects');
        }
        const response = await this.client.request('/api/mass-create-objects', { objects });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async massCreateObjectsWithProperties(objects) {
        if (!objects || objects.length === 0) {
            throw new Error('Objects array is required for mass_create_objects_with_properties');
        }
        const response = await this.client.request('/api/mass-create-objects-with-properties', { objects });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async deleteObject(instancePath) {
        if (!instancePath) {
            throw new Error('Instance path is required for delete_object');
        }
        const response = await this.client.request('/api/delete-object', { instancePath });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    // Smart Duplication Tools
    async smartDuplicate(instancePath, count, options) {
        if (!instancePath || count < 1) {
            throw new Error('Instance path and count > 0 are required for smart_duplicate');
        }
        const response = await this.client.request('/api/smart-duplicate', {
            instancePath,
            count,
            options
        });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async massDuplicate(duplications) {
        if (!duplications || duplications.length === 0) {
            throw new Error('Duplications array is required for mass_duplicate');
        }
        const response = await this.client.request('/api/mass-duplicate', { duplications });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    // Calculated Property Tools
    async setCalculatedProperty(paths, propertyName, formula, variables) {
        if (!paths || paths.length === 0 || !propertyName || !formula) {
            throw new Error('Paths, property name, and formula are required for set_calculated_property');
        }
        const response = await this.client.request('/api/set-calculated-property', {
            paths,
            propertyName,
            formula,
            variables
        });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    // Relative Property Tools
    async setRelativeProperty(paths, propertyName, operation, value, component // Vector3: X,Y,Z; UDim2: XScale, XOffset, YScale, YOffset
    ) {
        if (!paths || paths.length === 0 || !propertyName || !operation || value === undefined) {
            throw new Error('Paths, property name, operation, and value are required for set_relative_property');
        }
        const response = await this.client.request('/api/set-relative-property', {
            paths,
            propertyName,
            operation,
            value,
            component
        });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    // Script Management Tools
    async getScriptSource(instancePath, startLine, endLine) {
        if (!instancePath) {
            throw new Error('Instance path is required for get_script_source');
        }
        const response = await this.client.request('/api/get-script-source', { instancePath, startLine, endLine });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async setScriptSource(instancePath, source) {
        if (!instancePath || typeof source !== 'string') {
            throw new Error('Instance path and source code string are required for set_script_source');
        }
        const response = await this.client.request('/api/set-script-source', { instancePath, source });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    // Partial Script Editing Tools
    async editScriptLines(instancePath, startLine, endLine, newContent) {
        if (!instancePath || !startLine || !endLine || typeof newContent !== 'string') {
            throw new Error('Instance path, startLine, endLine, and newContent are required for edit_script_lines');
        }
        const response = await this.client.request('/api/edit-script-lines', { instancePath, startLine, endLine, newContent });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async insertScriptLines(instancePath, afterLine, newContent) {
        if (!instancePath || typeof newContent !== 'string') {
            throw new Error('Instance path and newContent are required for insert_script_lines');
        }
        const response = await this.client.request('/api/insert-script-lines', { instancePath, afterLine: afterLine || 0, newContent });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async deleteScriptLines(instancePath, startLine, endLine) {
        if (!instancePath || !startLine || !endLine) {
            throw new Error('Instance path, startLine, and endLine are required for delete_script_lines');
        }
        const response = await this.client.request('/api/delete-script-lines', { instancePath, startLine, endLine });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    // Attribute Tools
    async getAttribute(instancePath, attributeName) {
        if (!instancePath || !attributeName) {
            throw new Error('Instance path and attribute name are required for get_attribute');
        }
        const response = await this.client.request('/api/get-attribute', { instancePath, attributeName });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async setAttribute(instancePath, attributeName, attributeValue, valueType) {
        if (!instancePath || !attributeName) {
            throw new Error('Instance path and attribute name are required for set_attribute');
        }
        const response = await this.client.request('/api/set-attribute', { instancePath, attributeName, attributeValue, valueType });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async getAttributes(instancePath) {
        if (!instancePath) {
            throw new Error('Instance path is required for get_attributes');
        }
        const response = await this.client.request('/api/get-attributes', { instancePath });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async deleteAttribute(instancePath, attributeName) {
        if (!instancePath || !attributeName) {
            throw new Error('Instance path and attribute name are required for delete_attribute');
        }
        const response = await this.client.request('/api/delete-attribute', { instancePath, attributeName });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    // Tag Tools (CollectionService)
    async getTags(instancePath) {
        if (!instancePath) {
            throw new Error('Instance path is required for get_tags');
        }
        const response = await this.client.request('/api/get-tags', { instancePath });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async addTag(instancePath, tagName) {
        if (!instancePath || !tagName) {
            throw new Error('Instance path and tag name are required for add_tag');
        }
        const response = await this.client.request('/api/add-tag', { instancePath, tagName });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async removeTag(instancePath, tagName) {
        if (!instancePath || !tagName) {
            throw new Error('Instance path and tag name are required for remove_tag');
        }
        const response = await this.client.request('/api/remove-tag', { instancePath, tagName });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async getTagged(tagName) {
        if (!tagName) {
            throw new Error('Tag name is required for get_tagged');
        }
        const response = await this.client.request('/api/get-tagged', { tagName });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async getSelection() {
        const response = await this.client.request('/api/get-selection', {});
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
    async executeLuau(code) {
        if (!code) {
            throw new Error('Code is required for execute_luau');
        }
        const response = await this.client.request('/api/execute-luau', { code });
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(response, null, 2)
                }
            ]
        };
    }
}
//# sourceMappingURL=index.js.map