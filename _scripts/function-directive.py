#!/usr/bin/env python3
import argparse
import json
import sys
import re


plugin = {
    "name": "Function Directive",
    "directives": [
        {
            "name": "function",
            "doc": "",
            "alias": ["function"],
            "arg": {
                "type": "myst",
            },
            "options": {
                
            },
        }
    ],
}


def declare_result(content):
    """Declare result as JSON to stdout

    :param content: content to declare as the result
    """

    # Format result and write to stdout
    json.dump(content, sys.stdout, indent=2)
    # Successfully exit
    raise SystemExit(0)


def run_directive(name, data):
    """Execute a directive with the given name and data

    :param name: name of the directive to run
    :param data: data of the directive to run
    """
    assert name == "function"

    name = data.get("arg")

    # Insert an image of a landscape
    func = []
    func.append({
        "type": "admonitionTitle",
        "children": name,
    })
    func.extend(data.get("body"))
    return func


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--role")
    group.add_argument("--directive")
    group.add_argument("--transform")
    args = parser.parse_args()

    if args.directive:
        data = json.load(sys.stdin)
        declare_result(run_directive(args.directive, data))
    elif args.transform:
        raise NotImplementedError
    elif args.role:
        raise NotImplementedError
    else:
        declare_result(plugin)
