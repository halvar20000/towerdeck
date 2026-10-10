// Validates the app's GraphQL documents against the Unraid schema.
// Uses docs/unraid-schema.graphql, or – when UNRAID_URL and UNRAID_API_KEY are
// set – the live schema of that server via introspection.
// usage: dart run tool/dump_documents.dart > docs.json && node tool/validate_graphql.mjs docs.json
import { readFileSync } from 'node:fs';
import { buildClientSchema, buildSchema, getIntrospectionQuery, parse, validate } from 'graphql';

async function loadSchema() {
  const { UNRAID_URL: url, UNRAID_API_KEY: key } = process.env;
  if (url && key) {
    const res = await fetch(new URL('/graphql', url), {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-api-key': key },
      body: JSON.stringify({ query: getIntrospectionQuery() }),
    });
    const json = await res.json();
    if (!json.data) throw new Error(`Introspection failed: ${JSON.stringify(json.errors)}`);
    console.log(`Schema: live from ${url}`);
    return buildClientSchema(json.data);
  }
  console.log('Schema: docs/unraid-schema.graphql');
  return buildSchema(readFileSync(new URL('../docs/unraid-schema.graphql', import.meta.url), 'utf8'));
}

const schema = await loadSchema();
const docs = JSON.parse(readFileSync(process.argv[2], 'utf8'));
let failed = 0;
for (const { document } of docs) {
  const errors = validate(schema, parse(document));
  const name = document.trim().split('\n')[0].slice(0, 70);
  if (errors.length) {
    failed++;
    console.log(`FAIL ${name}\n  ${errors.map((e) => e.message).join('\n  ')}`);
  } else {
    console.log(`OK   ${name}`);
  }
}
console.log(`${docs.length - failed}/${docs.length} documents valid`);
process.exit(failed ? 1 : 0);
