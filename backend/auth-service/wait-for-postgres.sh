#!/bin/sh

host="$1"
port="$2"
shift 2
cmd="$@"

until nc -z $host $port; do
  echo "Esperando PostgreSQL em $host:$port..."
  sleep 2
done

echo "PostgreSQL disponível, executando comando"
exec $cmd