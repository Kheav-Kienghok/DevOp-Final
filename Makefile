.PHONY: help setup

MAKEFILES_DIR := makefiles

help:
	@echo ""
	@echo "DevOp-Final Main Makefile"
	@echo "========================================"
	@echo ""
	@echo "Run everything in ONE command:"
	@echo "  make setup   - Install Terraform + Ansible"
	@echo ""

# ONE command setup
setup:
	@echo ""
	@echo "========================================"
	@echo " Installing Terraform + Ansible"
	@echo "========================================"
	@echo ""

	@make -f $(MAKEFILES_DIR)/Makefile.terraform install-terraform
	@make -f $(MAKEFILES_DIR)/Makefile.ansible install-ansible

	@echo ""
	@echo "Setup completed successfully"
	@echo ""