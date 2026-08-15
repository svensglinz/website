#! /bin/bash

hugo build
mkdir -p docs
cp -r public/* docs/