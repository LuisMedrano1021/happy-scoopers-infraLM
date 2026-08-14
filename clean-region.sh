#!/usr/bin/env bash
set -euo pipefail
# ============================================================================
#  clean-region.sh  —  HERRAMIENTA DE INSTRUCTOR (no para estudiantes)
# ----------------------------------------------------------------------------
#  Elimina TODOS los Resource Groups que empiezan con un prefijo (dw- por
#  defecto) en una región. Úsalo para limpiar laboratorios al final del
#  curso o tus pruebas.
#
#  ADVERTENCIA: esto BORRA infraestructura de forma IRREVERSIBLE.
#      - Solo afecta la suscripción en la que estás autenticado (az login).
#      - NO puede tocar cuentas de otros (cada quien tiene su suscripción).
#      - Pero SI borra TODO lo que haga match con el prefijo en TU cuenta,
#        incluyendo laboratorios que quieras conservar.
#
#  Los estudiantes NO deben usar este script: para borrar su propio
#  laboratorio usan  make destruir, que solo afecta el suyo.
# ============================================================================
#  Uso:
#    ./clean-region.sh                 # region desde Terraform, prefijo dw-
#    ./clean-region.sh eastus          # region explicita
#    ./clean-region.sh eastus dw-      # region y prefijo explicitos
# ============================================================================
REGION="${1:-}"
PREFIX="${2:-dw-}"
if [[ -z "$REGION" ]]; then
    REGION=$(echo 'var.location' | terraform console 2>/dev/null | tr -d '"')
fi
if [[ -z "$REGION" ]]; then
    echo "ERROR: No se pudo determinar la region."
    exit 1
fi
CUENTA=$(az account show --query name -o tsv 2>/dev/null || echo "desconocida")
echo
echo "=============================================================="
echo "  AZURE LAB CLEANUP  —  BORRADO IRREVERSIBLE"
echo "=============================================================="
echo "  Cuenta : $CUENTA"
echo "  Region : $REGION"
echo "  Prefijo: $PREFIX"
echo "=============================================================="
echo "  Se eliminaran los siguientes Resource Groups:"
echo
az group list \
  --query "[?location=='${REGION}' && starts_with(name, '${PREFIX}')].{Name:name,Location:location}" \
  -o table
RG_LIST=$(az group list \
  --query "[?location=='${REGION}' && starts_with(name, '${PREFIX}')].name" \
  -o tsv)
if [[ -z "$RG_LIST" ]]; then
    echo
    echo "No se encontraron Resource Groups para limpiar."
    exit 0
fi
echo
echo "  Para confirmar, escribe exactamente la palabra:  BORRAR"
read -rp "  > " CONFIRM
if [[ "$CONFIRM" != "BORRAR" ]]; then
    echo "  Operacion cancelada (no escribiste BORRAR)."
    exit 0
fi
echo
for RG in $RG_LIST; do
    echo "Eliminando $RG ..."
    az group delete --name "$RG" --yes --no-wait
done
echo
echo "Esperando que Azure complete las eliminaciones..."
for RG in $RG_LIST; do
    echo "Esperando $RG ..."
    az group wait --name "$RG" --deleted
done
echo
echo "Limpieza completada."
