"""Hand-writes Metadata.appintents for the World Clock widget, standing in for Xcode's
appintentsmetadataprocessor. Field-for-field copy of the shape Apple's own
toolchain (27A200c) emits for Journal's StreaksWidgetConfigurationIntent.

    python3 -I scripts/make_metadata.py <appex>/Contents/Resources
"""
import json
import os
import sys

MODULE = "WorldClockWidget"
TOOLS_VERSION = "27A200c"  # match the system's own generator
# Must match @Parameter(default:) in Sources/WorldClockWidget/WorldClockWidget.swift.
DEFAULT_CITIES = "Denver, London, Sydney"


def mangled(type_name, kind):
    # Swift mangling for a top-level type: <len><module><len><type><V=struct|O=enum>
    return f"{len(MODULE)}{MODULE}{len(type_name)}{type_name}{kind}"


def text(value):
    # No .loctable shipped, so the key is the English string itself.
    return {"alternatives": [], "defaultValue": value, "key": value}


WILDCARD = {"LNPlatformNameWildcard": {"introducedVersion": "*"}}
VISIBLE = {"assistantOnly": False, "isDiscoverable": True}

intent_name = mangled("SelectCitiesIntent", "V")
select_city_intent = {
    "assistantDefinedSchemas": [],
    "assistantDefinedSchemaTraits": [],
    "authenticationPolicy": 0,
    "availabilityAnnotations": WILDCARD,
    "descriptionMetadata": {"descriptionText": text("Type cities separated by commas."),
                            "searchKeywords": []},
    "effectiveBundleIdentifiers": [],
    "fullyQualifiedTypeName": f"{MODULE}.SelectCitiesIntent",
    "identifier": "SelectCitiesIntent",
    "isAuthPolExplicit": False,
    "isDiscoverable": False,
    "mangledTypeName": intent_name,
    "mangledTypeNameByBundleIdentifier": {},
    "mangledTypeNameByBundleIdentifierV2": {},
    "mangledTypeNameV2": intent_name,
    "openAppWhenRun": False,
    "outputFlags": 8,
    "parameters": [{
        "capabilities": 1,
        "dynamicOptionsSupport": 0,
        "inputConnectionBehavior": 0,
        "isInput": False,
        "isOptional": False,
        "name": "cities",
        "resolvableInputTypes": [],
        "title": text("Cities"),
        "typeSpecificMetadata": ["LNValueTypeSpecificMetadataKeyDefaultValue",
                                 {"string": {"wrapper": DEFAULT_CITIES}}],
        # typeIdentifier 0 = String in Apple's metadata (Home.app targetIDString etc.)
        "valueType": {"primitive": {"wrapper": {"typeIdentifier": 0}}},
    }],
    "presentationStyle": 0,
    "requiredCapabilities": [],
    "supportedModes": 1,
    "systemProtocolMetadata": ["com.apple.link.systemProtocol.WidgetConfiguration", {"empty": {}}],
    "systemProtocolMetadataV2": ["com.apple.link.systemProtocol.WidgetConfiguration", {"empty": {}}],
    "systemProtocols": ["com.apple.link.systemProtocol.WidgetConfiguration"],
    "title": text("Choose Cities"),
    "typeSpecificMetadata": [],
    "visibilityMetadata": VISIBLE,
}

actionsdata = {
    "actions": {"SelectCitiesIntent": select_city_intent},
    "assistantEntities": [],
    "assistantIntentNegativePhrases": [],
    "assistantIntents": [],
    "autoShortcuts": [],
    "entities": {},
    "enums": [],
    "generator": {"name": "xcode-tools", "version": TOOLS_VERSION},
    "negativePhrases": [],
    "queries": {},
    "shortcutTileColor": 14,
    "version": 1,
}

out = os.path.join(sys.argv[1], "Metadata.appintents")
os.makedirs(out, exist_ok=True)
with open(os.path.join(out, "extract.actionsdata"), "w") as f:
    json.dump(actionsdata, f, indent=2, sort_keys=True)
with open(os.path.join(out, "version.json"), "w") as f:
    json.dump({"toolsVersion": TOOLS_VERSION, "version": "3.0"}, f, indent=2)
print(f"    wrote {out}")
