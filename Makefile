MAKEFLAGS += --no-print-directory
PlistBuddy = "/usr/libexec/PlistBuddy"
fastlane = bundle exec fastlane
AGIPAG_PLIST = "Apps/Agipag/Config/Info.plist"

.PHONY: install
# Usage: make install
install: install-tuist
	@test $(CLEAN_INSTALL) && $(MAKE) clean-dependencies || true
	brew tap --repair
	arch -arm64 brew update
	arch -arm64 brew bundle
	git lfs install
	git lfs pull
	sudo gem install cocoapods
	sudo gem update --system
	sudo gem update bundler
	bundle install
	bundle exec pod repo update
	carthage version
	./carthage.sh
	$(MAKE) -C Templates/XcodeTemplates install-templates

.PHONY: install-local
# Usage: make install-local
install-local: install-tuist
	@test $(CLEAN_INSTALL) && $(MAKE) clean-dependencies || true
	chmod +x removeTrash.sh
	./removeTrash.sh
	brew uninstall --force go
	brew install go
	brew tap --repair
	brew update
	brew bundle
	git lfs install
	git lfs pull
	brew install rbenv
	brew install ruby
	sudo gem update bundler
	bundle install
	bundle exec pod repo update
	carthage version
	./carthage.sh
	$(MAKE) -C Templates/XcodeTemplates install-templates

.PHONY: install-tuist
# Usage: make install-tuist
install-tuist:
	# Use this one when server is up
	#curl -Ls https://install.tuist.io | sh
	# Use this one when server is down
	#curl -Ls https://raw.githubusercontent.com/tuist/tuist/1.50.0/script/install | bash
	# tuist update --> Desabilitado temporáriamente. Problema na versão 4.0.0

.PHONY: bootstrap
# Usage: make bootstrap
bootstrap:
	-killall Xcode
	tuist clean
	tuist generate
	pod install
	$(MAKE) -C Templates/XcodeTemplates reinstall
	sleep 1
	@test $(CI) || open Agibank.xcworkspace

.PHONY: get-fonts
# Usage: make get-fonts
get-fonts:
	# Generate font files
	git submodule update --init --remote
	$(MAKE) -C Scripts get-fonts platform=iOS

.PHONY: update-devices
# Usage: make update-devices
update-devices:
	@echo "Updating devices on Apple Development Account"
	@sleep 1
	$(fastlane) update_devices
	@echo "Updating local certificates"
	@sleep 1
	$(MAKE) sign

.PHONY: build-demo
build-demo:
	$(call check_defined, module)
	-killall Xcode
	tuist clean
	tuist generate
	pod install
	$(MAKE) -C Templates/XcodeTemplates reinstall
	sleep 1
	@echo "Generating .ipa from $(module)"
	@sleep 1
	@$(fastlane) build_demo scheme_name:$(module)

.PHONY: sign-demo
sign-demo:
	$(call check_defined, module)
	@$(fastlane) code_signing_demo scheme_name:$(module)

# Signs the app project for development and distribution
.PHONY: sign
# Signs the app project for development and distribution

# Usage: make sign
sign:
	@echo "Make sure you are connected to the VPN"
	# install certificates
	$(fastlane) install_certificates

	#  decrypt locally
	$(eval match_folder = $(shell $(fastlane) match decrypt | grep -o "'.*'" | tail -n 1 | tr -d "'"))
	echo $(match_folder)
	#  move to Tuist folder
	mv "$(match_folder)/profiles/appstore/AppStore_br.com.agiplan.agipag-ios.mobileprovision" "Tuist/Signing/Agipag.HomologRelease.mobileprovision"
	mv "$(match_folder)/profiles/appstore/AppStore_br.com.agiplan.agipag.mobileprovision" "Tuist/Signing/Agipag.ProdRelease.mobileprovision"

	mv "$(match_folder)/profiles/development/Development_br.com.agiplan.agipag-ios.mobileprovision" "Tuist/Signing/Agipag.HomologDebug.mobileprovision"
	mv "$(match_folder)/profiles/development/Development_br.com.agiplan.agipag.mobileprovision" "Tuist/Signing/Agipag.ProdDebug.mobileprovision"

	mv "$(match_folder)/profiles/development/Development_br.com.agibank.FlameUI.demo.mobileprovision" "Tuist/Signing/FlameUIDemo.HomologDebug.mobileprovision"
	mv "$(match_folder)/profiles/adhoc/AdHoc_br.com.agibank.FlameUI.demo.mobileprovision" "Tuist/Signing/FlameUIDemo.HomologDebug.mobileprovision"

	find "$(match_folder)" -name "*.p12" -or -name "*.cer" | xargs -I file mv file "Tuist/Signing"

	$(MAKE) bootstrap

.PHONY: set-version
# Usage: make set-version version=1.2.3
set-version:
	$(call check_defined, version)
	@echo "Setting version to $(version)"
	@$(PlistBuddy) $(AGIPAG_PLIST) -c "set CFBundleShortVersionString $(version)"

.PHONY: set-build-number
# Usage: make set-build-number build=1234
set-build-number:
	$(call check_defined, build)
	@echo "Setting build to $(build)"
	@$(PlistBuddy) $(AGIPAG_PLIST) -c "set CFBundleVersion $(build)"

