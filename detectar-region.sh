#!/bin/bash
# ============================================================
# Detecta qué región de Azure permite TU cuenta para el
# laboratorio. Cada estudiante lo corre una vez, al inicio.
# Uso:  bash detectar-region.sh
# ============================================================
echo "Buscando regiones válidas para tu cuenta..."
echo "(esto prueba crear recursos pequeños y los borra; tarda ~1 min)"
echo ""

RG="rg-test-region-$RANDOM"
SKU="Standard_B2s_v2"
# Regiones candidatas cercanas a Centroamérica, en orden de preferencia
CANDIDATAS="centralus eastus eastus2 southcentralus westcentralus canadacentral"

REGION_VM=""
REGION_STORAGE=""

for region in $CANDIDATAS; do
  # ¿Permite VM de este tamaño?
  vm_ok=$(az vm list-skus --size "$SKU" --location "$region" \
          --query "[?resourceType=='virtualMachines' && restrictions[0].reasonCode==null] | length(@)" \
          -o tsv 2>/dev/null)
  # ¿Permite storage? (prueba real: crear grupo + storage, y borrar)
  az group create --name "$RG" --location "$region" -o none 2>/dev/null
  st_name="testst${RANDOM}"
  st_ok=$(az storage account create --name "$st_name" --resource-group "$RG" \
          --location "$region" --sku Standard_LRS \
          --query "provisioningState" -o tsv 2>/dev/null)
  az group delete --name "$RG" --yes --no-wait 2>/dev/null

  vm_txt="no"; [ "$vm_ok" -gt 0 ] 2>/dev/null && vm_txt="SÍ"
  st_txt="no"; [ "$st_ok" = "Succeeded" ] && st_txt="SÍ"

  echo "  $region  ->  VM: $vm_txt   Storage: $st_txt"

  # Guardar la primera que sirva para ambos
  if [ "$vm_txt" = "SÍ" ] && [ "$st_txt" = "SÍ" ] && [ -z "$REGION_VM" ]; then
    REGION_VM="$region"
  fi
done

echo ""
if [ -n "$REGION_VM" ]; then
  echo "============================================================"
  echo "  TU REGIÓN es:  $REGION_VM"
  echo "  Ponla en tu terraform.tfvars así:"
  echo "      location = \"$REGION_VM\""
  echo "============================================================"
else
  echo "No se encontró una región que permita VM + storage en la"
  echo "lista probada. Avísale al instructor."
fi
