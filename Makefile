# ============================================================
#  Happy Scoopers - Infraestructura del laboratorio
#  Atajos para crear, verificar y apagar tu máquina en Azure.
#  Uso:  make <comando>    ·    Lista:  make help
# ============================================================

# Regiones candidatas para check-region (cercanas a Centroamérica).
REGIONS_CANDIDATAS ?= centralus eastus eastus2 southcentralus westcentralus canadacentral

.PHONY: help check-region llave desplegar plan urls apagar encender destruir limpiar-region estado

help:  ## Muestra esta ayuda
	@echo "Comandos disponibles:"
	@grep -E '^[a-zA-Z-]+:.*## ' $(MAKEFILE_LIST) | \
	  sed 's/:.*## /|/' | awk -F'|' '{printf "  make %-16s %s\n", $$1, $$2}'

check-region:  ## Detecta qué región permite TU cuenta (VM + storage) hoy
	@echo "============================================================"
	@echo " Detectando regiones válidas para tu cuenta de Azure..."
	@echo " (crea recursos mínimos de prueba y los borra; ~1-2 min)"
	@echo "============================================================"
	@echo ""
	@cuenta=$$(az account show --query name -o tsv 2>/dev/null); \
	if [ -z "$$cuenta" ]; then \
	  echo "  ✗ No hay sesión de Azure. Corre primero: az login"; exit 1; fi; \
	echo "  Cuenta: $$cuenta"; \
	echo "  Fecha:  $$(date '+%Y-%m-%d %H:%M')"; echo ""; \
	printf "  %-18s %-8s %-10s\n" "REGIÓN" "VM" "STORAGE"; \
	printf "  %-18s %-8s %-10s\n" "------" "--" "-------"; \
	ganadora=""; rg="rg-checkregion-$$RANDOM"; \
	for region in $(REGIONS_CANDIDATAS); do \
	  vm_ok=$$(az vm list-skus --size Standard_B2s_v2 --location $$region \
	    --query "[?resourceType=='virtualMachines' && restrictions[0].reasonCode==null] | length(@)" \
	    -o tsv 2>/dev/null); \
	  az group create --name $$rg --location $$region -o none 2>/dev/null; \
	  stname="chk$$RANDOM"; \
	  st_state=$$(az storage account create --name $$stname --resource-group $$rg \
	    --location $$region --sku Standard_LRS --query provisioningState -o tsv 2>/dev/null); \
	  az group delete --name $$rg --yes --no-wait 2>/dev/null; \
	  vm_txt="no"; [ "$$vm_ok" -gt 0 ] 2>/dev/null && vm_txt="SÍ"; \
	  st_txt="no"; [ "$$st_state" = "Succeeded" ] && st_txt="SÍ"; \
	  printf "  %-18s %-8s %-10s\n" "$$region" "$$vm_txt" "$$st_txt"; \
	  if [ "$$vm_txt" = "SÍ" ] && [ "$$st_txt" = "SÍ" ] && [ -z "$$ganadora" ]; then \
	    ganadora="$$region"; fi; \
	done; echo ""; \
	if [ -n "$$ganadora" ]; then \
	  echo "============================================================"; \
	  echo "  ✓ TU REGIÓN: $$ganadora"; echo ""; \
	  echo "  Ponla en tu terraform.tfvars:"; \
	  echo "      location = \"$$ganadora\""; \
	  echo "============================================================"; \
	else \
	  echo "  ✗ Ninguna candidata permitió VM+storage. Avisa al instructor."; fi

plan:  ## Ver qué se va a crear (sin crear nada)
	terraform init -input=false >/dev/null && terraform plan

desplegar:  ## Crear tu máquina en Azure
	terraform init -input=false >/dev/null && terraform apply

urls:  ## Ver las direcciones de tu laboratorio
	@terraform output mi_laboratorio

apagar:  ## Apagar la máquina (deja de gastar crédito, conserva datos)
	@name=$$(terraform output -raw vm_name 2>/dev/null); \
	rg=$$(terraform output -raw resource_group 2>/dev/null); \
	if [ -n "$$name" ]; then az vm deallocate -g $$rg -n $$name; \
	else echo "No encuentro la VM. ¿Ya la creaste con make desplegar?"; fi

encender:  ## Encender la máquina para la clase
	@name=$$(terraform output -raw vm_name 2>/dev/null); \
	rg=$$(terraform output -raw resource_group 2>/dev/null); \
	if [ -n "$$name" ]; then az vm start -g $$rg -n $$name; \
	else echo "No encuentro la VM."; fi

destruir:  ## Borrar TODO (fin del curso)
	terraform destroy

limpiar-region:
	./clean-region.sh $(LOCATION) dw-

llave:  ## Generar tu llave SSH (si no existe)
	@ls ~/.ssh/id_rsa.pub >/dev/null 2>&1 && echo "Ya tienes llave SSH" || (ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" && echo "Llave SSH creada")

estado:  ## Ver el estado de tu máquina (encendida/apagada)
	@name=$$(terraform output -raw vm_name 2>/dev/null); \
	rg=$$(terraform output -raw resource_group 2>/dev/null); \
	if [ -z "$$name" ]; then echo "No hay VM. ¿Ya hiciste make desplegar?"; exit 0; fi; \
	estado=$$(az vm get-instance-view -g $$rg -n $$name --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus | [0]" -o tsv 2>/dev/null); \
	echo "Máquina: $$name"; \
	echo "Grupo:   $$rg"; \
	echo "Estado:  $$estado"
