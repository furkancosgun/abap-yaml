# abap-yaml

[![abaplint](https://img.shields.io/badge/abaplint-passing-brightgreen.svg)](https://abaplint.app)
[![Tests](https://img.shields.io/badge/tests-105%20passed-brightgreen.svg)]()
[![ABAP Release](https://img.shields.io/badge/ABAP-v702+-blue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

High-performance, production-ready YAML parser, serializer, and bidirectional data-binding engine for SAP ABAP (ABAP 7.02+ and Cloud).

Built following **SOLID** and **DRY** principles, featuring an AST-based parser architecture, unified document interface (`zif_ayaml`), high-speed secondary-indexed tree node storage, and 1-line bidirectional data binding.

---

## Table of Contents

- [✨ Features](#-features)
- [🚀 Quick Start](#-quick-start)
  - [1. Reading YAML](#1-reading-yaml)
  - [2. Writing & Constructing YAML](#2-writing--constructing-yaml)
  - [3. Bidirectional ABAP Data Binding](#3-bidirectional-abap-data-binding)
  - [4. Advanced Tree Operations](#4-advanced-tree-operations)
- [🌐 Real-World Specs Supported](#-real-world-specs-supported)
- [📚 API Reference](#-api-reference)
  - [Factory Methods (`zcl_ayaml`)](#factory-methods-zcl_ayaml)
  - [Document Interface (`zif_ayaml`)](#document-interface-zif_ayaml)
  - [Case Formatting Constants (`zif_ayaml_types`)](#case-formatting-constants-zif_ayaml_types)
- [📂 Architecture](#-architecture)
- [🧪 Testing & Quality Assurance](#-testing--quality-assurance)
- [📄 License](#-license)

---

## ✨ Features

- **AST-Based Architecture**: Complete YAML scanner & AST parser supporting nested mappings, sequences, block scalars (`|`, `>`), flow collections (`[1, 2]`, `{a: 1}`), anchors (`&anchor`), aliases (`*alias`), and merge keys (`<<: *defaults`).
- **High-Performance Storage**: Internal tree nodes stored in `SORTED TABLE` with secondary keys for $O(\log N)$ path/key lookups and traversals.
- **Unified Document Interface (`zif_ayaml`)**: Consistent API for querying, mutating, serializing, and deserializing YAML documents.
- **Null-Safe Typed Getters**: `get_string`, `get_integer`, `get_number`, `get_boolean`, `get_date`, `get_timestamp` with fallback defaults.
- **Programmatic Writer**: Full programmatic document construction with automatic parent path creation (`/a/b/c/d`), sequences (`init_array`, `push`), and indentation options.
- **Bidirectional 1-Line Data Binding**:
  - `create_from_abap(...)`: Structure or internal table $\rightarrow$ YAML document.
  - `to_abap(...)`: YAML $\rightarrow$ ABAP structure or internal table.
- **Intelligent Casing Conversion**: Convert ABAP fields to `camel_case`, `snake_case`, `lower_case`, or `upper_case` during serialization, with flexible case-insensitive matching during deserialization.
- **100% Tested**: Comprehensive test suite of **105 tests** covering unit operations, edge cases, writer serialization, and real-world production configurations.

---

## 🚀 Quick Start

### 1. Reading YAML

Parse any YAML string and read values safely:

```abap
DATA lv_yaml TYPE string.
DATA li_doc  TYPE REF TO zif_ayaml.

lv_yaml =
  |app:\n| &&
  |  name: 'Invoice Service'\n| &&
  |  port: 8080\n| &&
  |  enabled: true\n| &&
  |  timeout: 30.5\n| &&
  |  tags:\n| &&
  |    - billing\n| &&
  |    - sap|.

li_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).

" Typed getters with optional defaults
DATA(lv_name)    = li_doc->get_string( '/app/name' ).                     " 'Invoice Service'
DATA(lv_port)    = li_doc->get_integer( '/app/port' ).                    " 8080
DATA(lv_enabled) = li_doc->get_boolean( '/app/enabled' ).                 " abap_true
DATA(lv_timeout) = li_doc->get_number( '/app/timeout' ).                 " 30.5
DATA(lv_host)    = li_doc->get_string( iv_path    = '/app/host'
                                       iv_default = '127.0.0.1' ).        " Fallback default

" Sequence inspection
DATA(lv_tag_cnt) = li_doc->get_array_length( '/app/tags' ).              " 2
DATA(lv_tag1)    = li_doc->get_string( '/app/tags/1' ).                   " 'billing'
DATA(lt_tags)    = li_doc->get_string_table( '/app/tags' ).               " string_table

" Existence & keys
IF li_doc->exists( '/app' ) = abap_true.
  DATA(lt_keys) = li_doc->get_keys( '/app' ).                            " name, port, enabled...
ENDIF.
```

---

### 2. Writing & Constructing YAML

Construct a YAML document entirely from ABAP code:

```abap
DATA li_writer TYPE REF TO zif_ayaml.
DATA lv_yaml   TYPE string.

li_writer = zcl_ayaml=>create_empty( ).

" Auto-creates intermediate paths (/server)
li_writer->set_string( iv_path  = '/server/host'
                       iv_value = 'prod.api.internal' ).
li_writer->set_integer( iv_path  = '/server/port'
                        iv_value = 443 ).
li_writer->set_boolean( iv_path  = '/server/ssl'
                        iv_value = abap_true ).
li_writer->set_null( '/server/backup' ).

" Create and populate sequences
li_writer->init_array( '/server/regions' ).
li_writer->push( iv_path  = '/server/regions'
                 iv_value = 'eu-central-1' ).
li_writer->push( iv_path  = '/server/regions'
                 iv_value = 'us-east-1' ).

" Export to formatted YAML string (iv_indent = 1 or 2)
lv_yaml = li_writer->to_yaml( 1 ).
```

Output:
```yaml
server:
  host: prod.api.internal
  port: 443
  ssl: true
  backup: null
  regions:
    - eu-central-1
    - us-east-1
```

---

### 3. Bidirectional ABAP Data Binding

Map ABAP structures and tables directly to/from YAML with automatic field casing:

```abap
TYPES:
  BEGIN OF ty_s_service,
    service_name TYPE string,
    port_number  TYPE i,
    is_active    TYPE abap_bool,
  END OF ty_s_service,
  ty_t_services TYPE STANDARD TABLE OF ty_s_service WITH DEFAULT KEY.

DATA ls_input  TYPE ty_s_service.
DATA ls_output TYPE ty_s_service.
DATA lv_yaml   TYPE string.

ls_input-service_name = 'order-gateway'.
ls_input-port_number  = 9000.
ls_input-is_active    = abap_true.

" 1. ABAP Structure -> YAML with camelCase formatting
lv_yaml = zcl_ayaml=>create_from_abap(
  iv_data   = ls_input
  iv_format = zif_ayaml_types=>cs_format-camel_case )->to_yaml( 1 ).

" Output:
" serviceName: order-gateway
" portNumber: 9000
" isActive: true

" 2. YAML -> ABAP Structure
DATA(li_doc) = zcl_ayaml=>create_from_yaml( lv_yaml ).
li_doc->to_abap( IMPORTING ev_data = ls_output ).

" ls_output now contains identical data
```

---

### 4. Advanced Tree Operations

Manipulate, clone, and slice YAML document subtrees:

```abap
DATA li_doc   TYPE REF TO zif_ayaml.
DATA li_clone TYPE REF TO zif_ayaml.
DATA li_slice TYPE REF TO zif_ayaml.

li_doc = zcl_ayaml=>create_from_yaml( lv_yaml ).

" Safe deep cloning (mutations do not affect original)
li_clone = li_doc->clone( ).
li_clone->set_string( iv_path = '/app/version' iv_value = '2.0.0' ).

" Subtree extraction (slice becomes a standalone YAML document)
li_slice = li_doc->slice( '/server' ).
DATA(lv_server_yaml) = li_slice->to_yaml( 1 ).

" Node deletion
li_doc->delete( '/server/backup' ).

" Reset document
li_doc->clear( ).
```

---

## 🌐 Real-World Specs Supported

Tested and verified against complex real-world specifications in the test suite:

- **Kubernetes**: Deployment manifests, Pod specs, container ports, environment variables, Ingress routing.
- **Docker Compose**: Service definitions, port mappings, volumes, healthchecks, dependencies.
- **OpenAPI 3.0**: Endpoint definitions, HTTP request/response schemas, path parameters.
- **CI/CD Pipelines**: GitHub Actions workflows (`.github/workflows/ci.yml`), GitLab CI (`.gitlab-ci.yml`), Travis CI, Drone CI.
- **Monitoring & Observability**: Prometheus Alerting rules, Logstash pipeline configs.
- **Configuration Management**: Ansible playbooks, Helm `values.yaml`, Spring Boot `application.yml`, Elasticsearch configs, Serverless Framework manifests.
- **YAML 1.2 Features**: Block scalar chomping (`|-`, `|+`), multi-layer merge keys (`<<: *defaults`), and nested inline flow sequences/mappings.

---

## 📚 API Reference

### Factory Methods (`zcl_ayaml`)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `create_from_yaml` | `iv_yaml (string)` | `REF TO zif_ayaml` | Parses YAML string and returns document instance |
| `create_from_abap` | `iv_data (any)`, `iv_format (optional)` | `REF TO zif_ayaml` | Converts ABAP data into a YAML document |
| `create_empty` | *none* | `REF TO zif_ayaml` | Instantiates a new empty document for writing |

### Document Interface (`zif_ayaml`)

| Method | Parameters | Return / Export | Description |
|---|---|---|---|
| `get` | `iv_path`, `iv_default?` | `string` | Returns raw scalar value at path |
| `get_string` | `iv_path`, `iv_default?` | `string` | Safe string getter |
| `get_integer` | `iv_path`, `iv_default?` | `i` | Safe integer getter |
| `get_number` | `iv_path`, `iv_default?` | `f` | Safe floating point getter |
| `get_boolean` | `iv_path`, `iv_default?` | `abap_bool` | Safe boolean getter |
| `get_date` | `iv_path`, `iv_default?` | `d` | Safe date getter (`YYYYMMDD`) |
| `get_timestamp` | `iv_path`, `iv_default?` | `timestamp` | Safe timestamp getter |
| `get_keys` | `iv_path?` | `ty_t_string` | Returns list of child keys at path |
| `get_array_length`| `iv_path` | `i` | Returns count of items in sequence |
| `get_string_table`| `iv_path` | `string_table` | Returns sequence elements as string table |
| `exists` | `iv_path` | `abap_bool` | Checks if path exists |
| `is_empty` | *none* | `abap_bool` | Checks if document is empty |
| `set_string` | `iv_path`, `iv_value` | `REF TO zif_ayaml` | Sets string scalar at path |
| `set_integer` | `iv_path`, `iv_value` | `REF TO zif_ayaml` | Sets integer scalar at path |
| `set_number` | `iv_path`, `iv_value` | `REF TO zif_ayaml` | Sets float scalar at path |
| `set_boolean` | `iv_path`, `iv_value` | `REF TO zif_ayaml` | Sets boolean scalar at path |
| `set_date` | `iv_path`, `iv_value` | `REF TO zif_ayaml` | Sets date scalar at path |
| `set_null` | `iv_path` | `REF TO zif_ayaml` | Sets null node at path |
| `init_array` | `iv_path`, `iv_clear?` | `REF TO zif_ayaml` | Initializes a sequence node |
| `push` | `iv_path`, `iv_value` | `REF TO zif_ayaml` | Appends item to sequence |
| `delete` | `iv_path` | `REF TO zif_ayaml` | Removes node or subtree |
| `clear` | *none* | `REF TO zif_ayaml` | Removes all nodes from document |
| `slice` | `iv_path` | `REF TO zif_ayaml` | Extracts subtree as new document |
| `clone` | *none* | `REF TO zif_ayaml` | Deep copy of document |
| `to_yaml` | `iv_indent?` | `string` | Serializes document to YAML string |
| `to_abap` | `EXPORTING ev_data` | — | Deserializes document into ABAP data |

### Case Formatting Constants (`zif_ayaml_types`)

| Constant | Value | Result Example |
|---|---|---|
| `cs_format-camel_case` | `'camel_case'` | `serverHost` |
| `cs_format-snake_case` | `'snake_case'` | `server_host` |
| `cs_format-lower_case` | `'lower_case'` | `serverhost` |
| `cs_format-upper_case` | `'upper_case'` | `SERVERHOST` |

---

## 📂 Architecture

```
src/
├── zif_ayaml_types.intf.abap     # Type definitions, node structures & format constants
├── zif_ayaml.intf.abap           # Unified YAML document interface
├── zcl_ayaml_utils.clas.abap     # Path normalization, scalar detection & casing utils
├── zcx_ayaml_error.clas.abap     # Root exception class
└── zcl_ayaml.clas.abap           # Main API class
    ├── locals_def.abap           # AST node, scanner, parser & serializer definitions
    ├── locals_imp.abap           # Parser engine, recursive serializer & deserializer
    └── testclasses.abap          # 105 unit tests (specs, stress, writer & real-world)
```

---

## 🧪 Testing & Quality Assurance

The codebase is continuously validated using [abaplint](https://abaplint.app) and transpiled for automated execution via the [Open-ABAP](https://github.com/open-abap/open-abap-core) kernel.

### Run All Checks

```bash
npm test
```

### Run Linter & Unit Tests Individually

```bash
npm run lint    # Strict syntax & 702 compliance check with abaplint
npm run unit    # Transpile to JS and execute 105 unit tests
```

### Test Suites Included (105 Tests Total)

- `ltcl_ayaml_master_suite` (9 tests): Core types, null handling, readers, date/timestamp.
- `ltcl_ayaml_extended` (12 tests): Tree manipulation, path utils, array/struct touch.
- `ltcl_ayaml_advanced_parser` (6 tests): Indentation, block scalars, flow styles, merge keys.
- `ltcl_ayaml_new_architecture` (10 tests): `zif_ayaml` interface, ABAP data binding, casing.
- `ltcl_ayaml_comprehensive_suite` (8 tests): Empty/comment docs, special character scalars, 2D arrays.
- `ltcl_ayaml_stress_tests` (10 tests): Kubernetes manifests, URL scalars, chomping, syntax error assertions.
- `ltcl_ayaml_writer_suite` (25 tests): Comprehensive Writer testing, deep auto-paths, sequences, mutation, clone.
- `ltcl_ayaml_realworld_specs` (25 tests): Real-world production configs (Docker, K8s, OpenAPI, Helm, CI/CD) and end-to-end roundtrips.

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
