#! /usr/bin/env bash
set -ex

if ! which brew > /dev/null; then
  echo "Installing HomeBrew"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

if ! which swiftlint > /dev/null; then
  echo "Installing SwiftLint"
  brew install swiftlint
fi

if ! which rbenv > /dev/null; then
  echo "Installing rbenv"
  brew install rbenv
fi

if ! rbenv versions | grep $(cat .ruby-version) > /dev/null; then
  echo "Installing Ruby $(cat .ruby-version)"
  rbenv install $(cat .ruby-version)``
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
  echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
  source ~/.bash_profile
fi

if ! rbenv which bundle > /dev/null; then
  echo "Installing bundler"
  gem install bundler
fi

echo "Running bundle install"
bundle install

echo "Bootstrapping complete!"
