#!/usr/bin/env python3

import argparse
import json
import pathlib

BLANK_ICON_CODE = "\ue9fe"

def merge_templates(rm_templates: pathlib.Path, custom_templates: pathlib.Path):
  with open(rm_templates) as rm_templates_f:
    rm_templates_object = json.load(rm_templates_f)
    rm_templates = rm_templates_object["templates"]
    with open(custom_templates) as custom_templates_f:
        custom_templates = json.load(custom_templates_f)

        for custom_template in custom_templates:
            template_matched = False
            custom_template["iconCode"] = BLANK_ICON_CODE

            for rm_template in rm_templates:
                if rm_template["name"] == custom_template["name"]:
                   override_rm_template(rm_template, custom_template)
                   template_matched = True
                   continue

            if not template_matched:
               rm_templates.append(custom_template)
        
        return rm_templates_object

def override_rm_template(rm_template, custom_template):
    rm_template["filename"] = custom_template["filename"]
    rm_template["iconCode"] = custom_template["iconCode"]
    rm_template["categories"] = custom_template["categories"]

if __name__ == "__main__":
  parser = argparse.ArgumentParser()
  parser.add_argument("TEMPLATES_FROM_RM", help="Templates JSON from the Remarkable", type=pathlib.Path)
  parser.add_argument("TEMPLATES_TO_MERGE", help="Custom templates to include", type=pathlib.Path)
  args = parser.parse_args()

  output = merge_templates(args.TEMPLATES_FROM_RM, args.TEMPLATES_TO_MERGE)
  print(json.dumps(output, indent=2))