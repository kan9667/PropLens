#!/bin/bash
set -e

git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
export PATH="$HOME/flutter/bin:$HOME/flutter/bin/cache/dart-sdk/bin:$PATH"
flutter precache --web
flutter pub get

echo "OPENROUTER_API_KEY=$OPENROUTER_API_KEY" > .env

flutter build web --release
