.PHONY: vm shell lint test diag clean-vm

vm:        ## Launch the lab VM
	multipass launch 24.04 --name lab --cpus 2 --memory 4G --disk 20G \
	  --cloud-init environment/multipass/cloud-init.yaml
	multipass mount . lab:/home/ubuntu/lab

shell:     ## Open a shell in the lab VM
	multipass shell lab

lint:      ## shellcheck every script
	find . -name '*.sh' -not -path './.git/*' -print0 | xargs -0 shellcheck --severity=warning

test:      ## Run the bats tests
	bats tools/tests

diag:      ## Run the diag tool inside the VM
	multipass exec lab -- sudo /home/ubuntu/lab/tools/ubuntu-diag.sh -o /tmp

clean-vm:  ## Delete the lab VM
	multipass delete --purge lab
