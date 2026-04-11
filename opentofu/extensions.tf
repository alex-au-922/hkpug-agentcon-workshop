resource "terraform_data" "vscode_extension_cache" {
  for_each = local.vscode_extensions

  input = each.value

  triggers_replace = [sha256(jsonencode(each.value))]

  provisioner "local-exec" {
    interpreter = ["/bin/sh", "-c"]
    environment = {
      EXT_SOURCE    = each.value.source
      EXT_PUBLISHER = try(each.value.publisher, "")
      EXT_NAME      = try(each.value.name, "")
      EXT_VERSION   = try(each.value.version, "")
      EXT_TARGET    = each.value.target
      EXT_URL       = each.value.url
      EXT_OUTPUT    = abspath("${path.module}/${each.value.output}")
    }

    command = <<-EOT
      set -eu
      mkdir -p "$(dirname "$EXT_OUTPUT")"

      tmpfile=$(mktemp)
      metafile=$(mktemp)
      trap 'rm -f "$tmpfile" "$metafile"' EXIT

      case "$EXT_SOURCE" in
        openvsx)
          echo "metadata $EXT_PUBLISHER.$EXT_NAME@$EXT_VERSION"
          curl -fsSL "https://open-vsx.org/api/$EXT_PUBLISHER/$EXT_NAME/$EXT_VERSION" -o "$metafile"
          download_url=$(python3 - "$metafile" "$EXT_TARGET" <<'PY'
import json
import sys
from pathlib import Path

meta = json.loads(Path(sys.argv[1]).read_text())
target = sys.argv[2]
downloads = meta.get("downloads", {})
print(downloads.get(target) or downloads.get("universal") or meta["files"]["download"])
PY
)
          ;;
        direct)
          download_url="$EXT_URL"
          ;;
        *)
          echo "unsupported EXT_SOURCE: $EXT_SOURCE" >&2
          exit 1
          ;;
      esac

      echo "download $(basename "$EXT_OUTPUT")"
      curl -fL --progress-bar "$download_url" -o "$tmpfile"
      unzip -tqq "$tmpfile" >/dev/null
      mv "$tmpfile" "$EXT_OUTPUT"
      echo "saved $(basename "$EXT_OUTPUT")"
    EOT
  }
}
