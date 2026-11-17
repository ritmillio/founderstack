#!/bin/sh
set -e
git init -q && git config user.email eval@example.com && git config user.name eval
mkdir -p src
printf 'import React from "react";\nexport class Cart extends React.Component { render() { return null; } }\n' > src/Cart.jsx
printf 'import React from "react";\nexport class Header extends React.Component { render() { return null; } }\n' > src/Header.jsx
printf 'export function Footer() { return null; }\n' > src/Footer.jsx
echo '{ "name": "web", "dependencies": { "react": "^19.0.0" } }' > package.json
git add -A && git commit -qm "init"
