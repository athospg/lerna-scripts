// This script (in a Lerna monorepo) is used to verify that all packages in the
// monorepo uses the correct versions of other packages in the monorepo as
// specified in their package.json files.
//
// It scans every package's package.json for dependencies, devDependencies and
// peerDependencies from other packages in the monorepo, and checks that the
// version matches the version specified in package.json.

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Get all package names in the monorepo
const packageListJson = execSync('lerna list --all --json').toString();
const packages = JSON.parse(packageListJson);

if (packages.length === 0) {
  console.error('No packages found in the monorepo.');
  process.exit(1);
}

const dependenciesSections = ['dependencies', 'devDependencies', 'peerDependencies'];

for (const pkg of packages) {
  const packageJsonPath = path.join(pkg.location, 'package.json');
  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8'));

  for (const section of dependenciesSections) {
    const deps = packageJson[section];
    if (!deps) continue;

    for (const [depName, depVersion] of Object.entries(deps)) {
      const matchedPackage = packages.find((p) => p.name === depName);
      if (matchedPackage) {
        const expectedVersion = matchedPackage.version;
        if (depVersion !== expectedVersion) {
          console.error(
            `Version mismatch in package "${pkg.name}": ` +
              `"${depName}" is specified as "${depVersion}" but should be "${expectedVersion}".`,
          );
          process.exit(1);
        }
      }
    }
  }
}

console.log('All package versions are correct.');
process.exit(0);
