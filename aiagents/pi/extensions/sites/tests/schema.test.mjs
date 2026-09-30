import test from 'node:test';
import assert from 'node:assert/strict';
import { checkArguments } from '../src/client.ts';
import { code } from './helpers.mjs';
const object = field => ({ type: 'object', additionalProperties: false, required: ['value'], properties: { value: field } });
const valid = (schema, value) => assert.doesNotThrow(() => checkArguments(object(schema), { value }));
const invalid = (schema, value) => assert.throws(() => checkArguments(object(schema), { value }), code('schema_changed', 'invalid_arguments'));

test('schema: anyOf, oneOf, allOf and not distinguish valid alternatives', () => {
  valid({ anyOf: [{ type: 'string' }, { type: 'null' }] }, 'x'); valid({ anyOf: [{ type: 'string' }, { type: 'null' }] }, null);
  invalid({ anyOf: [{ type: 'string' }, { type: 'null' }] }, false);
  valid({ oneOf: [{ type: 'integer' }, { type: 'string' }] }, 1);
  invalid({ oneOf: [{ type: 'integer' }, { type: 'number' }] }, 1);
  valid({ allOf: [{ type: 'integer' }, { minimum: 1 }] }, 1); invalid({ allOf: [{ type: 'integer' }, { minimum: 1 }] }, 0);
  valid({ type: 'string', not: { const: 'public' } }, 'private'); invalid({ type: 'string', not: { const: 'public' } }, 'public');
});
test('schema: string length counts Unicode codepoints, not UTF-16 code units', () => { valid({ type: 'string', minLength: 1, maxLength: 1 }, '🚀'); invalid({ type: 'string', maxLength: 1 }, '🚀a'); });
test('schema: union types, number boundaries and multipleOf', () => {
  valid({ type: ['integer', 'null'] }, null); valid({ type: ['integer', 'null'] }, 2); invalid({ type: ['integer', 'null'] }, '2');
  valid({ type: 'number', exclusiveMinimum: 0, exclusiveMaximum: 1, multipleOf: 0.1 }, 0.3);
  for (const value of [0, 1, 0.35, Infinity, NaN]) invalid({ type: 'number', exclusiveMinimum: 0, exclusiveMaximum: 1, multipleOf: 0.1 }, value);
});
test('schema: nested object cardinality and schema-valued additionalProperties', () => { const s = { type: 'object', minProperties: 1, maxProperties: 2, additionalProperties: { type: 'integer' } }; valid(s, { a: 1, b: 2 }); for (const value of [{}, { a: 1, b: 2, c: 3 }, { a: 'bad' }]) invalid(s, value); });
test('schema: tuple prefixItems, false items, and deep uniqueItems', () => { const tuple = { type: 'array', prefixItems: [{ type: 'string' }, { type: 'integer' }], items: false }; valid(tuple, ['a', 1]); invalid(tuple, ['a', 1, true]); invalid(tuple, [1, 'a']); invalid({ type: 'array', uniqueItems: true }, [{ a: 1 }, { a: 1 }]); valid({ type: 'array', uniqueItems: true }, [{ a: 1 }, { a: 2 }]); });
test('schema: structured enum/const are compared deeply', () => { valid({ enum: [{ mode: 'private' }] }, { mode: 'private' }); invalid({ enum: [{ mode: 'private' }] }, { mode: 'public' }); valid({ const: ['a', 1] }, ['a', 1]); invalid({ const: ['a', 1] }, ['a', 2]); });
test('schema: optional unsupported reference also fails closed', () => { assert.throws(() => checkArguments({ type: 'object', properties: { later: { $ref: '#/unsupported' } } }, {}), code('schema_changed')); });
for (const field of [{ type: 'unsupported' }, { pattern: '[' }, { anyOf: 'bad' }, { unevaluatedProperties: false }]) test(`schema: malformed or unsupported constraint ${JSON.stringify(field)}`, () => { invalid(field, 'fixture'); });
test('schema: excessive schema nesting rejected before recursive matching', () => { let s = { type: 'string' }; for (let i = 0; i < 40; i++) s = { type: 'array', items: s }; invalid(s, []); });
test('schema: JSON object field __proto__ is not inherited schema authorization', () => { assert.throws(() => checkArguments({ type: 'object', properties: {}, additionalProperties: false }, JSON.parse('{"__proto__":{"polluted":true}}')), code('schema_changed', 'invalid_arguments')); assert.equal({}.polluted, undefined); });
