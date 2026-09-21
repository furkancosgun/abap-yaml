# abap-yaml

High-performance, modern YAML parser, serializer, and bidirectional data-binding engine for ABAP.

Built following **SOLID** and **DRY** principles, featuring an AST-based parser architecture, interface segregation (`zif_ayaml_reader` / `zif_ayaml_writer`), and direct ABAP-to-YAML / YAML-to-ABAP mapping with case conversion.

---

## ✨ Features

- **AST-Based Parser**: Full YAML scanner & AST parser supporting nested mappings, sequences, block scalars (`|`, `>`), flow sequences/mappings (`[1, 2]`, `{a: 1}`), inline comments, anchors (`&anchor`), and aliases (`*alias`).
- **Zero-Comments Self-Documenting Code**: Clean, intention-revealing code with 100% test coverage.
- **High-Performance Storage**: Tree nodes stored in a `SORTED TABLE` with secondary keys for $O(\log N)$ path/key lookups.
- **Interface Segregation**:
  - `zif_ayaml_reader`: Read-only queries, safe typing, path navigation, default fallbacks.
  - `zif_ayaml_writer`: Mutation methods (`set*`, `delete`, `clear`, `ensure_sequence`, `append_to_sequence`).
  - `zif_ayaml`: Combines reader and writer capabilities.
- **Bidirectional 1-Line Data Binding**:
  - `zcl_ayaml=>from_abap(...)`: Structure or internal table $\rightarrow$ formatted YAML string.
  - `to_abap( ... )`: YAML $\rightarrow$ ABAP structure or internal table.
- **Flexible Field Formatting**:
  - `camel_case` (`firstName`)
  - `snake_case` (`first_name`)
  - `lower_case` (`firstname`)
  - `upper_case` (`FIRSTNAME`)
  - Intelligent case-insensitive and pattern matching during deserialization.

---

## 🚀 Quick Start

### 1. Serialize ABAP to YAML

```abap
TYPES: BEGIN OF ty_s_config,
         server_host TYPE string,
         server_port TYPE i,
         is_secured  TYPE abap_bool,
       END OF ty_s_config.

DATA ls_config TYPE ty_s_config.
ls_config-server_host = 'api.internal'.
ls_config-server_port = 443.
ls_config-is_secured  = abap_true.

" Serialize with camelCase field naming
DATA(lv_yaml) = zcl_ayaml=>from_abap(
  iv_data   = ls_config
  iv_format = zif_ayaml_types=>cs_format-camel_case ).
```

Output:
```yaml
serverHost: api.internal
serverPort: 443
isSecured: true
```

### 2. Parse & Read YAML

```abap
DATA(li_yaml) = zcl_ayaml=>parse( lv_yaml ).

" Safe type getters with optional default values
DATA(lv_host) = li_yaml->get_string( iv_path = '/serverHost' iv_default = 'localhost' ).
DATA(lv_port) = li_yaml->get_integer( iv_path = '/serverPort' iv_default = 8080 ).
DATA(lv_sec)  = li_yaml->get_boolean( iv_path = '/isSecured' ).

" Check existence and list keys
IF li_yaml->exists( '/serverHost' ) = abap_true.
  DATA(lt_keys) = li_yaml->get_keys( '/' ).
ENDIF.
```

### 3. Deserialize YAML to ABAP

```abap
DATA ls_target TYPE ty_s_config.

li_yaml->to_abap( IMPORTING ev_data = ls_target ).
```

### 4. Mutate & Construct YAML

```abap
DATA(li_yaml) = zcl_ayaml=>new( ).

li_yaml->set_string( iv_path = '/app/name' iv_val = 'MyApp' ).
li_yaml->set_integer( iv_path = '/app/version' iv_val = 2 ).

li_yaml->ensure_sequence( '/app/tags' ).
li_yaml->append_to_sequence( iv_path = '/app/tags' iv_val = 'production' ).
li_yaml->append_to_sequence( iv_path = '/app/tags' iv_val = 'backend' ).

DATA(lv_output) = li_yaml->to_yaml( ).
```

---

## 📂 Architecture

```
src/
├── zif_ayaml_types.intf.abap     # Core type definitions & format constants
├── zif_ayaml_reader.intf.abap    # Read-only query interface
├── zif_ayaml_writer.intf.abap    # Mutation interface
├── zif_ayaml.intf.abap           # Combined YAML document interface
├── zcl_ayaml_utils.clas.abap     # Path, string, case conversion & type utilities
├── zcx_ayaml_error.clas.abap     # Exception class
└── zcl_ayaml.clas.abap           # Main class
    ├── locals_def.abap           # Local class definitions (scanner, parser, AST, serializer)
    ├── locals_imp.abap           # Local class implementations
    └── testclasses.abap          # Comprehensive ABAP Unit test suite
```

---

## 🧪 Testing & Validation

Run lint checks and transpiled unit tests:

```bash
npm test
```

Direct commands:
```bash
npm run lint    # Check syntax & formatting with abaplint
npm run unit    # Run test suite via Open-ABAP transpiler
```
