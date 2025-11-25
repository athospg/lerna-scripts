npx lerna exec -- "git stash push -m 'Stash before updating' || true"

npx lerna clean -y
rm package-lock.json
rm -rf node_modules
npm cache clean --force

npx lerna exec "rm package-lock.json && rm -rf node_modules"

npx lerna bootstrap
npx lerna run build
