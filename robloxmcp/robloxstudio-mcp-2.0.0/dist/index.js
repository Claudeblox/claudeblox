#!/usr/bin/env node
/**
 * Roblox Studio MCP Server
 *
 * This server provides Model Context Protocol (MCP) tools for interacting with Roblox Studio.
 * It allows AI assistants to access Studio data, scripts, and objects through a bridge plugin.
 *
 * Usage:
 *   npx robloxstudio-mcp
 *
 * Or add to your MCP configuration:
 *   "robloxstudio": {
 *     "command": "npx",
 *     "args": ["-y", "robloxstudio-mcp"]
 *   }
 */
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ErrorCode, ListToolsRequestSchema, McpError, } from '@modelcontextprotocol/sdk/types.js';
import { createHttpServer } from './http-server.js';
import { RobloxStudioTools } from './tools/index.js';
import { BridgeService } from './bridge-service.js';
class RobloxStudioMCPServer {
    server;
    tools;
    bridge;
    constructor() {
        this.server = new Server({
            name: 'robloxstudio-mcp',
            version: '2.0.0',
        }, {
            capabilities: {
                tools: {},
            },
        });
        this.bridge = new BridgeService();
        this.tools = new RobloxStudioTools(this.bridge);
        this.setupToolHandlers();
    }
    setupToolHandlers() {
        this.server.setRequestHandler(ListToolsRequestSchema, async () => {
            return {
                tools: [
                    // Instance Hierarchy Tools (NOT local filesystem - these operate on Roblox Studio instances)
                    {
                        name: 'get_file_tree',
                        description: 'Get the Roblox instance hierarchy tree from Roblox Studio. Returns game instances (Parts, Scripts, Models, Folders, etc.) as a tree structure. NOTE: This operates on Roblox Studio instances, NOT local filesystem files.',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                path: {
                                    type: 'string',
                                    description: 'Roblox instance path to start from using dot notation (e.g., "game.Workspace", "game.ServerScriptService"). Defaults to game root if empty.',
                                    default: ''
                                }
                            }
                        }
                    },
                    {
                        name: 'search_files',
                        description: 'Search for Roblox instances by name, class type, or script content. NOTE: This searches Roblox Studio instances, NOT local filesystem files.',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                query: {
                                    type: 'string',
                                    description: 'Search query - instance name, class type (e.g., "Script", "Part"), or Lua code pattern'
                                },
                                searchType: {
                                    type: 'string',
                                    enum: ['name', 'type', 'content'],
                                    description: 'Type of search: "name" for instance names, "type" for class names, "content" for script source code',
                                    default: 'name'
                                }
                            },
                            required: ['query']
                        }
                    },
                    // Studio Context Tools
                    {
                        name: 'get_place_info',
                        description: 'Get place ID, name, and game settings',
                        inputSchema: {
                            type: 'object',
                            properties: {}
                        }
                    },
                    {
                        name: 'get_services',
                        description: 'Get available Roblox services and their children',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                serviceName: {
                                    type: 'string',
                                    description: 'Optional specific service name to query'
                                }
                            }
                        }
                    },
                    {
                        name: 'search_objects',
                        description: 'Find instances by name, class, or properties',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                query: {
                                    type: 'string',
                                    description: 'Search query'
                                },
                                searchType: {
                                    type: 'string',
                                    enum: ['name', 'class', 'property'],
                                    description: 'Type of search to perform',
                                    default: 'name'
                                },
                                propertyName: {
                                    type: 'string',
                                    description: 'Property name when searchType is "property"'
                                }
                            },
                            required: ['query']
                        }
                    },
                    // Property & Instance Tools
                    {
                        name: 'get_instance_properties',
                        description: 'Get all properties of a specific Roblox instance in Studio',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path using dot notation (e.g., "game.Workspace.Part", "game.ServerScriptService.MainScript", "game.ReplicatedStorage.ModuleScript")'
                                }
                            },
                            required: ['instancePath']
                        }
                    },
                    {
                        name: 'get_instance_children',
                        description: 'Get child instances and their class types from a Roblox parent instance',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path using dot notation (e.g., "game.Workspace", "game.ServerScriptService")'
                                }
                            },
                            required: ['instancePath']
                        }
                    },
                    {
                        name: 'search_by_property',
                        description: 'Find objects with specific property values',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                propertyName: {
                                    type: 'string',
                                    description: 'Name of the property to search'
                                },
                                propertyValue: {
                                    type: 'string',
                                    description: 'Value to search for'
                                }
                            },
                            required: ['propertyName', 'propertyValue']
                        }
                    },
                    {
                        name: 'get_class_info',
                        description: 'Get available properties/methods for Roblox classes',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                className: {
                                    type: 'string',
                                    description: 'Roblox class name'
                                }
                            },
                            required: ['className']
                        }
                    },
                    // Project Tools
                    {
                        name: 'get_project_structure',
                        description: 'Get complete game hierarchy. IMPORTANT: Use maxDepth parameter (default: 3) to explore deeper levels of the hierarchy. Set higher values like 5-10 for comprehensive exploration',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                path: {
                                    type: 'string',
                                    description: 'Optional path to start from (defaults to workspace root)',
                                    default: ''
                                },
                                maxDepth: {
                                    type: 'number',
                                    description: 'Maximum depth to traverse (default: 3). RECOMMENDED: Use 5-10 for thorough exploration. Higher values provide more complete structure',
                                    default: 3
                                },
                                scriptsOnly: {
                                    type: 'boolean',
                                    description: 'Show only scripts and script containers',
                                    default: false
                                }
                            }
                        }
                    },
                    // Property Modification Tools
                    {
                        name: 'set_property',
                        description: 'Set a property on any Roblox instance',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Path to the instance (e.g., "game.Workspace.Part")'
                                },
                                propertyName: {
                                    type: 'string',
                                    description: 'Name of the property to set'
                                },
                                propertyValue: {
                                    description: 'Value to set the property to (any type)'
                                }
                            },
                            required: ['instancePath', 'propertyName', 'propertyValue']
                        }
                    },
                    {
                        name: 'mass_set_property',
                        description: 'Set the same property on multiple instances at once',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                paths: {
                                    type: 'array',
                                    items: { type: 'string' },
                                    description: 'Array of instance paths to modify'
                                },
                                propertyName: {
                                    type: 'string',
                                    description: 'Name of the property to set'
                                },
                                propertyValue: {
                                    description: 'Value to set the property to (any type)'
                                }
                            },
                            required: ['paths', 'propertyName', 'propertyValue']
                        }
                    },
                    {
                        name: 'mass_get_property',
                        description: 'Get the same property from multiple instances at once',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                paths: {
                                    type: 'array',
                                    items: { type: 'string' },
                                    description: 'Array of instance paths to read from'
                                },
                                propertyName: {
                                    type: 'string',
                                    description: 'Name of the property to get'
                                }
                            },
                            required: ['paths', 'propertyName']
                        }
                    },
                    // Object Creation/Deletion Tools
                    {
                        name: 'create_object',
                        description: 'Create a new Roblox object instance (basic, without properties)',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                className: {
                                    type: 'string',
                                    description: 'Roblox class name (e.g., "Part", "Script", "Folder")'
                                },
                                parent: {
                                    type: 'string',
                                    description: 'Path to the parent instance (e.g., "game.Workspace")'
                                },
                                name: {
                                    type: 'string',
                                    description: 'Optional name for the new object'
                                }
                            },
                            required: ['className', 'parent']
                        }
                    },
                    {
                        name: 'create_object_with_properties',
                        description: 'Create a new Roblox object instance with initial properties',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                className: {
                                    type: 'string',
                                    description: 'Roblox class name (e.g., "Part", "Script", "Folder")'
                                },
                                parent: {
                                    type: 'string',
                                    description: 'Path to the parent instance (e.g., "game.Workspace")'
                                },
                                name: {
                                    type: 'string',
                                    description: 'Optional name for the new object'
                                },
                                properties: {
                                    type: 'object',
                                    description: 'Properties to set on creation'
                                }
                            },
                            required: ['className', 'parent']
                        }
                    },
                    {
                        name: 'mass_create_objects',
                        description: 'Create multiple objects at once (basic, without properties)',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                objects: {
                                    type: 'array',
                                    items: {
                                        type: 'object',
                                        properties: {
                                            className: {
                                                type: 'string',
                                                description: 'Roblox class name'
                                            },
                                            parent: {
                                                type: 'string',
                                                description: 'Path to the parent instance'
                                            },
                                            name: {
                                                type: 'string',
                                                description: 'Optional name for the object'
                                            }
                                        },
                                        required: ['className', 'parent']
                                    },
                                    description: 'Array of objects to create'
                                }
                            },
                            required: ['objects']
                        }
                    },
                    {
                        name: 'mass_create_objects_with_properties',
                        description: 'Create multiple objects at once with initial properties',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                objects: {
                                    type: 'array',
                                    items: {
                                        type: 'object',
                                        properties: {
                                            className: {
                                                type: 'string',
                                                description: 'Roblox class name'
                                            },
                                            parent: {
                                                type: 'string',
                                                description: 'Path to the parent instance'
                                            },
                                            name: {
                                                type: 'string',
                                                description: 'Optional name for the object'
                                            },
                                            properties: {
                                                type: 'object',
                                                description: 'Properties to set on creation'
                                            }
                                        },
                                        required: ['className', 'parent']
                                    },
                                    description: 'Array of objects to create with properties'
                                }
                            },
                            required: ['objects']
                        }
                    },
                    {
                        name: 'delete_object',
                        description: 'Delete a Roblox object instance',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Path to the instance to delete'
                                }
                            },
                            required: ['instancePath']
                        }
                    },
                    // Smart Duplication Tools
                    {
                        name: 'smart_duplicate',
                        description: 'Smart duplication with automatic naming, positioning, and property variations',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Path to the instance to duplicate'
                                },
                                count: {
                                    type: 'number',
                                    description: 'Number of duplicates to create'
                                },
                                options: {
                                    type: 'object',
                                    properties: {
                                        namePattern: {
                                            type: 'string',
                                            description: 'Name pattern with {n} placeholder (e.g., "Button{n}")'
                                        },
                                        positionOffset: {
                                            type: 'array',
                                            items: { type: 'number' },
                                            minItems: 3,
                                            maxItems: 3,
                                            description: 'X, Y, Z offset per duplicate'
                                        },
                                        rotationOffset: {
                                            type: 'array',
                                            items: { type: 'number' },
                                            minItems: 3,
                                            maxItems: 3,
                                            description: 'X, Y, Z rotation offset per duplicate'
                                        },
                                        scaleOffset: {
                                            type: 'array',
                                            items: { type: 'number' },
                                            minItems: 3,
                                            maxItems: 3,
                                            description: 'X, Y, Z scale multiplier per duplicate'
                                        },
                                        propertyVariations: {
                                            type: 'object',
                                            description: 'Property name to array of values'
                                        },
                                        targetParents: {
                                            type: 'array',
                                            items: { type: 'string' },
                                            description: 'Different parent for each duplicate'
                                        }
                                    }
                                }
                            },
                            required: ['instancePath', 'count']
                        }
                    },
                    {
                        name: 'mass_duplicate',
                        description: 'Perform multiple smart duplications at once',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                duplications: {
                                    type: 'array',
                                    items: {
                                        type: 'object',
                                        properties: {
                                            instancePath: {
                                                type: 'string',
                                                description: 'Path to the instance to duplicate'
                                            },
                                            count: {
                                                type: 'number',
                                                description: 'Number of duplicates to create'
                                            },
                                            options: {
                                                type: 'object',
                                                properties: {
                                                    namePattern: {
                                                        type: 'string',
                                                        description: 'Name pattern with {n} placeholder'
                                                    },
                                                    positionOffset: {
                                                        type: 'array',
                                                        items: { type: 'number' },
                                                        minItems: 3,
                                                        maxItems: 3,
                                                        description: 'X, Y, Z offset per duplicate'
                                                    },
                                                    rotationOffset: {
                                                        type: 'array',
                                                        items: { type: 'number' },
                                                        minItems: 3,
                                                        maxItems: 3,
                                                        description: 'X, Y, Z rotation offset per duplicate'
                                                    },
                                                    scaleOffset: {
                                                        type: 'array',
                                                        items: { type: 'number' },
                                                        minItems: 3,
                                                        maxItems: 3,
                                                        description: 'X, Y, Z scale multiplier per duplicate'
                                                    },
                                                    propertyVariations: {
                                                        type: 'object',
                                                        description: 'Property name to array of values'
                                                    },
                                                    targetParents: {
                                                        type: 'array',
                                                        items: { type: 'string' },
                                                        description: 'Different parent for each duplicate'
                                                    }
                                                }
                                            }
                                        },
                                        required: ['instancePath', 'count']
                                    },
                                    description: 'Array of duplication operations'
                                }
                            },
                            required: ['duplications']
                        }
                    },
                    // Calculated Property Tools
                    {
                        name: 'set_calculated_property',
                        description: 'Set properties using mathematical formulas and variables',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                paths: {
                                    type: 'array',
                                    items: { type: 'string' },
                                    description: 'Array of instance paths to modify'
                                },
                                propertyName: {
                                    type: 'string',
                                    description: 'Name of the property to set'
                                },
                                formula: {
                                    type: 'string',
                                    description: 'Mathematical formula (e.g., "Position.magnitude * 2", "index * 50")'
                                },
                                variables: {
                                    type: 'object',
                                    description: 'Additional variables for the formula'
                                }
                            },
                            required: ['paths', 'propertyName', 'formula']
                        }
                    },
                    // Relative Property Tools
                    {
                        name: 'set_relative_property',
                        description: 'Modify properties relative to their current values',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                paths: {
                                    type: 'array',
                                    items: { type: 'string' },
                                    description: 'Array of instance paths to modify'
                                },
                                propertyName: {
                                    type: 'string',
                                    description: 'Name of the property to modify'
                                },
                                operation: {
                                    type: 'string',
                                    enum: ['add', 'multiply', 'divide', 'subtract', 'power'],
                                    description: 'Mathematical operation to perform'
                                },
                                value: {
                                    description: 'Value to use in the operation'
                                },
                                component: {
                                    type: 'string',
                                    enum: ['X', 'Y', 'Z', 'XScale', 'XOffset', 'YScale', 'YOffset'],
                                    description: 'For Vector3: X, Y, Z. For UDim2: XScale, XOffset, YScale, YOffset (value must be a number)'
                                }
                            },
                            required: ['paths', 'propertyName', 'operation', 'value']
                        }
                    },
                    // Script Management Tools (for Roblox Studio scripts - NOT local files)
                    {
                        name: 'get_script_source',
                        description: 'Get the source code of a Roblox script (LocalScript, Script, or ModuleScript). Returns both "source" (raw code) and "numberedSource" (with line numbers prefixed like "1: code"). Use numberedSource to accurately identify line numbers for editing. For large scripts (>1500 lines), use startLine/endLine to read specific sections.',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path to the script using dot notation (e.g., "game.ServerScriptService.MainScript", "game.StarterPlayer.StarterPlayerScripts.LocalScript")'
                                },
                                startLine: {
                                    type: 'number',
                                    description: 'Optional: Start line number (1-indexed). Use for reading specific sections of large scripts.'
                                },
                                endLine: {
                                    type: 'number',
                                    description: 'Optional: End line number (inclusive). Use for reading specific sections of large scripts.'
                                }
                            },
                            required: ['instancePath']
                        }
                    },
                    {
                        name: 'set_script_source',
                        description: 'Replace the entire source code of a Roblox script. Uses ScriptEditorService:UpdateSourceAsync (works with open editors). For partial edits, prefer edit_script_lines, insert_script_lines, or delete_script_lines.',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path to the script (e.g., "game.ServerScriptService.MainScript")'
                                },
                                source: {
                                    type: 'string',
                                    description: 'New source code for the script'
                                }
                            },
                            required: ['instancePath', 'source']
                        }
                    },
                    // Partial Script Editing Tools - use "numberedSource" from get_script_source to identify correct line numbers
                    {
                        name: 'edit_script_lines',
                        description: 'Replace specific lines in a Roblox script without rewriting the entire source. IMPORTANT: Use the "numberedSource" field from get_script_source to identify the correct line numbers. Lines are 1-indexed and ranges are inclusive.',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path to the script (e.g., "game.ServerScriptService.MainScript")'
                                },
                                startLine: {
                                    type: 'number',
                                    description: 'First line to replace (1-indexed). Get this from the "numberedSource" field.'
                                },
                                endLine: {
                                    type: 'number',
                                    description: 'Last line to replace (inclusive). Get this from the "numberedSource" field.'
                                },
                                newContent: {
                                    type: 'string',
                                    description: 'New content to replace the specified lines (can be multiple lines separated by newlines)'
                                }
                            },
                            required: ['instancePath', 'startLine', 'endLine', 'newContent']
                        }
                    },
                    {
                        name: 'insert_script_lines',
                        description: 'Insert new lines into a Roblox script at a specific position. IMPORTANT: Use the "numberedSource" field from get_script_source to identify the correct line numbers.',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path to the script (e.g., "game.ServerScriptService.MainScript")'
                                },
                                afterLine: {
                                    type: 'number',
                                    description: 'Insert after this line number (0 = insert at very beginning, 1 = after first line). Get line numbers from "numberedSource".',
                                    default: 0
                                },
                                newContent: {
                                    type: 'string',
                                    description: 'Content to insert (can be multiple lines separated by newlines)'
                                }
                            },
                            required: ['instancePath', 'newContent']
                        }
                    },
                    {
                        name: 'delete_script_lines',
                        description: 'Delete specific lines from a Roblox script. IMPORTANT: Use the "numberedSource" field from get_script_source to identify the correct line numbers.',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path to the script (e.g., "game.ServerScriptService.MainScript")'
                                },
                                startLine: {
                                    type: 'number',
                                    description: 'First line to delete (1-indexed). Get this from the "numberedSource" field.'
                                },
                                endLine: {
                                    type: 'number',
                                    description: 'Last line to delete (inclusive). Get this from the "numberedSource" field.'
                                }
                            },
                            required: ['instancePath', 'startLine', 'endLine']
                        }
                    },
                    // Attribute Tools (for Roblox instance attributes)
                    {
                        name: 'get_attribute',
                        description: 'Get a single attribute value from a Roblox instance',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path using dot notation (e.g., "game.Workspace.Part", "game.ServerStorage.DataStore")'
                                },
                                attributeName: {
                                    type: 'string',
                                    description: 'Name of the attribute to get'
                                }
                            },
                            required: ['instancePath', 'attributeName']
                        }
                    },
                    {
                        name: 'set_attribute',
                        description: 'Set an attribute value on a Roblox instance. Supports string, number, boolean, Vector3, Color3, UDim2, and BrickColor.',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path using dot notation (e.g., "game.Workspace.Part")'
                                },
                                attributeName: {
                                    type: 'string',
                                    description: 'Name of the attribute to set'
                                },
                                attributeValue: {
                                    description: 'Value to set. For Vector3: {X, Y, Z}, Color3: {R, G, B}, UDim2: {X: {Scale, Offset}, Y: {Scale, Offset}}'
                                },
                                valueType: {
                                    type: 'string',
                                    description: 'Optional type hint: "Vector3", "Color3", "UDim2", "BrickColor"'
                                }
                            },
                            required: ['instancePath', 'attributeName', 'attributeValue']
                        }
                    },
                    {
                        name: 'get_attributes',
                        description: 'Get all attributes on a Roblox instance',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path using dot notation (e.g., "game.Workspace.Part")'
                                }
                            },
                            required: ['instancePath']
                        }
                    },
                    {
                        name: 'delete_attribute',
                        description: 'Delete an attribute from a Roblox instance',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path using dot notation (e.g., "game.Workspace.Part")'
                                },
                                attributeName: {
                                    type: 'string',
                                    description: 'Name of the attribute to delete'
                                }
                            },
                            required: ['instancePath', 'attributeName']
                        }
                    },
                    // Tag Tools (CollectionService) - for Roblox instance tags
                    {
                        name: 'get_tags',
                        description: 'Get all CollectionService tags on a Roblox instance',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path using dot notation (e.g., "game.Workspace.Part")'
                                }
                            },
                            required: ['instancePath']
                        }
                    },
                    {
                        name: 'add_tag',
                        description: 'Add a CollectionService tag to a Roblox instance',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path using dot notation (e.g., "game.Workspace.Part")'
                                },
                                tagName: {
                                    type: 'string',
                                    description: 'Name of the tag to add'
                                }
                            },
                            required: ['instancePath', 'tagName']
                        }
                    },
                    {
                        name: 'remove_tag',
                        description: 'Remove a CollectionService tag from a Roblox instance',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                instancePath: {
                                    type: 'string',
                                    description: 'Roblox instance path using dot notation (e.g., "game.Workspace.Part")'
                                },
                                tagName: {
                                    type: 'string',
                                    description: 'Name of the tag to remove'
                                }
                            },
                            required: ['instancePath', 'tagName']
                        }
                    },
                    {
                        name: 'get_tagged',
                        description: 'Get all instances with a specific tag',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                tagName: {
                                    type: 'string',
                                    description: 'Name of the tag to search for'
                                }
                            },
                            required: ['tagName']
                        }
                    },
                    {
                        name: 'get_selection',
                        description: 'Get all currently selected objects',
                        inputSchema: {
                            type: 'object',
                            properties: {}
                        }
                    },
                    {
                        name: 'execute_luau',
                        description: 'Execute arbitrary Luau code in Roblox Studio and return the result. The code runs in the plugin context with access to game, workspace, and all services. Use print() or warn() to produce output. The return value of the code (if any) is captured. Useful for querying game state, running one-off operations, or testing logic.',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                code: {
                                    type: 'string',
                                    description: 'Luau code to execute. Can use print() for output. The return value is captured.'
                                }
                            },
                            required: ['code']
                        }
                    }
                ]
            };
        });
        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params;
            try {
                switch (name) {
                    // File System Tools
                    case 'get_file_tree':
                        return await this.tools.getFileTree(args?.path || '');
                    case 'search_files':
                        return await this.tools.searchFiles(args?.query, args?.searchType || 'name');
                    // Studio Context Tools
                    case 'get_place_info':
                        return await this.tools.getPlaceInfo();
                    case 'get_services':
                        return await this.tools.getServices(args?.serviceName);
                    case 'search_objects':
                        return await this.tools.searchObjects(args?.query, args?.searchType || 'name', args?.propertyName);
                    // Property & Instance Tools
                    case 'get_instance_properties':
                        return await this.tools.getInstanceProperties(args?.instancePath);
                    case 'get_instance_children':
                        return await this.tools.getInstanceChildren(args?.instancePath);
                    case 'search_by_property':
                        return await this.tools.searchByProperty(args?.propertyName, args?.propertyValue);
                    case 'get_class_info':
                        return await this.tools.getClassInfo(args?.className);
                    // Project Tools
                    case 'get_project_structure':
                        return await this.tools.getProjectStructure(args?.path, args?.maxDepth, args?.scriptsOnly);
                    // Property Modification Tools
                    case 'set_property':
                        return await this.tools.setProperty(args?.instancePath, args?.propertyName, args?.propertyValue);
                    // Mass Property Tools
                    case 'mass_set_property':
                        return await this.tools.massSetProperty(args?.paths, args?.propertyName, args?.propertyValue);
                    case 'mass_get_property':
                        return await this.tools.massGetProperty(args?.paths, args?.propertyName);
                    // Object Creation/Deletion Tools
                    case 'create_object':
                        return await this.tools.createObject(args?.className, args?.parent, args?.name);
                    case 'create_object_with_properties':
                        return await this.tools.createObjectWithProperties(args?.className, args?.parent, args?.name, args?.properties);
                    case 'mass_create_objects':
                        return await this.tools.massCreateObjects(args?.objects);
                    case 'mass_create_objects_with_properties':
                        return await this.tools.massCreateObjectsWithProperties(args?.objects);
                    case 'delete_object':
                        return await this.tools.deleteObject(args?.instancePath);
                    // Smart Duplication Tools
                    case 'smart_duplicate':
                        return await this.tools.smartDuplicate(args?.instancePath, args?.count, args?.options);
                    case 'mass_duplicate':
                        return await this.tools.massDuplicate(args?.duplications);
                    // Calculated Property Tools
                    case 'set_calculated_property':
                        return await this.tools.setCalculatedProperty(args?.paths, args?.propertyName, args?.formula, args?.variables);
                    // Relative Property Tools
                    case 'set_relative_property':
                        return await this.tools.setRelativeProperty(args?.paths, args?.propertyName, args?.operation, args?.value, args?.component);
                    // Script Management Tools
                    case 'get_script_source':
                        return await this.tools.getScriptSource(args?.instancePath, args?.startLine, args?.endLine);
                    case 'set_script_source':
                        return await this.tools.setScriptSource(args?.instancePath, args?.source);
                    // Partial Script Editing Tools
                    case 'edit_script_lines':
                        return await this.tools.editScriptLines(args?.instancePath, args?.startLine, args?.endLine, args?.newContent);
                    case 'insert_script_lines':
                        return await this.tools.insertScriptLines(args?.instancePath, args?.afterLine, args?.newContent);
                    case 'delete_script_lines':
                        return await this.tools.deleteScriptLines(args?.instancePath, args?.startLine, args?.endLine);
                    // Attribute Tools
                    case 'get_attribute':
                        return await this.tools.getAttribute(args?.instancePath, args?.attributeName);
                    case 'set_attribute':
                        return await this.tools.setAttribute(args?.instancePath, args?.attributeName, args?.attributeValue, args?.valueType);
                    case 'get_attributes':
                        return await this.tools.getAttributes(args?.instancePath);
                    case 'delete_attribute':
                        return await this.tools.deleteAttribute(args?.instancePath, args?.attributeName);
                    // Tag Tools (CollectionService)
                    case 'get_tags':
                        return await this.tools.getTags(args?.instancePath);
                    case 'add_tag':
                        return await this.tools.addTag(args?.instancePath, args?.tagName);
                    case 'remove_tag':
                        return await this.tools.removeTag(args?.instancePath, args?.tagName);
                    case 'get_tagged':
                        return await this.tools.getTagged(args?.tagName);
                    // Selection Tools
                    case 'get_selection':
                        return await this.tools.getSelection();
                    // Execute Luau
                    case 'execute_luau':
                        return await this.tools.executeLuau(args?.code);
                    default:
                        throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${name}`);
                }
            }
            catch (error) {
                throw new McpError(ErrorCode.InternalError, `Tool execution failed: ${error instanceof Error ? error.message : String(error)}`);
            }
        });
    }
    async run() {
        const basePort = process.env.ROBLOX_STUDIO_PORT ? parseInt(process.env.ROBLOX_STUDIO_PORT) : 58741;
        const maxPort = basePort + 4; // Up to 5 simultaneous agents
        const host = process.env.ROBLOX_STUDIO_HOST || '0.0.0.0';
        const httpServer = createHttpServer(this.tools, this.bridge);
        let boundPort = 0;
        for (let port = basePort; port <= maxPort; port++) {
            try {
                await new Promise((resolve, reject) => {
                    const onError = (err) => {
                        if (err.code === 'EADDRINUSE') {
                            httpServer.removeListener('error', onError);
                            reject(err);
                        }
                        else {
                            reject(err);
                        }
                    };
                    httpServer.once('error', onError);
                    httpServer.listen(port, host, () => {
                        httpServer.removeListener('error', onError);
                        boundPort = port;
                        console.error(`HTTP server listening on ${host}:${port} for Studio plugin`);
                        resolve();
                    });
                });
                break; // Successfully bound
            }
            catch (err) {
                if (err.code === 'EADDRINUSE') {
                    console.error(`Port ${port} in use, trying next...`);
                    if (port === maxPort) {
                        throw new Error(`All ports ${basePort}-${maxPort} are in use. Stop some MCP server instances and retry.`);
                    }
                    continue;
                }
                throw err;
            }
        }
        // Legacy port support: old plugins (pre-1.9) connect on 3002.
        // Spin up the same handler on that port so they still work.
        const LEGACY_PORT = 3002;
        if (boundPort !== LEGACY_PORT) {
            const legacyServer = createHttpServer(this.tools, this.bridge);
            try {
                await new Promise((resolve, reject) => {
                    const onError = (err) => {
                        if (err.code === 'EADDRINUSE') {
                            legacyServer.removeListener('error', onError);
                            reject(err);
                        }
                        else {
                            reject(err);
                        }
                    };
                    legacyServer.once('error', onError);
                    legacyServer.listen(LEGACY_PORT, host, () => {
                        legacyServer.removeListener('error', onError);
                        console.error(`Legacy HTTP server also listening on ${host}:${LEGACY_PORT} for old plugins`);
                        resolve();
                    });
                });
                // Keep legacy server's MCP state in sync below
                legacyServer.setMCPServerActive(true);
            }
            catch {
                // Port 3002 taken — that's fine, just skip legacy support
                console.error(`Legacy port ${LEGACY_PORT} in use, skipping backward-compat listener`);
            }
        }
        const transport = new StdioServerTransport();
        await this.server.connect(transport);
        console.error('Roblox Studio MCP server running on stdio');
        httpServer.setMCPServerActive(true);
        console.error('MCP server marked as active');
        console.error('Waiting for Studio plugin to connect...');
        setInterval(() => {
            const pluginConnected = httpServer.isPluginConnected();
            const mcpActive = httpServer.isMCPServerActive();
            if (pluginConnected && mcpActive) {
            }
            else if (pluginConnected && !mcpActive) {
                console.error('Studio plugin connected, but MCP server inactive');
            }
            else if (!pluginConnected && mcpActive) {
                console.error('MCP server active, waiting for Studio plugin...');
            }
            else {
                console.error('Waiting for connections...');
            }
        }, 5000);
        setInterval(() => {
            this.bridge.cleanupOldRequests();
        }, 5000);
    }
}
const server = new RobloxStudioMCPServer();
server.run().catch((error) => {
    console.error('Server failed to start:', error);
    process.exit(1);
});
//# sourceMappingURL=index.js.map