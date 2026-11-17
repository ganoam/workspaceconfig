# sed tricks

## Insert a line after the FIRST matching line only (per file)

```shell
sed -i -E '0,/foo/s|^(//\|#)( bar)$|\1\2\n\1 yourmom|' files...
```

Result: files whose header is `// foo bar` or `# foo bar` get
`// yourmom` / `# yourmom` inserted right after it -- the comment
prefix is copied via backreference, so one expression handles multiple
comment styles.

Anatomy:
- `0,/foo/` -- address range "line 0 until first match" (GNU ext);
  the s-command applies only up to the first match -> other `foo bar`
  lines further down stay untouched
- `-E` -- ERE syntax (`|` alternation, `()` groups)
- `s|pat|repl|` -- `|` as delimiter, since the pattern itself contains `/`
- `\1` -- backreference reuses the matched comment prefix (`//` vs `#`)
- `\n` in replacement -- literal newline

Pitfall: a `/` inside the *address* regex also terminates it
(`0,/a/b/` is a syntax error). Either use a different address delimiter
(`sed '0,\%a/b%s|...'`), or just match on the plain text part.

## Delete exact full lines (several variants at once)

```shell
sed -i '/^\/\/ foo bar yourmom\.$/d; /^# foo bar yourmom\.$/d' files...
```

## Run sed only on files matching TWO patterns

```shell
for f in $(grep -l "patA" dir/* | xargs grep -l "patB"); do
  sed -i '...' "$f"
done
```

`grep -l patA | xargs grep -l patB` = intersection of file sets.
