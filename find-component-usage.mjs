/**
 * This script can be used to find all usages of a specific component in a project. It searches through the project's files and identifies where the component is being imported and used.
 *
 * Usage:
 *   node ./scripts/find-component-usage.mjs <component-name> <project-directory>
 *
 * Example:
 *   node ./scripts/find-component-usage.mjs MyComponent packages
 *   node ./scripts/find-component-usage.mjs Tooltip packages
 */

import fs from 'fs';
import path from 'path';

const [componentName, projectDir] = process.argv.slice(2);

if (!componentName || !projectDir) {
  console.error('Usage: node find-component-usage.mjs <component-name> <project-directory>');
  process.exit(1);
}

const ignoredDirs = [
  'node_modules',
  'dist',
  'build',
  'lib',
  '.git',
  '.azuredevops',
  '.husky',
  '.nginx',
  '__mocks__',
  '__tests__',
];

function extractPropsFromJSX(content, componentName) {
  // Match both <Component ... /> and <Component ...>...</Component>
  const jsxRegex = new RegExp(`<${componentName}([^>/]*)[/>]`, 'g');
  const propsSet = new Set();
  let match;
  while ((match = jsxRegex.exec(content)) !== null) {
    const propsString = match[1];
    // Match propName= or ...spread
    const propRegex = /([a-zA-Z0-9_\-$]+)\s*=/g;
    let propMatch;
    while ((propMatch = propRegex.exec(propsString)) !== null) {
      propsSet.add(propMatch[1]);
    }
    // Also check for spread props {...props}
    const spreadRegex = /{\s*\.\.\.([a-zA-Z0-9_\-$]+)\s*}/g;
    let spreadMatch;
    while ((spreadMatch = spreadRegex.exec(propsString)) !== null) {
      propsSet.add('...' + spreadMatch[1]);
    }
  }
  return Array.from(propsSet);
}

function findComponentUsage(dir) {
  const files = fs.readdirSync(dir);
  const usageLocations = [];
  files.forEach((file) => {
    const filePath = path.join(dir, file);
    if (fs.statSync(filePath).isDirectory()) {
      if (!ignoredDirs.includes(file)) {
        usageLocations.push(...findComponentUsage(filePath));
      }
    } else if (
      filePath.endsWith('.js') ||
      filePath.endsWith('.jsx') ||
      filePath.endsWith('.ts') ||
      filePath.endsWith('.tsx')
    ) {
      const content = fs.readFileSync(filePath, 'utf-8');
      const importRegex = new RegExp(`import\\s+.*\\b${componentName}\\b.*from\\s+['"].*['"]`, 'g');
      const usageRegex = new RegExp(`\\b${componentName}\\b`, 'g');
      if (importRegex.test(content) || usageRegex.test(content)) {
        // Extract props if JSX/TSX
        let props = [];
        if (
          filePath.endsWith('.jsx') ||
          filePath.endsWith('.tsx') ||
          filePath.endsWith('.js') ||
          filePath.endsWith('.ts')
        ) {
          props = extractPropsFromJSX(content, componentName);
        }
        usageLocations.push({ filePath, props });
      }
    }
  });
  return usageLocations;
}

const usageLocations = findComponentUsage(projectDir);
if (usageLocations.length > 0) {
  // console.log(`Found ${componentName} usage in the following files:`);
  // usageLocations.forEach(({ filePath, props }) => {
  //   console.log(filePath);
  //   if (props && props.length > 0) {
  //     console.log('  Props used:', props.join(', '));
  //   }
  // });

  console.log(`Found ${componentName} usage in ${usageLocations.length} files`);

  const uniquePropsUsed = new Set();
  usageLocations.forEach(({ props }) => {
    props.forEach((prop) => uniquePropsUsed.add(prop));
  });

  if (uniquePropsUsed.size > 0) {
    console.log(`Unique props used with ${componentName}:`);
    uniquePropsUsed.forEach((prop) => console.log(`  ${prop}`));
  }
} else {
  console.log(`No usage of ${componentName} found in the project.`);
}
