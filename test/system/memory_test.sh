#!/usr/bin/env bash

valgrind --leak-check=full --log-file=./valgrind.out $1
