# .claude/hooks/guard.sh   (chmod +x)
#!/usr/bin/env bash
input=$(cat)
tool=$(jq -r '.tool_name' <<<"$input")

# 1) Hard-block all file mutation tools (belt-and-suspenders with the denylist)
case "$tool" in
  Edit|Write|MultiEdit)
    echo "BLOCKED: tutor mode is read-only. Provide instructions + a snippet for me to apply by hand." >&2
    exit 2 ;;
esac

# 2) For Bash, refuse anything that escapes the project root
if [[ "$tool" == "Bash" ]]; then
  cmd=$(jq -r '.tool_input.command' <<<"$input")
  if grep -Eq '(^|[^a-zA-Z])(\.\./|/etc/|/usr/|~|\$HOME)' <<<"$cmd"; then
    echo "BLOCKED: command appears to reach outside the project folder." >&2
    exit 2 ;
  fi
fi
exit 0