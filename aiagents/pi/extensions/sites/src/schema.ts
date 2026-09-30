import { isDeepStrictEqual } from 'node:util';
import { SitesError } from './security.ts';
import type { Json } from './types.ts';

const supported = new Set(['type', 'properties', 'required', 'additionalProperties', 'items', 'prefixItems', 'minItems', 'maxItems', 'uniqueItems', 'minProperties', 'maxProperties', 'minLength', 'maxLength', 'pattern', 'minimum', 'maximum', 'exclusiveMinimum', 'exclusiveMaximum', 'multipleOf', 'enum', 'const', 'anyOf', 'oneOf', 'allOf', 'not', 'title', 'description', 'default', 'examples', 'deprecated', 'readOnly', 'writeOnly', 'format', '$schema', '$id', '$comment']);
const types = new Set(['object', 'array', 'string', 'integer', 'number', 'boolean', 'null']);

function inspect(schema: any, depth = 0) {
  if (depth > 30) throw new SitesError('schema_changed', 'Sites 인자 스키마가 너무 깊어.');
  if (typeof schema === 'boolean') return;
  if (!schema || typeof schema !== 'object' || Array.isArray(schema)) throw new SitesError('schema_changed', 'Sites 인자 스키마가 유효하지 않아.');
  for (const key of Object.keys(schema)) if (!supported.has(key) && !key.startsWith('x-')) throw new SitesError('schema_changed', '지원하지 않는 Sites 인자 스키마 제약이 추가됐어.');
  for (const kind of schema.type === undefined ? [] : Array.isArray(schema.type) ? schema.type : [schema.type]) if (!types.has(kind)) throw new SitesError('schema_changed', 'Sites 인자 스키마의 타입이 지원되지 않아.');
  for (const child of Object.values(schema.properties ?? {})) inspect(child, depth + 1);
  for (const key of ['anyOf', 'oneOf', 'allOf', 'prefixItems']) if (schema[key]) {
    if (!Array.isArray(schema[key])) throw new SitesError('schema_changed', 'Sites 인자 스키마의 분기 형식이 잘못됐어.');
    for (const child of schema[key]) inspect(child, depth + 1);
  }
  for (const key of ['items', 'additionalProperties', 'not']) if (schema[key] !== undefined) inspect(schema[key], depth + 1);
  if (schema.pattern !== undefined) try { new RegExp(schema.pattern, 'u'); } catch { throw new SitesError('schema_changed', 'Sites 문자열 검사 규칙을 읽지 못했어.'); }
}
function kindMatches(type: string, value: any) {
  if (type === 'null') return value === null;
  if (type === 'array') return Array.isArray(value);
  if (type === 'object') return value !== null && typeof value === 'object' && !Array.isArray(value);
  if (type === 'number') return typeof value === 'number' && Number.isFinite(value);
  if (type === 'integer') return typeof value === 'number' && Number.isInteger(value);
  return typeof value === type;
}
function matches(schema: any, value: any): boolean {
  if (typeof schema === 'boolean') return schema;
  if (schema.type && !(Array.isArray(schema.type) ? schema.type : [schema.type]).some((type: string) => kindMatches(type, value))) return false;
  if ('const' in schema && !isDeepStrictEqual(schema.const, value)) return false;
  if (schema.enum && !schema.enum.some((entry: any) => isDeepStrictEqual(entry, value))) return false;
  if (schema.anyOf && !schema.anyOf.some((child: any) => matches(child, value))) return false;
  if (schema.oneOf && schema.oneOf.filter((child: any) => matches(child, value)).length !== 1) return false;
  if (schema.allOf && !schema.allOf.every((child: any) => matches(child, value))) return false;
  if (schema.not && matches(schema.not, value)) return false;
  if (typeof value === 'number') {
    if (!Number.isFinite(value) || schema.minimum !== undefined && value < schema.minimum || schema.maximum !== undefined && value > schema.maximum || schema.exclusiveMinimum !== undefined && value <= schema.exclusiveMinimum || schema.exclusiveMaximum !== undefined && value >= schema.exclusiveMaximum) return false;
    if (schema.multipleOf !== undefined && (!Number.isFinite(schema.multipleOf) || schema.multipleOf <= 0 || Math.abs(value / schema.multipleOf - Math.round(value / schema.multipleOf)) > 1e-10)) return false;
  }
  if (typeof value === 'string' && (schema.minLength !== undefined && [...value].length < schema.minLength || schema.maxLength !== undefined && [...value].length > schema.maxLength || schema.pattern !== undefined && !new RegExp(schema.pattern, 'u').test(value))) return false;
  if (Array.isArray(value)) {
    if (schema.minItems !== undefined && value.length < schema.minItems || schema.maxItems !== undefined && value.length > schema.maxItems) return false;
    if (schema.uniqueItems && value.some((entry, i) => value.slice(0, i).some(other => isDeepStrictEqual(entry, other)))) return false;
    for (let i = 0; i < value.length; i++) {
      const child = schema.prefixItems?.[i] ?? schema.items;
      if (child !== undefined && !matches(child, value[i])) return false;
    }
  }
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    const keys = Object.keys(value);
    if (schema.minProperties !== undefined && keys.length < schema.minProperties || schema.maxProperties !== undefined && keys.length > schema.maxProperties || (schema.required ?? []).some((key: string) => !Object.hasOwn(value, key))) return false;
    for (const key of keys) {
      if (Object.hasOwn(schema.properties ?? {}, key)) { if (!matches(schema.properties[key], value[key])) return false; }
      else if (schema.additionalProperties !== undefined && !matches(schema.additionalProperties, value[key])) return false;
    }
  }
  return true;
}
export function validateSchema(schema: Json, value: unknown) {
  inspect(schema);
  if (!matches(schema, value)) throw new SitesError('invalid_arguments', '요청 인자의 타입·범위가 현재 Sites 스키마와 맞지 않아.');
}
