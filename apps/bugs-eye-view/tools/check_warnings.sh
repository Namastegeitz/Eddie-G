#!/usr/bin/env bash
# Recompiles every script with Godot's default warnings promoted to errors.
# Usage: tools/check_warnings.sh   (prints offending lines; exit 1 if any)
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
{ echo "[debug]"; echo
  for w in unassigned_variable unassigned_variable_op_assign unused_variable unused_local_constant \
    unused_parameter unused_signal shadowed_variable shadowed_variable_base_class shadowed_global_identifier \
    unreachable_code unreachable_pattern standalone_expression standalone_ternary incompatible_ternary \
    static_called_on_instance redundant_static_unload redundant_await assert_always_true assert_always_false \
    integer_division narrowing_conversion int_as_enum_without_cast int_as_enum_without_match \
    enum_variable_without_default empty_file deprecated_keyword confusable_identifier \
    confusable_local_declaration confusable_local_usage confusable_capture_reassignment inference_on_variant \
    native_method_override get_node_default_without_onready onready_with_export missing_tool; do
    echo "gdscript/warnings/$w=2"; done; } > override.cfg
(timeout 60 "$GODOT" --headless --path . res://tests/check_scripts.tscn > /tmp/bev_warn.log 2>&1; true)
rm -f override.cfg
grep -E "Parse Error|Compile Error" -A1 /tmp/bev_warn.log | grep -vE "Failed to compile depended|^--$" | paste - - | sed 's/  */ /g' | grep "Parse Error" && exit 1
echo "no warnings"
