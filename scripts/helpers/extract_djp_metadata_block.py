#!/usr/bin/env python3

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as ET


NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
REL_NS = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"


def read_shared_strings(archive: ZipFile) -> list[str]:
    if "xl/sharedStrings.xml" not in archive.namelist():
        return []

    sst = ET.fromstring(archive.read("xl/sharedStrings.xml"))
    strings = []

    for si in sst.findall(f"{NS}si"):
        strings.append("".join(t.text or "" for t in si.iter() if t.tag == f"{NS}t"))

    return strings


def cell_value(cell: ET.Element, shared_strings: list[str]) -> str:
    value = cell.find(f"{NS}v")

    if value is None:
        inline = cell.find(f"{NS}is")
        if inline is None:
            return ""
        return "".join(t.text or "" for t in inline.iter() if t.tag == f"{NS}t")

    raw = value.text or ""
    if cell.attrib.get("t") == "s":
        return shared_strings[int(raw)]
    return raw


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: extract_djp_metadata_block.py <input.xlsx> <output.csv>", file=sys.stderr)
        return 1

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])

    with ZipFile(input_path) as archive:
        workbook = ET.fromstring(archive.read("xl/workbook.xml"))
        relationships = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
        shared_strings = read_shared_strings(archive)
        relmap = {
            rel.attrib["Id"]: rel.attrib["Target"]
            for rel in relationships
        }

        worksheet_target = None
        for sheet in workbook.find(f"{NS}sheets"):
            if sheet.attrib["name"] == "Sheet1":
                worksheet_target = "xl/" + relmap[sheet.attrib[f"{REL_NS}id"]]
                break

        if worksheet_target is None:
            raise RuntimeError("Could not find worksheet named 'Sheet1'")

        worksheet = ET.fromstring(archive.read(worksheet_target))

    rows = []

    for row in worksheet.find(f"{NS}sheetData").findall(f"{NS}row"):
        row_index = int(row.attrib["r"])
        values: dict[str, str] = {}

        for cell in row.findall(f"{NS}c"):
            col = re.match(r"[A-Z]+", cell.attrib["r"]).group(0)
            values[col] = cell_value(cell, shared_strings)

        rows.append([
            row_index,
            values.get("BU", ""),
            values.get("BV", ""),
            values.get("BW", ""),
            values.get("BX", ""),
            values.get("BY", ""),
            values.get("BZ", ""),
        ])

    with output_path.open("w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["row_index", "moon", "weather", "rain", "site", "tape", "pax"])
        writer.writerows(rows)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
