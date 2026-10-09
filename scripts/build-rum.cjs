const { build } = require("esbuild");
const fs = require("fs");

function publicKey() {
  if (process.env.RUM_PUBLIC_KEY) return process.env.RUM_PUBLIC_KEY.trim();
  if (!fs.existsSync(".env")) return "";
  for (const line of fs.readFileSync(".env", "utf8").split("\n")) {
    const match = line.match(/^\s*RUM_PUBLIC_KEY\s*=\s*(.*?)\s*$/);
    if (match) return match[1].replace(/^["']|["']$/g, "");
  }
  return "";
}

const key = publicKey();
if (!key) {
  console.error("Set RUM_PUBLIC_KEY in the environment or in .env before building.");
  process.exit(1);
}

build({
  entryPoints: ["src/rum.js"],
  bundle: true,
  format: "iife",
  target: "es2018",
  outfile: "site/js/rum.js",
  minify: true,
  legalComments: "none",
  define: {
    __RUM_PUBLIC_KEY__: JSON.stringify(key),
  },
}).catch(() => process.exit(1));
