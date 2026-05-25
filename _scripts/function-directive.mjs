const functionDirective = {
  name: 'funky',
  doc: 'A directive for a displayed function.',
  alias: ['function'],
  arg: {
    type: 'myst',
  },
  options: {
    enumerated: {
      type: 'boolean',
      default: true,
      doc: 'Whether the function is enumerated.',
    },
  },
  body: {
    type: 'myst',
    required: true,
  },
  run(data) {
    const children = [];
    if (data.arg) {
      children.push({
        type: 'admonitionTitle',
        children: data.arg,
      });
    }
    if (data.body) {
      children.push(...(data.body));
    }
    enumerated = true;
    const func = {
      type: 'function',
      kind: 'function',
      enumerated,
      children: children,
    };
    return [func];
  },
};

const plugin = { name: 'Function directive', directives: [functionDirective] };

export default plugin;