.PHONY: get-version
# Usage: make get-version
get-version:
	@$(PlistBuddy) -c "Print CFBundleShortVersionString" $(AGIPAG_PLIST)

.PHONY: release-all
# Run the release for both hlg and prod

# Usage: make release-all version=1.2.3 build=1234
release-all:
	$(call check_defined, version)
	$(eval build ?= 0)
	$(MAKE) release version=$(version) build=$(build) environment=prod
	$(MAKE) release version=$(version) build=$(build) environment=hlg

.PHONY: release
# - Updates the Info.plist files with the version and commits them
# - Creates a tag to be processed and release by the CI
# - Pushes all changes
# Usage: make release environment=<hlg|prod> version=<version> build=[build]
# environment: hlg or prod
# version: semantic version, eg. 3.2.1
# build(optional): build number, eg. 1234

# Usage: make release environment=prod version=1.2.3 build=1234
# Usage: make release environment=hlg version=1.2.3 build=1234
release:
	$(call check_defined, environment)
	$(call check_defined, version)
	$(eval build ?= 0)
	@$(MAKE) set-version version=$(version)
	@$(MAKE) set-build-number build=$(build)
	git add ./\*.plist
	$(eval release = $(version) ($(build)))
	git commit -m "Set version to $(release)" || echo "No changes to commit"
	$(eval tagName := "release/$(environment)/$(version)/$(build)")
	git tag -a $(tagName) -m "Release $(release)" -f
	git push || true
	git push origin $(tagName) -f

.PHONY: generate-demo
generate-demo:
	$(call check_defined,module)
	$(eval current_datetime := $(shell date +"%Y-%m-%d_%H-%M-%S"))
	$(eval sanitized_module := $(subst /,-,$(module)))
	$(eval tagName := "demo/$(sanitized_module)/$(current_datetime)")
	git tag -a "$(tagName)" -m "Demo $(module)" -f
	git push || true
	git push origin "$(tagName)" -f

.PHONY: clean-dependencies
# Usage: make clean-dependencies
clean-dependencies:
	@echo "Deleting cached dependencies"
	rm -rf Carthage
	rm -rf Pods

.PHONY: test
# Usage: make test
test:
	tuist test "Agipag Homolog" --device "iPhone 15"

.PHONY: update
# Usage: make update
update:
	bundle update
	./carthage.sh

.PHONY: unlink-phone
# Usage: make unlink-phone username=<your_username> password=<your_password> cpf=<your_cpf>
unlink-phone:
	$(call check_defined, username \
						  password \
						  cpf, credentials)
	$(eval token = $(shell curl -X POST 'https://hlg-gateway.agibank.com.br/token?grant_type=password&username=$(username)&password=$(password)' \
	-H 'Authorization: Basic M2V2S2NiUzJPZm51enA2a2pmTzVpRzhlUTFnYTpTclJMU3pkWHJUU1ZubTQzNFh2MVJrdGU1Q2dh' \
	-H 'Content-Type: application/x-www-form-urlencoded' | jq --raw-output '.access_token'))

	curl -i -X POST "http://channel-integration-service.k8s.hlg.bancoagiplan.com.br/v1/phone/unlink" \
	-H  "Authorization: $(token)" -H  "x-origin: MOBILE" -H  "Content-Type: application/json" \
	-d '{  "taxId": "$(cpf)"}'


.PHONY: clean-derived-data
# Usage: make clean-derived-data
clean-derived-data:
	-killall Xcode
	-rm -rf Agibank.xcworkspace Agibank.xcodeproj
	-rm -rf Pods Podfile.lock
	rm -rf ~/Library/Developer/Xcode/DerivedData ~/Library/Caches/com.apple.dt.Xcode
	tuist clean
	@echo "\xF0\x9F\x94\xA5 BURN IT ALL \xF0\x9F\x94\xA5"
	$(MAKE) bootstrap

.PHONY: nuke
# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.

# Usage: make nuke
nuke:
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	git reset HEAD --hard
	git clean -dfx
	$(MAKE) clean-derived-data

check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

.PHONY: generate-needle-file
# Usage: make generate-needle-file module=YourModuleName
generate-needle-file:
	$(call check_defined, module)
	@echo "Generating Needle for module: $(module)"
	@$(MAKE) check-needle-files module=$(module) || \
		$(MAKE) create-needle-files module=$(module)
	needle generate Libs/$(module)/Classes/NeedleGenerated.swift Libs/$(module)/Classes/
	@echo "Needle file generated for module successfully: $(module) ✅"

.PHONY: check-needle-files
# Usage: make check-needle-files module=YourModuleName
check-needle-files:
	$(call check_defined, module)
	@test -f Libs/$(module)/Classes/NeedleGenerated.swift && \
		echo "Needle file exists for module: $(module)" || \
		(echo "Needle file does not exist for module: $(module)" && exit 1)

.PHONY: create-needle-files
# Usage: make create-needle-files module=YourModuleName
create-needle-files:
	$(call check_defined, module)
	@echo "Creating Needle file and folder structure for module: $(module)"
	mkdir -p Libs/$(module)/Classes
	touch Libs/$(module)/Classes/NeedleGenerated.swift
